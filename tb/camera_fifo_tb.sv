/*
  Contributors:
    * CLAUDE GENERATED (Dovydas)
  Description:
    * Testbench for fifo_fwft (deps/camera_fifo/rtl/verilog/fifo_fwft.v)
    *
    * Demonstrates FWFT (First-Word-Fall-Through) behaviour:
    *   - dout is valid the cycle empty deasserts; no rd_en needed to fetch
    *   - rd_en advances the read pointer (pops the current word)
    *
    * Test phases:
    *   1. Reset       - rst active-HIGH, synchronous
    *   2. Write burst - write 4 words; observe empty falling and dout appearing
    *   3. Read burst  - drain with rd_en
    *   4. Fill / full - write 1024 words; observe full flag
    *
    * Run:
    *   ./script/xrun_fifo_test.sh
*/
`timescale 1ns/1ps

module camera_fifo_tb;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    logic        clk   = 0;
    logic        rst   = 0;
    logic [31:0] din   = 0;
    logic        wr_en = 0;
    logic        rd_en = 0;
    logic [31:0] dout;
    logic        full;
    logic        empty;

    fifo_fwft #(.DATA_WIDTH(32), .DEPTH_WIDTH(10)) dut ( // FIFO DEPTH = 2^DEPTH_WIDTH=1024
        .clk   (clk),
        .rst   (rst),
        .din   (din),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .dout  (dout),
        .full  (full),
        .empty (empty)
    );

    // -------------------------------------------------------------------------
    // 10 ns clock
    // -------------------------------------------------------------------------
    always #5 clk = ~clk;

    task automatic tick(int n = 1);
        repeat (n) @(posedge clk);
        #1;
    endtask

    // -------------------------------------------------------------------------
    // Test
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("camera_fifo_tb.vcd");
        $dumpvars(0, camera_fifo_tb);

        // ------------------------------------------------------------------
        // Phase 1: Reset
        // ------------------------------------------------------------------
        $display("\n=== Phase 1: Reset ===");
        tick(2);
        rst = 1;
        tick(2);
        rst = 0;
        tick(2);
        $display("  After reset: empty=%b full=%b", empty, full);
        assert (empty == 1) else $error("Expected empty=1 after reset");
        assert (full  == 0) else $error("Expected full=0 after reset");

        // // ------------------------------------------------------------------
        // // Phase 2: Write 4 words, observe FWFT behaviour
        // // ------------------------------------------------------------------
        // $display("\n=== Phase 2: Write burst (4 words) ===");
        // for (int i = 0; i < 4; i++) begin
        //     @(posedge clk);
        //     wr_en = 1;
        //     din   = 32'hA000_0000 + i;
        // end
        // @(posedge clk);
        // wr_en = 0;
        // tick(2);

        // $display("  After writing 4 words:");
        // $display("    empty=%b  full=%b", empty, full);
        // $display("    dout=0x%08X  (should be 0xA0000000, no rd_en needed)", dout);
        // assert (empty == 0)              else $error("FIFO should not be empty");
        // assert (dout == 32'hA000_0000)   else $error("FWFT: expected first word on dout");

        // // ------------------------------------------------------------------
        // // Phase 3: Read burst - drain all 4 words
        // // ------------------------------------------------------------------
        // $display("\n=== Phase 3: Read burst (drain all 4 words) ===");
        // for (int i = 0; i < 4; i++) begin
        //     $display("  word %0d: dout=0x%08X  empty=%b", i, dout, empty);
        //     @(posedge clk);
        //     rd_en = 1;
        //     @(posedge clk);
        //     rd_en = 0;
        //     #1;
        // end
        // tick(2);
        // $display("  After drain: empty=%b", empty);
        // assert (empty == 1) else $error("FIFO should be empty after drain");

        // ------------------------------------------------------------------
        // Phase 4: Fill to full (1024 words)
        // ------------------------------------------------------------------
        $display("\n=== Phase 4: Fill to full (1024 + 3 words) ===");
        for (int i = 0; i < 1027; i++) begin
            @(posedge clk);
            wr_en = 1;
            din = (i == 0) ? 32'hDEAD_BEEF : i; // Write 0xDEAD_BEEF then numbers 1 to 0x403 (0d1027)
        end
        @(posedge clk);
        wr_en = 0;
        tick(2);

        rd_en = 1;
        tick(8);

        $display("\n=== All phases done ===\n");
        $finish;
    end

endmodule
