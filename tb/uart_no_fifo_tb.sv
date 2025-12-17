`include "project_defs.svh"
`include "../../tb/misc/tb.v"
`include "../../tb/misc/UART_RX.sv"
`include "../../tb/misc/UART_TX.sv"

parameter program_folder="test/uart_no_fifo";


module simple_system_tb;
    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 12.5;  
    parameter MEMInitFile = {"../../sw/ibex/",program_folder,"/build/verilog_hex.v"};

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
    logic [7:0] byte_to_send;
    logic TX_Active;
    logic TX_DV = 0;
    
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

    logic       w_RX_DV     ;
    logic [7:0] w_RX_Byte   ;

    assign RX_Serial = out_valid[0] ? ext_pad_io[1] : 1;
    
    UART_TX #(.CLKS_PER_BIT(clocks_per_baud)) UART_TX_Inst
      (.i_Rst_L(1'b1),
       .i_Clock(clk_sys),
       .i_TX_DV(TX_DV),
       .i_TX_Byte(byte_to_send),
       .o_TX_Active(TX_Active),
       .o_TX_Serial(output_value[0]),
       .o_TX_Done()
       );
       
    
    UART_RX #(.CLKS_PER_BIT(clocks_per_baud)) UART_RX_Inst
      (.i_Clock(clk_sys),
       .i_RX_Serial(RX_Serial),
       .o_RX_DV(w_RX_DV),
       .o_RX_Byte(w_RX_Byte)
       );

    always @(posedge w_RX_DV) begin
         $write("%s",w_RX_Byte);
    end

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

        #10_000
        // Set GPIO0 (UART RX)
        out_valid[0] = 1;
        #1_000
//      out_valid =  0; 
                
        tb.memory_write_back_test;

        // Time for timer test program to end
        #15_000_000

        // data_to_send = "6";
        send_uart_string("6",1);
        // send_uart_byte(data_to_send);
        #5_000_000
        // data_to_send = "7";
        send_uart_string("7",1);
        // send_uart_byte(data_to_send);
        #5_000_025
        // data_to_send = "-";
        send_uart_string("-",1);
        // send_uart_byte(data_to_send);
        #4_000_000

    //==================================================
    // Simulated External Event
    //==================================================

    send_uart_string({"Briedis",8'd10},8);
    

    
	#1_000

    #1_000_000
    #5_000_000
    $finish();
    // $stop();
end

task send_uart_string (input string text, input [7:0] len);
    begin
        for (int i = 0; i < len; i++) begin
            byte_to_send = text[i];
            TX_DV = 1;
            #100;
            TX_DV=0;
            wait (TX_Active == 0);
        end
    end
endtask

    

`ifdef SDF
    // SDF annotate for post pnr
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",simple_system_tb.dut,,"sdf.log","MAXIMUM");
    end
`endif
endmodule
