`include "project_defs.svh"
`include "boot_defs.svh"
`include "../../tb/misc/tb.v"



module simple_system_tb;
    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 12.5;  
    parameter MEMInitFile = {"../../tb/misc/mem_test_hex.v"};

    logic clk_sys, rst_sys_n, test_mode;
    assign test_mode = 1'b0;
 
    // GPIO signals
    wire [GPIO_COUNT-1:0] ext_pad_io;

    // Testbench driven GPIO control
    logic [GPIO_COUNT-1:0] input_val;
    logic [GPIO_COUNT-1:0] output_value;
    logic [GPIO_COUNT-1:0] out_valid;

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
        .test_mode_Pad  (test_mode)
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
        // Add delay to let scan_en propagate, this is so we don't get $setup timing violations for postpnr 
        // SDF annotated simulation
        #(CLK_PERIOD*1)

        // Initial top signal values
        rst_sys_n = 1'b1;
        #(CLK_PERIOD*4)
        rst_sys_n = 1'b0;
        // SPI_CS_n = 1'b1;
        // r_Master_TX_DV = 1'b0;
        clk_sys = 1'b0;
        // output_value = 'h0;
        out_valid = 0;

        #(CLK_PERIOD*4)
        rst_sys_n = 1'b1;
        
        tb.wait_bootloader;
        tb.memory_write_back_test;
        
        $display("Test is passed");
    $finish();
    $stop();
end

    

`ifdef SDF
    // SDF annotate for post pnr
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",simple_system_tb.dut,,"sdf.log","MAXIMUM");
    end
`endif
endmodule
