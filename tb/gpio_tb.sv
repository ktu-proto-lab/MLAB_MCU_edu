`include "project_defs.svh"
`include "../../tb/misc/tb.v"
parameter program_folder="test/gpio";

module simple_system_tb;
    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 12.5;
    parameter MEMInitFile = {"../../sw/ibex/",program_folder,"/build/verilog_hex.v"};
`ifdef LOG_OUTPUT
    // Output file of the tb info.
    parameter file="../../tb/log/gpio.log";
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

`ifdef DUMPVCD
    initial begin
        $dumpfile("output.vcd");
        $dumpvars(0,simple_system_tb);
    end
`endif 
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
        rst_sys_n = 1'b0;
        clk_sys = 1'b0;
        out_valid = 0;

        #(CLK_PERIOD*4)
        rst_sys_n = 1'b1;


        tb.wait_bootloader;
        tb.memory_write_back_test;
        
        // Wait for startup code to finish and for main to jump into while(1)
        #1_000_000;
        
        // Set GPIO6 (start the sw state machine)
        out_valid = 1;
        output_value = 1 << 6;
        #100; 
        
        // Reset GPIO6
        out_valid =  0; 

        // Wait for state machine to complete
        #100_000;

`ifdef LOG_OUTPUT
        $fclose(fd);
`endif
        $finish();
    end

//-------------------------------------
// Automatic test sequence
//-------------------------------------

// expected sequence for shift_right
logic [5:0] expected_seq [0:4] = '{6'h02, 6'h04, 6'h08, 6'h10, 6'h20};

int idx = 0;

always @(ext_pad_io[5:0]) begin
  if (idx < $size(expected_seq)) begin
    if (ext_pad_io[5:0] === expected_seq[idx]) begin
      $display("[%0t] Got expected value %h", $time, ext_pad_io[5:0]);
`ifdef LOG_OUTPUT
        $fwrite(fd, "[SUCCESS]: expected value = %h, actual = %h (%0t)\n", expected_seq[idx], ext_pad_io[5:0], $time);
`endif
      idx++;
      if (idx == $size(expected_seq)) begin
        $display("[%0t] Sequence complete!", $time);
`ifdef LOG_OUTPUT
        $fwrite(fd, "[SUCCESS]: sequence completed (%0t)\n", $time);
        $fwrite(fd, "[   FLAG]: TEST_SUCCESS\n");
`endif
      end
    end else if (ext_pad_io[5:0] != 0) begin
        $error("[%0t] Unexpected value on GPIOs: %h (expected %h)",
             $time, ext_pad_io[5:0], expected_seq[idx]);
`ifdef LOG_OUTPUT
        $fwrite(fd, "[   FAIL]: unexpected value on GPIOs: expected: %h, actual: %h (%0t)\n",
            expected_seq[idx], ext_pad_io[5:0], $time);
`endif
    end
  end
end

`ifdef SDF
    // SDF annotate (Add real delays) for post pnr sim
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",simple_system_tb.dut,,"sdf.log","MAXIMUM");
    end
`endif

endmodule
