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
    * Camera FIFO is emulated as an 8-bit FWFT model (one pixel per word).
    * Output pixels are captured from the intermediate FIFO write port and
    * written out as a P2 ASCII PGM.
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
    // Camera FIFO emulation (FWFT, 8-bit: dout valid whenever empty=0)
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
    // Intermediate FIFO emulation (receives output from DUT)
    // Capture every write into a shadow array for verification and PGM output.
    // -------------------------------------------------------------------------
    logic       out_wr_en; // driven by DUT
    logic [7:0] out_din;   // driven by DUT
    logic       out_full;  // driven by TB (never full - infinite sink)

    assign out_full = 1'b0;

    logic [7:0] shadow [0:TOTAL_PIXELS-1];
    int         shadow_ptr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_ptr <= 0;
        end else if (out_wr_en) begin
            shadow[shadow_ptr] <= out_din;
            shadow_ptr         <= shadow_ptr + 1;
        end
    end

    // -------------------------------------------------------------------------
    // Simulation timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        #10_000_000; // 10 ms @ 100 MHz - far more than one frame needs
        $fatal(1, "[TB] Simulation timeout at %0t ns", $time);
    end

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    sobel_acc u_dut (
        .wb         (wb),
        .fifo_empty (fifo_empty),
        .fifo_dout  (fifo_dout),
        .fifo_rd_en (fifo_rd_en),
        .out_wr_en  (out_wr_en),
        .out_din    (out_din),
        .out_full   (out_full)
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
            src_mem[i] = tmp_val[7:0];
        end
        $fclose(fd);
        $display("[TB] Loaded %s%s (%0d pixels)", SRC_IMG_PATH, SRC_IMAGE, TOTAL_PIXELS);

        // ------------------------------------------------------------------
        // Release reset
        // ------------------------------------------------------------------
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        repeat(4) @(posedge clk);

        // Start with auto_start=1, algo_sel=0 (pixel inversion reference)
        wb_write(`SOBEL_BASE_ADDR, 32'h1);
        $display("[TB] Started - polling for done...");

        // Poll STATUS.done (bit 1)
        do wb_read(`SOBEL_BASE_ADDR + 32'h4, status);
        while (!(status & 32'h2));

        wb_read(`SOBEL_BASE_ADDR + 32'h8, frame_count);
        $display("[TB] Done. STATUS=%08h  FRAME_COUNT=%0d  shadow_ptr=%0d",
                 status, frame_count, shadow_ptr);

        // ------------------------------------------------------------------
        // Verify against golden reference (pixel inversion)
        // ------------------------------------------------------------------
        errors = 0;
        for (int i = 0; i < TOTAL_PIXELS; i++) begin
            if (shadow[i] !== ~src_mem[i]) begin
                if (errors < 8)
                    $display("[FAIL] pixel %0d: expected %02h  got %02h",
                             i, ~src_mem[i], shadow[i]);
                errors++;
            end
        end

        if (errors == 0)
            $display("[PASS] All %0d pixels match.", TOTAL_PIXELS);
        else
            $display("[FAIL] %0d / %0d pixels mismatched.", errors, TOTAL_PIXELS);

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
                $fwrite(fd, "%0d\n", shadow[i]);
            $fclose(fd);
            $display("[TB] Output written to %s", out_path);
        end

        $finish;
    end

endmodule
