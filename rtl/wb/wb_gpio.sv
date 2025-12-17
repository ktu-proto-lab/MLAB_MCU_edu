/* Wrapper to connect standalone wb signals to interface defined in wb_if.sv */

// CONFIGURATION (in gpio_defines.v):
// STRICT 32bit access
// Module decodes only relevant bits
// IO outputs and WB outputs are NOT registered
// External clock is disabled
// 16 GPIOs

module wb_gpio(
    wb_if.slave wb,
    output  logic               int_o,
    input   logic   [`GPIO_IOS-1:0]    aux_i,
    input   logic   [`GPIO_IOS-1:0]    ext_pad_i,    
    output  logic   [`GPIO_IOS-1:0]    ext_pad_o,    
    output  logic   [`GPIO_IOS-1:0]    ext_padoe_o    
);


assign wb.stall = 1'b0;

gpio_top u_wb_gpio (
    .wb_clk_i      (wb.clk),
    .wb_rst_i_n    (wb.rst),
    .wb_cyc_i      (wb.cyc),
    .wb_adr_i      (wb.adr[(`GPIO_ADDRHH+1)-1:0]), // Connect only the relevant LSB to the GPIO module
`ifdef NO_MODPORT_EXPRESSIONS
    .wb_dat_i      (wb.dat_m),
    .wb_dat_o      (wb.dat_s),
`else
    .wb_dat_i      (wb.dat_i),
    .wb_dat_o      (wb.dat_o),
`endif
    .wb_sel_i      (wb.sel),
    .wb_we_i       (wb.we),
    .wb_stb_i      (wb.stb),
    .wb_ack_o      (wb.ack),
    .wb_err_o      (wb.err),

    .wb_inta_o     (int_o),

    .aux_i          (aux_i),

    .ext_pad_i      (ext_pad_i),
    .ext_pad_o      (ext_pad_o), 
    .ext_padoe_o    (ext_padoe_o)
);

endmodule
