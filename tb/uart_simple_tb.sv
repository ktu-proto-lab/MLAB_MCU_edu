`include "project_defs.svh"
`include "../../tb/misc/tb.v"
`include "../../tb/misc/UART_RX.sv"
`include "../../tb/misc/UART_TX.sv"


parameter program_folder="test/uart_simple";


module simple_system_tb;
    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 20;
    parameter MEMInitFile = {"../../sw/ibex/",program_folder,"/build/verilog_hex.v"};

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

    //==================================================
    // DUT
    //==================================================
    ibex_simple_system dut (
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
    // DUT reads pads
    assign ext_pad_i  = ext_pad_io;

    // TB drives pads + pulldown
    genvar j;
    generate
        for (j = 0; j < GPIO_COUNT; j++) begin : TB_GPIO
        // DUT drives pads
        assign ext_pad_io[j] = gpio_oe[j] ? gpio_o[j] : 1'bz;
        assign ext_pad_io[j] =
            out_valid[j] ? output_value[j] : 1'bz;
        pulldown(ext_pad_io[j]);
        end
    endgenerate

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
    // Clock generation
    //==================================================
    always begin
        #(CLK_PERIOD / 2) clk_sys = ~clk_sys;
    end

    //==================================================
    // UART
    //==================================================
    // UART clocks_per_baud
    parameter [23:0] clocks_per_baud = 694;

    // UART data_to_send
    logic [7:0] byte_to_send;
    logic TX_Active;
    logic TX_DV = 0;

    logic       w_RX_DV;
    logic [7:0] w_RX_Byte;

    // Multiplexer for UART RX (controled by TX valid signal)
    assign RX_Serial = out_valid[0] ? ext_pad_io[1] : 0;
    
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

    initial begin
        // Initial top signal values
        clk_sys = 1'b0;
        out_valid = 0;
        rst_sys_n = 1'b0;

        // De-assert reset after 4 clk cycles
        #(CLK_PERIOD*4)
        rst_sys_n = 1'b1;

        // Set GPIO0 to output for UART TX
        out_valid[0] = 1;

        #125_000_000; // Bootloader working
        
        #1_000_000;

        send_uart_string("6",1);
        #5_000_000
        send_uart_string("7",1);
        #5_000_000
        send_uart_string("-",1);
        #4_000_000
        
        send_uart_string("9",1);
        #5_000_000
        send_uart_string("5",1);
        #5_000_000
        send_uart_string("+",1);
        #4_000_000

        // Wait for state machine to complete
        #100_000;

        $finish();
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
    // SDF annotate (Add real delays) for post pnr sim
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",simple_system_tb.dut,,"sdf.log","MAXIMUM");
    end
`endif

endmodule
