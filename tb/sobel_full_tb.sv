/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
  Description:
    * Full-system testbench for sobel_acc integrated in ibex_simple_system.
    *
    * Workflow:
    *   1. Load SRC_IMAGE from src_images/ into a byte array.
    *   2. Reset and allow the CPU to boot (BOOT_SKIP mode, SRAM pre-loaded).
    *   3. Force fifo_din/fifo_wr_en (tied off in RTL) to write pixels one byte
    *      at a time into the camera FIFO.
    *   4. The CPU writes SOBEL_CTRL=1, polls FRAME_COUNT, then raises GPIO0.
    *   5. TB shadows inter_wr_en/inter_din to capture processed pixels as they
    *      are written to the intermediate FIFO.
    *   6. On GPIO0 high: verify shadow against ~src, write output PGM.
*/
`include "project_defs.svh"

module simple_system_tb;

    // -------------------------------------------------------------------------
    localparam int  FRAME_W      = 320;
    localparam int  FRAME_H      = 240;
    localparam int  TOTAL_PIXELS = FRAME_W * FRAME_H;
    localparam real CLK_PERIOD   = 12.5;              // 80 MHz

    localparam string SRC_IMAGE    = "baboon.pgm";
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
    logic [7:0] src_mem    [0:TOTAL_PIXELS-1];
    logic [7:0] shadow     [0:TOTAL_PIXELS-1];
    int         shadow_ptr;

    // -------------------------------------------------------------------------
    // Capture intermediate FIFO writes (sobel_acc output) into shadow array.
    // inter_wr_en and inter_din are module-level wires in ibex_simple_system.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk_sys) begin
        if (dut.inter_wr_en) begin
            shadow[shadow_ptr] <= dut.inter_din;
            shadow_ptr         <= shadow_ptr + 1;
        end
    end

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
    integer fifo_i = 0;           // FIFO feeder index - must be module-level (static)
    string  hdr_str, out_path;

    initial begin
        shadow_ptr = 0;

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
            src_mem[i] = tmp_val[7:0];
        end
        $fclose(fd);
        $display("[TB] Loaded %s%s (%0d pixels)", SRC_IMG_PATH, SRC_IMAGE, TOTAL_PIXELS);

        // ------------------------------------------------------------------
        // Reset
        // ------------------------------------------------------------------
        // Force camera FIFO inputs to inactive
        force dut.fifo_wr_en = 1'b0;
        force dut.fifo_din   = 8'h0;

        rst_sys_n = 1'b0;
        repeat(4) @(posedge clk_sys);
        rst_sys_n = 1'b1;

        // Allow startup code (~200 µs = 16 000 cycles) to reach main()
        #200_000;

        // ------------------------------------------------------------------
        // Feed camera FIFO one pixel (byte) at a time, honouring fifo_full.
        // fifo_din and fifo_wr_en are tied to constants in RTL; override
        // them with force so the FIFO model sees real data.
        // ------------------------------------------------------------------
        force dut.fifo_din   = src_mem[fifo_i];
        force dut.fifo_wr_en = 1'b1;
        @(posedge clk_sys);

        while (fifo_i < TOTAL_PIXELS) begin
            if (!dut.fifo_full) begin
                force dut.fifo_din   = src_mem[fifo_i];
                force dut.fifo_wr_en = 1'b1;
                @(posedge clk_sys);
                fifo_i++;
            end else begin
                force dut.fifo_wr_en = 1'b0;
                @(posedge clk_sys);
            end
        end
        @(posedge clk_sys); #1;
        force dut.fifo_wr_en = 1'b0;
        release dut.fifo_wr_en;
        release dut.fifo_din;
        $display("[TB] FIFO feeder: all %0d pixels written.", TOTAL_PIXELS);

        // ------------------------------------------------------------------
        // Wait for CPU to raise GPIO0 (gpio_oe[0]=1 AND gpio_o[0]=1).
        // ------------------------------------------------------------------
        wait (gpio_oe[0] && gpio_o[0]);
        $display("[TB] CPU signaled done at %0t ns. shadow_ptr=%0d",
                 $time, shadow_ptr);
        @(posedge clk_sys); // allow last shadow write to settle

        // ------------------------------------------------------------------
        // Verify intermediate FIFO shadow against bitwise-inverted source
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
        out_path = {OUT_IMG_PATH, SRC_IMAGE.substr(0, SRC_IMAGE.len()-5), "_full_out.pgm"};
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
