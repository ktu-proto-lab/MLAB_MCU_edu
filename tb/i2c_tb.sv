`include "project_defs.svh"
`include "../../tb/misc/tb.v"
`include "../../tb/misc/i2c_slave/i2cSlaveTop.v"
`include "../../tb/misc/i2c_slave/i2cSlave.v"
`include "../../tb/misc/i2c_slave/registerInterface.v"
`include "../../tb/misc/i2c_slave/serialInterface.v"



parameter program_folder="test/i2c";


module simple_system_tb;
    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 12.5;  
    parameter MEMInitFile = {"../../sw/ibex/",program_folder,"/build/verilog_hex.v"};
`ifdef LOG_OUTPUT
    // Output file of the tb info.
    parameter file="../../tb/log/i2c.log";
    // Output file descriptor.
    int fd;
`endif
    // Test success flag.
    integer flg_test_succ;

    logic clk_sys, rst_sys_n, test_mode;
    assign test_mode = 1'b0;
 
    // GPIO signals
     wire [GPIO_COUNT-1:0] ext_pad_io;

    // Testbench driven GPIO control
    logic [GPIO_COUNT-1:0] input_val;
    logic [GPIO_COUNT-1:0] output_value;
    logic [GPIO_COUNT-1:0] out_valid;

    // I2C signals
    logic      i2c_int; 

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
        .test_mode_Pad      (test_mode)
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

    // UART clocks_per_baud
    parameter [23:0] clocks_per_baud = 694;

    // UART data_to_send
    logic [7:0] data_to_send;

    // GPIO inout signal control
    assign input_val = ext_pad_io;
    // assign ext_pad_io = out_valid ? output_value : 'hZ;
    
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

    // Core Reset Control (for functional)
// `ifdef FUNCTIONAL
//     // Disable core until first spi byte arrives to ignore asserts
//     initial begin
//         force simple_system_tb.dut.rst_core_n = 1'b0;
//         #500;
//         release simple_system_tb.dut.rst_core_n;
//     end
// `endif    

    reg [7:0] dataReg [0:255];

    i2cSlaveTop i2c_slave (
        .clk    (clk_sys),
        .rst    (~rst_sys_n),
        .sda    (SDA),
        .scl    (SCL),
        .dataReg(dataReg)
    );
    reg [15:0] new_number;


    //==================================================
    // Testbench main
    //==================================================
`ifdef DUMPVCD
    // initial begin
    //     $dumpfile("output.vcd");
    //     $dumpvars(0,simple_system_tb);
    // end
`endif 
    initial begin

`ifdef LOG_OUTPUT
        // If 0, means not all stages of the test were passed.
        flg_test_succ = 1;
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
        rst_sys_n = 1'b1;
        #(CLK_PERIOD*8)
        rst_sys_n = 1'b0;
        #(CLK_PERIOD*4)
        rst_sys_n = 1'b1;
        

        // $display(`RANDOM_NUMBER);
        tb.wait_bootloader;
        tb.memory_write_back_test;
        
        // Time for timer test program to end
        #10_000_000
        new_number = dataReg[128] * dataReg[129];
        $display( "Expected values: 0x%0h 0x%0h 0x%0h 0x%0h", dataReg[128], dataReg[129], new_number[15:8], new_number[7:0]);
        `ifdef LOG_OUTPUT
        $fwrite(fd, "[   FLAG]: expected: 0x%0h 0x%0h 0x%0h 0x%0h\n", dataReg[128], dataReg[129], new_number[15:8], new_number[7:0]);
        `endif
        $display( "Received values: 0x%0h 0x%0h 0x%0h 0x%0h", dataReg[0], dataReg[1], dataReg[2], dataReg[3]);
        `ifdef LOG_OUTPUT
        $fwrite(fd, "[   FLAG]: actual: 0x%0h 0x%0h 0x%0h 0x%0h\n", dataReg[0], dataReg[1], dataReg[2], dataReg[3]);
        `endif
        if (dataReg[0] == dataReg[128] && 
            dataReg[1] == dataReg[129] &&
            dataReg[2] == new_number[15:8] &&
            dataReg[3] == new_number[7:0]) begin
            $display("BLOCKING I2C RECEIVE/TRANSMIT TEST PASS.");
`ifdef LOG_OUTPUT
            $fwrite(fd, "[SUCCESS]: blocking rx/tx test passed\n");
`endif
        end else begin
            $display("BLOCKING I2C RECEIVE/TRANSMIT TEST FAILED.");
`ifdef LOG_OUTPUT
            $fwrite(fd, "[   FAIL]: blocking rx/tx test failed\n");
            flg_test_succ = 0;
`endif
        end
        
        new_number = dataReg[130] * dataReg[131];
        $display( "Expected values: 0x%0h 0x%0h 0x%0h 0x%0h", dataReg[130], dataReg[131], new_number[15:8], new_number[7:0]);
        $display( "Received values: 0x%0h 0x%0h 0x%0h 0x%0h", dataReg[4], dataReg[5], dataReg[6], dataReg[7]);
        if (dataReg[4] == dataReg[130] && 
            dataReg[5] == dataReg[131] &&
            dataReg[6] == new_number[15:8] &&
            dataReg[7] == new_number[7:0]) begin
            $display("NON-BLOCKING I2C RECEIVE/TRANSMIT TEST PASS.");
`ifdef LOG_OUTPUT
            $fwrite(fd, "[SUCCESS]: non-blocking rx/tx test passed\n");
`endif
        end else begin
            $display("NON-BLOCKING I2C RECEIVE/TRANSMIT TEST FAILED.");
`ifdef LOG_OUTPUT
            $fwrite(fd, "[   FAIL]: non-blocking rx/tx test failed\n");
            flg_test_succ = 0;
`endif
        end

`ifdef LOG_OUTPUT
        if (flg_test_succ) begin
            $fwrite(fd, "[   FLAG]: TEST_SUCCESS\n");
        end else begin
             $fwrite(fd, "[   FLAG]: TEST_FAIL\n");
        end
        $fclose(fd);
`endif
        
        $finish();
    end

`ifdef SDF
    // SDF annotate for post pnr
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",simple_system_tb.dut,,"sdf.log","MAXIMUM");
    end
`endif
endmodule
