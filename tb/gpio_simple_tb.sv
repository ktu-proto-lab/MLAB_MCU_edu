`include "project_defs.svh"
`include "../../tb/misc/tb.v"


parameter program_folder="test/gpio_simple";


module simple_system_tb;
    // Parameters
    parameter GPIO_COUNT = `GPIO_IOS;
    parameter CLK_PERIOD = 12.5;
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

        #125_000_000; // Bootloader working
        
        #1_000_000;// Wait for startup code to finish and for main to jump into while(1)

        // Set GPIO3 (set off the interrupt)
        out_valid     = 1 << 3;
        output_value = 1 << 3;
        
        // Reset GPIO
        #(CLK_PERIOD*2)
        out_valid =  0; 

        // Wait for state machine to complete
        #100_000;
	$display("[   INFO]: GPIO pin values %010b", ext_pad_io);
        $finish();
    end

`ifdef SDF
    // SDF annotate (Add real delays) for post pnr sim
    initial begin
        $sdf_annotate("../../pnr/pnrOutData/simple_system.sdf",simple_system_tb.dut,,"sdf.log","MAXIMUM");
    end
`endif

endmodule
