module wb_spi_flash (
    wb_if.slave wb,
    output logic o_qspi_sck,
    output logic o_qspi_cs_n,
    output logic [1:0] o_qspi_mod,
    output logic [3:0] o_qspi_dat,
    input logic [3:0] i_qspi_dat
);
    assign wb.err	= 1'b0;
    // qflexpress outputs stall whenever it is busy, no matter, that master is not starting transaction (for exaple during startup sequence)
    // This stalls whole bus, and master also.
    // To fix this, multiplex wb. stall signal, so it only be true, then cycle and strobe is true (master starting transaction)
    logic stall;
    // assign wb.stall	= ((stall & wb.cyc) & wb.stb);
    assign wb.stall	= (wb.cyc & wb.stb) ? stall : 1'b0;

    qflexpress #(
        .LGFLASHSZ(24),
        .OPT_STARTUP(1)
	) u_wb_spi_flash (
        .i_clk          (wb.clk),
        .i_reset        (~wb.rst),
        .i_wb_cyc       (wb.cyc),
        .i_wb_stb       (wb.stb),
        .i_cfg_stb      (1'b0),
        .i_wb_we        (wb.we),
        .i_wb_addr      (wb.adr[21:0]),
        .o_wb_stall     (stall),
        .o_wb_ack       (wb.ack),

    `ifdef NO_MODPORT_EXPRESSIONS
        .i_wb_data          (wb.dat_m),
        .o_wb_data          (wb.dat_s),
    `else
        .i_wb_data          (wb.dat_i),
        .o_wb_data          (wb.dat_o),
    `endif

        .o_qspi_sck     (o_qspi_sck),
        .o_qspi_cs_n    (o_qspi_cs_n),
        .o_qspi_mod     (o_qspi_mod),
        .o_qspi_dat     (o_qspi_dat),
        .i_qspi_dat     (i_qspi_dat)
	);

endmodule
