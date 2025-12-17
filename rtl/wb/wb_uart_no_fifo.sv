module wb_uart(
	wb_if.slave wb,

    output  logic       o_uart_rx_int,
    output  logic       o_uart_tx_int,

    input   logic       i_uart_rx,
    output  logic       o_uart_tx
    );

	// {{{
	// 4MB 8N1, when using 100MHz clock
	parameter [31:0] INITIAL_SETUP = 31'd868;

	assign wb.err	= 1'b0;

    wbuart #(

        .INITIAL_SETUP(INITIAL_SETUP)

    ) u_wb_uart (

        .i_clk              (wb.clk),
        .i_reset_n          (wb.rst),
        .i_wb_cyc           (wb.cyc),
        .i_wb_stb           (wb.stb),
        .i_wb_we            (wb.we),
        .i_wb_addr          (wb.adr[3:2]),
        .i_wb_sel           (wb.sel),
        .o_wb_stall         (wb.stall),
        .o_wb_ack           (wb.ack),

    `ifdef NO_MODPORT_EXPRESSIONS
        .i_wb_data          (wb.dat_m),
        .o_wb_data          (wb.dat_s),
    `else
        .i_wb_data          (wb.dat_i),
        .o_wb_data          (wb.dat_o),
    `endif

        .i_uart_rx          (i_uart_rx),
        .o_uart_tx          (o_uart_tx),
        .o_uart_rx_int      (o_uart_rx_int),
        .o_uart_tx_int      (o_uart_tx_int)

    );

endmodule
