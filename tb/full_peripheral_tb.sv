`include "project_defs.svh"
`include "../../tb/misc/tb.v"

//==================================================
// Configs
//==================================================
// Software directory.d
parameter program_folder="test/full_peripheral";
integer expected_ext_pad_io = 12'b0000_0001_1111;

module simple_system_tb;

    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 12.5;  
    parameter MEMInitFile = {"../../sw/ibex/",program_folder,"/build/verilog_hex.v"};
    parameter IMEM_1_InitFile = {"../../sw/ibex/",program_folder,"/build/instr_hex_1.mem"};
    parameter IMEM_2_InitFile = {"../../sw/ibex/",program_folder,"/build/instr_hex_2.mem"};
    parameter DMEM_InitFile = {"../../sw/ibex/",program_folder,"/build/data_hex.mem"};

`ifdef LOG_OUTPUT
    // Output file of the tb info.
    parameter file="../../tb/log/full_peripheral.log";
    // Output file descriptor.
    int fd;
`endif

    //==================================================
    // Clock / reset
    //==================================================
    logic clk_sys;
    logic rst_sys_n;
    // logic test_mode = 1'b0;
 
    
    //==================================================
    // GPIO PAD (single shared tristate net)
    //==================================================
    tri [GPIO_COUNT-1:0] ext_pad_io;

    // TB GPIO control
    logic [GPIO_COUNT-1:0] output_value;
    logic [GPIO_COUNT-1:0] out_valid;

    //==================================================
    // I2C PADs
    //==================================================
    tri SDA;
    tri SCL;

    // DUT-facing I2C signals
    logic scl_pad_i, scl_pad_o, scl_padoen_o;
    logic sda_pad_i, sda_pad_o, sda_padoen_o;

    // DUT-facing GPIO
    logic [GPIO_COUNT-1:0] ext_pad_i;
    logic [GPIO_COUNT-1:0] gpio_o;
    logic [GPIO_COUNT-1:0] gpio_oe;

    //DUT-facing SPI
    logic o_qspi_sck;
    logic o_qspi_cs_n;
    logic [1:0] o_qspi_mod;
    logic [3:0] o_qspi_dat;
    logic [3:0] i_qspi_dat;

    tri [3:0] io_qspi_dat;

    //==================================================
    // DUT
    //==================================================
    ibex_simple_system #(
        .IMEM_1_InitFile(IMEM_1_InitFile),
        .IMEM_2_InitFile(IMEM_2_InitFile),
        .DMEM_InitFile(DMEM_InitFile)
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
        .gpio_oe      (gpio_oe),

        .o_qspi_sck   (o_qspi_sck),
        .o_qspi_cs_n  (o_qspi_cs_n),
        .o_qspi_mod   (o_qspi_mod),
        .o_qspi_dat   (o_qspi_dat),
        .i_qspi_dat   (i_qspi_dat)
    );

    //==================================================
    // I2C tristate modeling (open-drain)
    //==================================================
    assign SCL       = scl_padoen_o ? 1'bz : scl_pad_o;
    assign scl_pad_i = SCL;

    assign SDA       = sda_padoen_o ? 1'bz : sda_pad_o;
    assign sda_pad_i = SDA;

    // I2C pull-ups
    pullup(SCL);
    pullup(SDA);


    //==================================================
    // GPIO tristate modeling
    //==================================================
    // DUT drives pads
    assign ext_pad_io = gpio_oe ? gpio_o : 'z;

    // DUT reads pads
    assign ext_pad_i  = ext_pad_io;

    // TB drives pads + pulldown
    genvar j;
    generate
        for (j = 0; j < GPIO_COUNT; j++) begin : TB_GPIO
        assign ext_pad_io[j] =
            out_valid[j] ? output_value[j] : 1'bz;
        pulldown(ext_pad_io[j]);
        end
    endgenerate

    //==================================================
    // SPI tristate modeling
    //==================================================
    assign i_qspi_dat = io_qspi_dat;
    assign io_qspi_dat = (~o_qspi_mod[1])?({2'b11,1'bz,o_qspi_dat[0]}) // Serial mode
                        :((o_qspi_mod[0])?(4'bzzzz):(o_qspi_dat[3:0])); // Quad mode
    //==================================================
    // External EEPROM
    //==================================================
    M24CS512 #(
        .MEMInitFile(MEMInitFile)
    ) eeprom (
        .A0     (1'b0),
        .A1     (1'b0),
        .A2     (1'b0),
        .WP     (1'b0),  // No write protect
        .SDA    (SDA),
        .SCL    (SCL),
        .RESET  (1'b0)   // Reset without internal function
    );

    //==================================================
    // External Flash
    //==================================================
    sst26wf040b flash (
        .SCK    (o_qspi_sck),
        .SIO    (io_qspi_dat),
        .CEb    (o_qspi_cs_n)
    );
    initial #1 $readmemh(MEMInitFile, flash.I0.memory);

    //==================================================
    // Clock generation
    //==================================================
    always begin
        #(CLK_PERIOD / 2) clk_sys = ~clk_sys;
    end


    //==================================================
    // Testbench main
    //==================================================

    initial begin
`ifdef LOG_OUTPUT
        // Open output file with write permission.
        fd = $fopen ( file, "w");
        if (fd)  begin
            $display("[SUCCESS]: log output file '%s' opened succesfully", file);
            $fwrite(fd, "[   FLAG]: LOG_OUT_INIT\n");
        end else begin
            $display("[   FAIL]: log output file was not opened successfully: %0d", fd);
        end
`endif

        // Add delay to let scan_en propagate, this is so we don't get $setup timing violations for postpnr 
        // SDF annotated simulation
        // #(CLK_PERIOD*1)

        // Initial top signal values
        clk_sys = 1'b0;
        out_valid = 0;
        rst_sys_n = 1'b0;

        #(CLK_PERIOD*4)
        rst_sys_n = 1'b1;

        tb.wait_bootloader;
`ifdef BOOT_WRITEBACK
        tb.memory_write_back_test;
`endif
        // Wait for startup code to finish and for main to jump into while(1)
        #1_000_000;

        // Set GPIO8 (start the sw state machine)
        out_valid     = 1 << 8;
        output_value = 1 << 8;
      #100;
        
        // Reset GPIO
        out_valid =  0; 

        // Wait for state machine to complete
        #10_000_000;

        // If GPIOs 0-4 are set after simulation then test is successful
        if (ext_pad_io == expected_ext_pad_io) begin 
            $display("[SUCCESS]: all 5 stages of the full peripheral test are passed: expected GPIO values = %012b, actual = %012b", expected_ext_pad_io, ext_pad_io);
`ifdef LOG_OUTPUT
            $fwrite(fd, "[SUCCESS]: all 5 stages of the full peripheral test are passed: expected GPIO values = %012b, actual = %012b\n", expected_ext_pad_io, ext_pad_io);
            $fwrite(fd, "[   FLAG]: TEST_SUCCESS\n");
`endif
      end else begin
            $display("[   FAIL]:  expected GPIO values = %012b, actual = %012b", expected_ext_pad_io, ext_pad_io);
`ifdef LOG_OUTPUT
            $fwrite(fd, "[   FAIL]:  expected GPIO values = %012b, actual = %012b\n", expected_ext_pad_io, ext_pad_io);
            $fwrite(fd, "[   FLAG]: TEST_FAIL\n");
`endif
      end
        // Close log output file.
`ifdef LOG_OUTPUT
        $fclose(fd);
`endif
        $finish();
    end

`ifdef SDF
    // SDF annotate (Add real delays) for post pnr sim
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",
        simple_system_tb.dut,
        ,
        "sdf.log",
        "MAXIMUM");
    end
`endif

endmodule
