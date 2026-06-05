/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
  Description:
    * Isolated testbench for compress_acc.
    *
    * Workflow:
    *   1. Set SRC_IMAGE to one of the *_edge.pgm files in src_images/.
    *   2. Run: ./script/xrun_sim_compress.sh
    *   3. Decompress the output binary in out2_images/ with a matching
    *      software decompressor and verify it round-trips to the original.
    *
    * The intermediate FIFO is emulated as an 8-bit FWFT model that feeds
    * one pixel per cycle once the accelerator starts reading.
    * TX FIFO writes are captured into a shadow array; after the frame
    * completes the raw bytes are written to a binary file.
    *
    * TX bytes are written to the output file one byte at a time.
    * The pass-through skeleton emits one byte per pixel so the output
    * is TOTAL_PIXELS bytes uncompressed.  A real RLE implementation
    * will reduce this.
    *
    * NOTE: COMPRESSED_SIZE is a student TODO - until it is implemented
    *       the TB reports 0 for the compression ratio.
*/
`include "project_defs.svh"

module compress_acc_tb;

    // -------------------------------------------------------------------------
    localparam int  FRAME_W      = 320;
    localparam int  FRAME_H      = 240;
    localparam int  TOTAL_PIXELS = FRAME_W * FRAME_H;
    localparam int  TX_MAX_BYTES = TOTAL_PIXELS * 2; // worst-case RLE 2x expansion
    localparam real CLK_PERIOD   = 10.0;

    localparam string SRC_IMAGE    = "baboon_edge.pgm";
    localparam string SRC_IMG_PATH = "../../tb/src_images/";
    localparam string OUT_IMG_PATH = "../../tb/out2_images/";

    // Wishbone offsets (compress_acc only decodes adr[3:2])
    localparam logic [31:0] COMPRESS_CTRL   = 32'h00;
    localparam logic [31:0] COMPRESS_STATUS = 32'h04;
    localparam logic [31:0] COMPRESS_SIZE   = 32'h08;

    // -------------------------------------------------------------------------
    // Clock and reset
    // -------------------------------------------------------------------------
    logic clk   = 1'b0;
    logic rst_n = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Wishbone interface
    // -------------------------------------------------------------------------
    wb_if wb (.clk(clk), .rst(rst_n));

    initial begin
        wb.cyc   = '0;
        wb.stb   = '0;
        wb.we    = '0;
        wb.sel   = 4'hF;
        wb.adr   = '0;
        wb.dat_m = '0;
    end

    // -------------------------------------------------------------------------
    // Intermediate FIFO emulation (FWFT 8-bit, one pixel per word)
    // -------------------------------------------------------------------------
    logic [7:0] src_mem [0:TOTAL_PIXELS-1];
    int         fifo_ptr;

    logic       fifo_empty;
    logic [7:0] fifo_dout;
    logic       fifo_rd_en; // driven by DUT

    assign fifo_empty = (fifo_ptr >= TOTAL_PIXELS);
    assign fifo_dout  = fifo_empty ? 8'h0 : src_mem[fifo_ptr];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fifo_ptr <= 0;
        else if (fifo_rd_en && !fifo_empty)
            fifo_ptr <= fifo_ptr + 1;
    end

    // -------------------------------------------------------------------------
    // TX FIFO emulation (32-bit, infinite sink: never asserts full)
    // Capture every write into tx_shadow for file output.
    // -------------------------------------------------------------------------
    logic [7:0] tx_shadow [0:TX_MAX_BYTES-1];
    int         tx_ptr;

    logic       tx_wr_en; // driven by DUT
    logic [7:0] tx_din;   // driven by DUT
    logic       tx_full;  // driven by TB

    assign tx_full = 1'b0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_ptr <= 0;
        else if (tx_wr_en) begin
            tx_shadow[tx_ptr] <= tx_din;
            tx_ptr            <= tx_ptr + 1;
        end
    end

    // -------------------------------------------------------------------------
    // Cycle counter
    // -------------------------------------------------------------------------
    int cycle_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cycle_count <= 0;
        else        cycle_count <= cycle_count + 1;
    end

    // -------------------------------------------------------------------------
    // Simulation timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        #50_000_000; // 50 ms @ 100 MHz
        $fatal(1, "[TB] Simulation timeout at %0t ns", $time);
    end

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    compress_acc u_dut (
        .wb         (wb),
        .fifo_empty (fifo_empty),
        .fifo_dout  (fifo_dout),
        .fifo_rd_en (fifo_rd_en),
        .tx_wr_en   (tx_wr_en),
        .tx_din     (tx_din),
        .tx_full    (tx_full)
    );

    // -------------------------------------------------------------------------
    // Wishbone tasks
    // -------------------------------------------------------------------------
    task automatic wb_write(input logic [31:0] addr, data);
        @(posedge clk); #1;
        wb.adr   <= addr;
        wb.dat_m <= data;
        wb.we    <= 1'b1;
        wb.cyc   <= 1'b1;
        wb.stb   <= 1'b1;
        @(posedge clk iff wb.ack); #1;
        wb.cyc <= 1'b0;
        wb.stb <= 1'b0;
        wb.we  <= 1'b0;
    endtask

    task automatic wb_read(input logic [31:0] addr, output logic [31:0] data);
        @(posedge clk); #1;
        wb.adr <= addr;
        wb.we  <= 1'b0;
        wb.cyc <= 1'b1;
        wb.stb <= 1'b1;
        @(posedge clk iff wb.ack); #1;
        data   = wb.dat_s;
        wb.cyc <= 1'b0;
        wb.stb <= 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // Main test
    // -------------------------------------------------------------------------
    integer      fd, tmp_val, start_cycle;
    string       hdr_str, out_path;
    logic [31:0] status, compressed_size;

    initial begin
        // ------------------------------------------------------------------
        // Load edge PGM (P2 ASCII, one comment line)
        // ------------------------------------------------------------------
        fd = $fopen({SRC_IMG_PATH, SRC_IMAGE}, "r");
        if (fd == 0)
            $fatal(1, "[TB] Cannot open %s%s", SRC_IMG_PATH, SRC_IMAGE);
        void'($fgets(hdr_str, fd)); // P2
        void'($fgets(hdr_str, fd)); // # comment
        void'($fgets(hdr_str, fd)); // width height
        void'($fgets(hdr_str, fd)); // maxval
        for (int i = 0; i < TOTAL_PIXELS; i++) begin
            void'($fscanf(fd, "%d", tmp_val));
            src_mem[i] = tmp_val[7:0];
        end
        $fclose(fd);
        $display("[TB] Loaded %s%s (%0d pixels)", SRC_IMG_PATH, SRC_IMAGE, TOTAL_PIXELS);

        // ------------------------------------------------------------------
        // Reset
        // ------------------------------------------------------------------
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        repeat(4) @(posedge clk);

        // ------------------------------------------------------------------
        // Start: write CTRL auto_start=1
        // ------------------------------------------------------------------
        wb_write(COMPRESS_CTRL, 32'h1);
        start_cycle = cycle_count;
        $display("[TB] Started, polling STATUS.done...");

        // ------------------------------------------------------------------
        // Poll STATUS.done (bit 1)
        // ------------------------------------------------------------------
        do wb_read(COMPRESS_STATUS, status);
        while (!(status & 32'h2));

        wb_read(COMPRESS_SIZE, compressed_size);
        $display("[TB] Done. STATUS=%08h  COMPRESSED_SIZE=%0d  tx_bytes=%0d  elapsed=%0d cycles",
                 status, compressed_size, tx_ptr, cycle_count - start_cycle);
        $display("[TB] Throughput: %.2f input bytes/cycle",
                 real'(TOTAL_PIXELS) / real'(cycle_count - start_cycle));
        if (compressed_size > 0)
            $display("[TB] Compression ratio: %.3f  (%0d -> %0d bytes)",
                     real'(compressed_size) / real'(TOTAL_PIXELS),
                     TOTAL_PIXELS, compressed_size);

        // ------------------------------------------------------------------
        // Write compressed output as raw binary (little-endian word bytes)
        // ------------------------------------------------------------------
        out_path = {OUT_IMG_PATH,
                    SRC_IMAGE.substr(0, SRC_IMAGE.len()-5),
                    "_compressed.bin"};
        fd = $fopen(out_path, "wb");
        if (!fd) begin
            $display("[TB] Cannot open output file %s", out_path);
        end else begin
            for (int i = 0; i < tx_ptr; i++)
                $fwrite(fd, "%c", tx_shadow[i]);
            $fclose(fd);
            $display("[TB] Output written to %s (%0d bytes)", out_path, tx_ptr);
        end

        $finish;
    end

endmodule
