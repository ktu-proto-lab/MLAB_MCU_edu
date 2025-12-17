`include "project_defs.svh"
`include "../../tb/misc/tb.v"
`include "../../tb/misc/UART_RX.sv"


module simple_system_tb;
    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 12.5;  
    parameter MEMInitFile = "../../sw/ibex/verilog_hex.v";

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

    logic       w_RX_DV     ;
    logic [7:0] w_RX_Byte   ;
    UART_RX #(.CLKS_PER_BIT(clocks_per_baud)) UART_RX_Inst
      (.i_Clock(clk_sys),
       .i_RX_Serial(output_value[0] ? ext_pad_io[1] : 1),
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

        
        // Set GPIO0 (UART RX)
        out_valid[0] = 1;
        output_value[0] = 1;
        #1_000
//      out_valid =  0; 
        
        // Time for timer test program to end
        #10_000_000

    //==================================================
    // Simulated External Event
    //==================================================

	data_to_send = 66;		// B
    send_uart_byte(data_to_send);
	#1_000

	data_to_send = 114;		// r
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 105;		// i
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 101;		// e
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 100;		// d
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 105;		// i
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 115;		// s
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 116;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 117;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 118;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 119;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 120;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 121;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 122;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 123;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 124;
	send_uart_byte(data_to_send);
	#1_000

	data_to_send = 125;
	send_uart_byte(data_to_send);
	#1_000



/*
        // Set GPIO0
        out_valid = 1;
	33a9774 (feat(tb): add uart_rx for testing)
        output_value = 1 << 6;
        #100; 
        
        // Reset GPIO6
        out_valid =  0; 
        #2000;
*/

        $stop();
    end


    

    // Send UART frame: Start bit (0), 8 data bits LSB first, Stop bit (1)
    // Task to send a UART byte serially
    task send_uart_byte(input [7:0] send_byte);
        integer bit_i;
        begin
            // Start bit (0)
            drive_rx_bit(0);

            // Data bits LSB first
            for(bit_i = 0; bit_i < 8; bit_i = bit_i + 1) begin
                drive_rx_bit(send_byte[bit_i]);
            end

            // Stop bit (1)
            drive_rx_bit(1);
        end
    endtask

    // Task to drive rx line for one UART bit period
    task drive_rx_bit(input bit_value);
        integer tick_count;
        begin
            output_value = bit_value;
            // Hold rx stable for clocks_per_baud
            for(tick_count = 0; tick_count < clocks_per_baud; tick_count = tick_count + 1) begin
                @(posedge clk_sys);
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
