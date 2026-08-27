/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
  Description:
    * Full-system testbench for compress_acc integrated in ibex_simple_system.
    *
    * Workflow:
    *   1. Load SRC_IMAGE (*_edge.pgm, already Sobel-processed) into a byte array.
    *   2. Reset and allow the CPU to boot
    *   3. Force inter_din/inter_wr_en (driven by sobel_acc in RTL) to inject
    *      pixels directly into the intermediate FIFO, bypassing sobel_acc.
    *   4. The CPU writes COMPRESS_CTRL=1, polls COMPRESS_STATUS.done, reads
    *      COMPRESSED_SIZE, then raises GPIO0.
    *   5. TB forces tx_rd_en high whenever tx_empty is low to drain the TX FIFO
    *      and shadows each byte into tx_shadow[].
    *   6. On GPIO0 high: write compressed bytes to a binary file.
    *
    * NOTE: sobel_acc is present in the DUT but its output path is overridden
    *       by force, so it plays no role in this test.
*/
`include "project_defs.svh"

module simple_system_tb;

    // -------------------------------------------------------------------------
    localparam int  FRAME_W      = 320;
    localparam int  FRAME_H      = 240;
    localparam int  TOTAL_PIXELS = FRAME_W * FRAME_H;
    localparam int  TX_MAX_BYTES = TOTAL_PIXELS * 2; // worst-case RLE 2x
    localparam real CLK_PERIOD   = 12.5;             // 80 MHz

    localparam string SRC_IMAGE    = "pattern_checkerboard.pgm";
    localparam string SRC_IMG_PATH = "../../tb/src_images/";
    localparam string OUT_IMG_PATH = "../../tb/out2_images/";

    parameter string program_folder  = "test/compress_acc";
    parameter string IMEM_1_InitFile = {"../../sw/ibex/", program_folder, "/build/instr_hex_1.mem"};
    parameter string IMEM_2_InitFile = {"../../sw/ibex/", program_folder, "/build/instr_hex_2.mem"};
    parameter string DMEM_InitFile   = {"../../sw/ibex/", program_folder, "/build/data_hex.mem"};

    parameter MEMInitFile = {"../../sw/ibex/", program_folder, "/build/verilog_hex.v"};

    // -------------------------------------------------------------------------
    // Clock / reset
    // -------------------------------------------------------------------------
    logic clk_sys   = 1'b0;
    logic rst_sys_n = 1'b0;
    always #(CLK_PERIOD / 2) clk_sys = ~clk_sys;

    // -------------------------------------------------------------------------
    // I2C pads (unused; tied high = idle)
    // -------------------------------------------------------------------------
    logic scl_pad_i = 1'b1, scl_pad_o, scl_padoen_o;
    logic sda_pad_i = 1'b1, sda_pad_o, sda_padoen_o;

    // -------------------------------------------------------------------------
    // GPIO
    // -------------------------------------------------------------------------
    logic [`GPIO_IOS-1:0] ext_pad_i = '0;
    logic [`GPIO_IOS-1:0] gpio_o, gpio_oe;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    ibex_simple_system #(
        .IMEM_1_InitFile(IMEM_1_InitFile),
        .IMEM_2_InitFile(IMEM_2_InitFile),
        .DMEM_InitFile  (DMEM_InitFile)
    ) dut (
        .clk_sys      (clk_sys),
        .rst_async_n  (rst_sys_n),
        .scl_pad_i    (scl_pad_i),
        .scl_pad_o    (scl_pad_o),
        .scl_padoen_o (scl_padoen_o),
        .sda_pad_i    (sda_pad_i),
        .sda_pad_o    (sda_pad_o),
        .sda_padoen_o (sda_padoen_o),
        .ext_pad_i    (ext_pad_i),
        .gpio_o       (gpio_o),
        .gpio_oe      (gpio_oe)
    );

    // -------------------------------------------------------------------------
    // TX shadow: capture bytes as they leave the TX FIFO
    // -------------------------------------------------------------------------
    logic [7:0] tx_shadow [0:TX_MAX_BYTES-1];
    int         tx_ptr;

    always_ff @(posedge clk_sys) begin
        if (!rst_sys_n) begin
            tx_ptr <= 0;
        end else if (!dut.tx_empty && dut.tx_rd_en) begin
            tx_shadow[tx_ptr] <= dut.tx_dout;
            tx_ptr            <= tx_ptr + 1;
        end
    end

    // Drain the TX FIFO continuously so compress_acc never stalls on backpressure
    always @(posedge clk_sys)
        force dut.tx_rd_en = !dut.tx_empty;

    // -------------------------------------------------------------------------
    // Main test
    // -------------------------------------------------------------------------
    logic [7:0] src_mem [0:TOTAL_PIXELS-1];
    integer     fd, tmp_val;
    integer     fifo_i = 0;
    string      hdr_str, out_path;

    initial begin
        // ------------------------------------------------------------------
        // Load Sobel-processed PGM (P2 ASCII, one comment line)
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
        force dut.inter_wr_en = 1'b0;
        force dut.inter_din   = 8'h0;

        rst_sys_n = 1'b0;
        repeat(4) @(posedge clk_sys);
        rst_sys_n = 1'b1;

        // Allow CPU to boot and reach main()
        #200_000;

        // ------------------------------------------------------------------
        // Inject pixels into the intermediate FIFO one byte at a time,
        // honouring inter_full (backpressure from the FIFO).
        // ------------------------------------------------------------------
        while (fifo_i < TOTAL_PIXELS) begin
            if (!dut.inter_full) begin
                force dut.inter_din   = src_mem[fifo_i];
                force dut.inter_wr_en = 1'b1;
                @(posedge clk_sys);
                fifo_i++;
            end else begin
                force dut.inter_wr_en = 1'b0;
                @(posedge clk_sys);
            end
        end
        @(posedge clk_sys); #1;
        force dut.inter_wr_en = 1'b0;
        release dut.inter_wr_en;
        release dut.inter_din;
        $display("[TB] Inter-FIFO feeder: all %0d pixels written.", TOTAL_PIXELS);

        // ------------------------------------------------------------------
        // Wait for CPU to raise GPIO0 (signals frame complete + CSR read done)
        // ------------------------------------------------------------------
        wait (gpio_oe[0] && gpio_o[0]);
        $display("[TB] CPU signaled done at %0t ns. tx_bytes=%0d", $time, tx_ptr);
        @(posedge clk_sys);

        // ------------------------------------------------------------------
        // Write compressed output as raw binary
        // ------------------------------------------------------------------
        out_path = {OUT_IMG_PATH,
                    SRC_IMAGE.substr(0, SRC_IMAGE.len()-5),
                    "_full_compressed.bin"};
        fd = $fopen(out_path, "wb");
        if (!fd) begin
            $display("[TB] Cannot open output file %s", out_path);
        end else begin
            for (int i = 0; i < tx_ptr; i++)
                $fwrite(fd, "%c", tx_shadow[i]);
            $fclose(fd);
            $display("[TB] Output written to %s (%0d bytes)", out_path, tx_ptr);
            $display("[TB] Compression ratio: %.3f  (%0d -> %0d bytes)",
                     real'(tx_ptr) / real'(TOTAL_PIXELS),
                     TOTAL_PIXELS, tx_ptr);
        end

        $finish;
    end

    // -------------------------------------------------------------------------
    // Simulation timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        #100_000_000; // 100 ms @ 80 MHz
        $fatal(1, "[TB] Simulation timeout at %0t ns", $time);
    end

endmodule
