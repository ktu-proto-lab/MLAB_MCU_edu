/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
  Description:
    * Full-system testbench for sobel_acc integrated in ibex_simple_system.
    *
    * Workflow:
    *   1. Load SRC_IMAGE from src_images/ into a packed word array.
    *   2. Reset and allow the CPU to boot (BOOT_SKIP mode, SRAM pre-loaded).
    *   3. Force fifo_din/fifo_wr_en (tied off in RTL) to write pixel words into camera FIFO.
    *   4. The CPU writes SOBEL_CTRL=1, polls STATUS.done, then raises GPIO0.
    *   5. TB detects GPIO0 high, reads Frame BRAM B, verifies against ~src.
    *   6. Write output as P2 PGM for visual inspection.
    *
    * The FIFO feeder writes sequentially before waiting for the CPU signal;
    * fifo_full stalls the feeder while the accelerator drains the 1024-word FIFO.
*/
`include "project_defs.svh"

module simple_system_tb;

    // -------------------------------------------------------------------------
    localparam int  FRAME_W      = 320;
    localparam int  FRAME_H      = 240;
    localparam int  TOTAL_PIXELS = FRAME_W * FRAME_H;
    localparam int  FRAME_WORDS  = TOTAL_PIXELS / 4;  // 19200
    localparam real CLK_PERIOD   = 12.5;              // 80 MHz

    localparam string SRC_IMAGE    = "pattern.pgm";
    localparam string SRC_IMG_PATH = "../../tb/src_images/";
    localparam string OUT_IMG_PATH = "../../tb/out_images/";

    parameter string program_folder  = "test/sobel_acc";
    parameter string IMEM_1_InitFile = {"../../sw/ibex/", program_folder, "/build/instr_hex_1.mem"};
    parameter string IMEM_2_InitFile = {"../../sw/ibex/", program_folder, "/build/instr_hex_2.mem"};
    parameter string DMEM_InitFile   = {"../../sw/ibex/", program_folder, "/build/data_hex.mem"};

    // BELOW IS ONLY FOR WARNING. Need to either remove M24CS512 from file list or initialize (the later is chosen)
    parameter MEMInitFile = {"../../sw/ibex/",program_folder,"/build/verilog_hex.v"};
    // -------------------------------------------------------------------------
    // Clock / reset
    // -------------------------------------------------------------------------
    logic clk_sys   = 1'b0;
    logic rst_sys_n = 1'b0;
    always #(CLK_PERIOD / 2) clk_sys = ~clk_sys;

    // -------------------------------------------------------------------------
    // I2C pads (unused by this test; tied high = idle)
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
    // Image buffers
    // -------------------------------------------------------------------------
    logic [31:0] src_mem    [0:FRAME_WORDS-1];
    logic [7:0]  pixels_in  [0:TOTAL_PIXELS-1];
    logic [7:0]  pixels_out [0:TOTAL_PIXELS-1];

    // -------------------------------------------------------------------------
    // Simulation timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        #50_000_000; // 50 ms @ 80 MHz = 4 M cycles - far more than needed
        $fatal(1, "[TB] Simulation timeout at %0t ns", $time);
    end

    // -------------------------------------------------------------------------
    // Main test
    // -------------------------------------------------------------------------
    integer fd, errors, tmp_val;
    integer fifo_i;           // FIFO feeder index - must be module-level (static)
    string  hdr_str, out_path;

    initial begin
        // ------------------------------------------------------------------
        // Load source PGM (P2 ASCII, one comment line)
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

        // Pack into 32-bit words (LSB = first pixel)
        for (int i = 0; i < FRAME_WORDS; i++)
            src_mem[i] = {pixels_in[i*4+3], pixels_in[i*4+2],
                          pixels_in[i*4+1], pixels_in[i*4+0]};

        // ------------------------------------------------------------------
        // Reset
        // ------------------------------------------------------------------
        rst_sys_n = 1'b0;
        repeat(4) @(posedge clk_sys);
        rst_sys_n = 1'b1;

        // Allow startup code (~200 µs = 16 000 cycles) to reach main()
        #200_000;

        // ------------------------------------------------------------------
        // Feed FIFO via write port, respecting fifo_full backpressure.
        // fifo_din and fifo_wr_en are tied to constants in RTL; override
        // them with force so the Xilinx FIFO model sees real data.
        // ------------------------------------------------------------------
        fifo_i = 0;
        force dut.fifo_wr_en = 1'b0;
        force dut.fifo_din   = 32'h0;
        while (fifo_i < FRAME_WORDS) begin
            @(posedge clk_sys);
            if (!dut.fifo_full) begin
                force dut.fifo_din   = src_mem[fifo_i];
                force dut.fifo_wr_en = 1'b1;
                fifo_i++;
            end else begin
                force dut.fifo_wr_en = 1'b0;
            end
        end
        @(posedge clk_sys);
        force dut.fifo_wr_en = 1'b0;
        release dut.fifo_wr_en;
        release dut.fifo_din;
        $display("[TB] FIFO feeder: all %0d words written.", FRAME_WORDS);

        // ------------------------------------------------------------------
        // Wait for CPU to raise GPIO0 (gpio_oe[0]=1 AND gpio_o[0]=1).
        // gpio_o is a registered signal updated via NBA, so the iff clause
        // correctly samples it post-NBA after the CPU's write takes effect.
        // ------------------------------------------------------------------
        @(posedge clk_sys iff (gpio_oe[0] && gpio_o[0]));
        $display("[TB] CPU signaled done at %0t ns.", $time);

        // ------------------------------------------------------------------
        // Verify Frame BRAM B contents against bitwise-inverted source
        // ------------------------------------------------------------------
        errors = 0;
        for (int i = 0; i < FRAME_WORDS; i++) begin
            if (dut.u_frame_bram_b.mem[i] !== ~src_mem[i]) begin
                if (errors < 8)
                    $display("[FAIL] word %0d: expected %08h  got %08h",
                             i, ~src_mem[i], dut.u_frame_bram_b.mem[i]);
                errors++;
            end
        end
        if (errors == 0)
            $display("[PASS] All %0d words match.", FRAME_WORDS);
        else
            $display("[FAIL] %0d / %0d words mismatched.", errors, FRAME_WORDS);

        // ------------------------------------------------------------------
        // Unpack BRAM B into pixel array and write output PGM
        // ------------------------------------------------------------------
        for (int i = 0; i < FRAME_WORDS; i++) begin
            pixels_out[i*4+0] = dut.u_frame_bram_b.mem[i][ 7: 0];
            pixels_out[i*4+1] = dut.u_frame_bram_b.mem[i][15: 8];
            pixels_out[i*4+2] = dut.u_frame_bram_b.mem[i][23:16];
            pixels_out[i*4+3] = dut.u_frame_bram_b.mem[i][31:24];
        end

        out_path = {OUT_IMG_PATH, SRC_IMAGE.substr(0, SRC_IMAGE.len()-5), "_full_out.pgm"};
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
