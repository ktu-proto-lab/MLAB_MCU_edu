`include "project_defs.svh"
`include "../../tb/misc/tb.v"

//==================================================
// Configs
//==================================================
// Software directory.
parameter program_folder="test/full_peripheral_v2";
integer expected_ext_pad_io = 12'b0000_0011_1111;

module simple_system_tb;

    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 12.5;  
    parameter MEMInitFile = {"../../sw/ibex/",program_folder,"/build/verilog_hex.v"};

`ifdef LOG_OUTPUT
    // Output file of the tb info.
    parameter file="../../tb/log/full_peripheral_v2.log";
    // Output file descriptor.
    int fd;
`endif

    logic clk_sys, rst_sys_n, test_mode;
    assign test_mode = 1'b0;
 
    // GPIO signals
     wire [GPIO_COUNT-1:0] ext_pad_io;

    // Testbench driven GPIO control
    logic [GPIO_COUNT-1:0] input_val;
    logic [GPIO_COUNT-1:0] output_value;
    logic [GPIO_COUNT-1:0] out_valid;

    // I2C signals
    logic i2c_int; 

    // I2C signals
    wire  SDA, SCL;

    // Instantiate DUT
    ibex_simple_system dut 
    (
        .clk_sys_Pad    (clk_sys),
        .rst_sys_n_Pad  (rst_sys_n),  
        .SDA_Pad        (SDA),
        .SCL_Pad        (SCL),
        .ext_pad        (ext_pad_io),
        .test_mode_Pad        (test_mode)
    );

    // Instantiate external EEPROM
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

    // Clock generation
    always begin
        #(CLK_PERIOD / 2) clk_sys = ~clk_sys;
    end

    // GPIO inout signal control
    assign input_val = ext_pad_io;
    assign ext_pad_io = out_valid ? output_value : 'hZ;
    
    // Add pull-down resistors for inout signal
    genvar j;
    generate
        for(j=0; j<GPIO_COUNT; j++)begin
        assign ext_pad_io[j] = out_valid[j] ? output_value[j] : 'hZ;
        pulldown(ext_pad_io[j]);
        end
    endgenerate

    // Pull-up on I2C lines
    pullup(SDA);
    pullup(SCL);

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
        #(CLK_PERIOD*1)

        // Initial top signal values
        clk_sys = 1'b0;
        out_valid = 0;
        rst_sys_n = 1'b0;
        #(CLK_PERIOD*4)
        rst_sys_n = 1'b1;

        tb.wait_bootloader;
        tb.memory_write_back_test;
        
        // Wait for startup code to finish and for main to jump into while(1)
        #1_000_000;

        // Set GPIO8 (start the sw state machine)
        out_valid = 1;
        output_value = 1 << 8;
        #100; 
        
        // Reset GPIO0
        out_valid =  0; 

        // Wait for state machine to complete
        #10_000_000;

        // If GPIOs 0-4 are set after simulation then test is successful
        if (ext_pad_io == expected_ext_pad_io) begin 
            $display("[SUCCESS]: all 6 stages of the full peripheral test are passed: expected GPIO values = %012b, actual = %012b", expected_ext_pad_io, ext_pad_io);
`ifdef LOG_OUTPUT
            $fwrite(fd, "[SUCCESS]: all 6 stages of the full peripheral test are passed: expected GPIO values = %012b, actual = %012b\n", expected_ext_pad_io, ext_pad_io);
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
        $finish();
`endif
        $stop();
    end

`ifdef SDF
    // SDF annotate (Add real delays) for post pnr sim
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",simple_system_tb.dut,,"sdf.log","MAXIMUM");
    end
`endif

endmodule
