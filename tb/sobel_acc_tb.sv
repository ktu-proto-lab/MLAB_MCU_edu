/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
  Description:
    * Isolated testbench for sobel_acc.
    *
    * Workflow:
    *   1. Set SRC_IMAGE to one of the P2 PGMs in src_images/.
    *   2. Run this testbench.
    *   3. Open the matching file in out_images/ for visual verification.
    *
    * The testbench emulates the FWFT FIFO directly
    * All writes to BRAM B are shadowed into an array; the array
    * is used for verification and written out as a P2 ASCII PGM.
    *
    * Input images must be P2 ASCII PGM, 320x240, with exactly one
    * comment line after the magic number (matching the src_images/ files).
*/
`include "project_defs.svh"

module sobel_acc_tb;

    // -------------------------------------------------------------------------
    localparam int  FRAME_W      = 320;
    localparam int  FRAME_H      = 240;
    localparam int  TOTAL_PIXELS = FRAME_W * FRAME_H;
    localparam int  FRAME_WORDS  = TOTAL_PIXELS / 4; // 19200
    localparam real CLK_PERIOD   = 10.0;

    localparam string SRC_IMAGE    = "baboon.pgm";
    localparam string SRC_IMG_PATH = "../../tb/src_images/";
    localparam string OUT_IMG_PATH = "../../tb/out_images/";

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
    // FIFO emulation (FWFT: dout valid whenever empty=0, no read latency)
    // -------------------------------------------------------------------------
    logic [31:0] src_mem [0:FRAME_WORDS-1];
    int          fifo_ptr;

    logic        fifo_empty;
    logic [31:0] fifo_dout;
    logic        fifo_rd_en; // driven by DUT

    assign fifo_empty = (fifo_ptr >= FRAME_WORDS);
    assign fifo_dout  = fifo_empty ? 32'h0 : src_mem[fifo_ptr];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fifo_ptr <= 0;
        else if (fifo_rd_en && !fifo_empty)
            fifo_ptr <= fifo_ptr + 1;
    end

    // -------------------------------------------------------------------------
    // BRAM B signals (driven by DUT)
    // -------------------------------------------------------------------------
    logic        dst_en, dst_we;
    logic [14:0] dst_addr;
    logic [31:0] dst_wdata, dst_rdata;

    // Shadow: capture every write - used for verify + PGM output
    logic [31:0] shadow [0:FRAME_WORDS-1];
    always_ff @(posedge clk) begin
        if (dst_en && dst_we)
            shadow[dst_addr] <= dst_wdata;
    end

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    sobel_acc u_dut (
        .wb            (wb),
        .frame_ready_i (1'b0),
        .fifo_empty    (fifo_empty),
        .fifo_dout     (fifo_dout),
        .fifo_rd_en    (fifo_rd_en),
        .dst_en        (dst_en),
        .dst_we        (dst_we),
        .dst_addr      (dst_addr),
        .dst_wdata     (dst_wdata),
        .dst_rdata     (dst_rdata)
    );

    bram u_bram_b (
        .clk   (clk),
        .en    (dst_en),
        .we    (dst_we),
        .addr  (dst_addr),
        .wdata (dst_wdata),
        .rdata (dst_rdata)
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
    integer      fd, errors, tmp_val;
    string       hdr_str, out_path;
    logic [7:0]  pixels_in  [0:TOTAL_PIXELS-1];
    logic [7:0]  pixels_out [0:TOTAL_PIXELS-1];
    logic [31:0] status, frame_count;

    initial begin
        // ------------------------------------------------------------------
        // Read input PGM (P2 ASCII, one comment line)
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
            pixels_in[i] = tmp_val[7:0];
        end
        $fclose(fd);
        $display("[TB] Loaded %s%s", SRC_IMG_PATH, SRC_IMAGE);

        // Pack pixels into 32-bit words (4 pixels/word, LSB = first pixel)
        for (int i = 0; i < FRAME_WORDS; i++)
            src_mem[i] = {pixels_in[i*4+3], pixels_in[i*4+2],
                          pixels_in[i*4+1], pixels_in[i*4+0]};

        // ------------------------------------------------------------------
        // Release reset
        // ------------------------------------------------------------------
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        repeat(4) @(posedge clk);

        // Start (algo_sel=0: pixel inversion)
        wb_write(`SOBEL_BASE_ADDR, 32'h1);
        $display("[TB] Started - polling for done...");

        // Poll STATUS.done (bit 1)
        do wb_read(`SOBEL_BASE_ADDR + 32'h4, status);
        while (!(status & 32'h2));

        wb_read(`SOBEL_BASE_ADDR + 32'h8, frame_count);
        $display("[TB] Done. STATUS=%08h  FRAME_COUNT=%0d", status, frame_count);

        // ------------------------------------------------------------------
        // Verify against golden reference (pixel inversion)
        // ------------------------------------------------------------------
        errors = 0;
        for (int i = 0; i < FRAME_WORDS; i++) begin
            if (shadow[i] !== ~src_mem[i]) begin
                if (errors < 8)
                    $display("[FAIL] word %0d: expected %08h  got %08h",
                             i, ~src_mem[i], shadow[i]);
                errors++;
            end
        end

        if (errors == 0)
            $display("[PASS] All %0d words match.", FRAME_WORDS);
        else
            $display("[FAIL] %0d / %0d words mismatched.", errors, FRAME_WORDS);

        // ------------------------------------------------------------------
        // Unpack shadow into pixel array
        // ------------------------------------------------------------------
        for (int i = 0; i < FRAME_WORDS; i++) begin
            pixels_out[i*4+0] = shadow[i][ 7: 0];
            pixels_out[i*4+1] = shadow[i][15: 8];
            pixels_out[i*4+2] = shadow[i][23:16];
            pixels_out[i*4+3] = shadow[i][31:24];
        end

        // ------------------------------------------------------------------
        // Write output PGM (P2 ASCII)
        // ------------------------------------------------------------------
        out_path = {OUT_IMG_PATH, SRC_IMAGE.substr(0, SRC_IMAGE.len()-5), "_out.pgm"};
        fd = $fopen(out_path, "w");
        if (!fd) begin
            $display("[TB] Cannot open %s", out_path);
        end else begin
            $fwrite(fd, "P2\n# Output\n%0d %0d\n255\n", FRAME_W, FRAME_H);
            for (int i = 0; i < TOTAL_PIXELS; i++)
                $fwrite(fd, "%0d\n", pixels_out[i]);
            $fclose(fd);
            $display("[TB] Output written to %s", out_path);
        end

        $finish;
    end

endmodule
