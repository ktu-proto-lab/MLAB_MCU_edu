/* Wrapper to connect standalone wb signals to interface defined in wb_if.sv */

// CONFIGURATION (in gpio_defines.v):
// STRICT 32bit access
// Module decodes only relevant bits
// IO outputs and WB outputs are NOT registered
// External clock is disabled
// 16 GPIOs


module wb_i2c(
    wb_if.slave wb,

    output  logic       int_o,

    input   logic       scl_pad_i,
    output  logic       scl_pad_o,
    output  logic       scl_padoen_o,    
    input   logic       sda_pad_i,    
    output  logic       sda_pad_o,
    output  logic       sda_padoen_o     
);
    parameter BOOT_I2C_PRESCALER = 16'd15; // I2C freq = clk_sys/80

    logic   [7:0]   wb_dat_o_8; 

    assign wb.stall = 1'b0;
    assign wb.err   = 1'b0;

    `ifdef NO_MODPORT_EXPRESSIONS
    assign wb.dat_s = {{24{1'b0}}, wb_dat_o_8}; // Connect 8bit from I2C to 32 bit of bus
    `else
    assign wb.dat_o = {{24{1'b0}}, wb_dat_o_8}; // Connect 8bit from I2C to 32 bit of bus
    `endif

    logic   [29:0]   wb_adr_8;

    assign wb_adr_8 = wb.adr >> 2;

    i2c_master_top #(
            .BOOT_I2C_PRESCALER(BOOT_I2C_PRESCALER)
        ) u_wb_i2c (
        .wb_clk_i      (wb.clk),
        .wb_adr_i      (wb_adr_8[2:0]),
    `ifdef NO_MODPORT_EXPRESSIONS
        .wb_dat_i      (wb.dat_m[7:0]),
    `else
        .wb_dat_i      (wb.dat_i[7:0]),
    `endif
        .wb_dat_o      (wb_dat_o_8),
        .wb_we_i       (wb.we),
        .wb_stb_i      (wb.stb),
        .wb_cyc_i      (wb.cyc),
        .wb_ack_o      (wb.ack),
        .wb_inta_o     (int_o),

        .arst_i        (wb.rst),
        .scl_pad_i     (scl_pad_i),
        .scl_pad_o     (scl_pad_o),
        .scl_padoen_o  (scl_padoen_o),
        .sda_pad_i     (sda_pad_i),
        .sda_pad_o     (sda_pad_o),
        .sda_padoen_o  (sda_padoen_o)
    );



endmodule
