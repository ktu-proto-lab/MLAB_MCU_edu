module wb_uart(
	wb_if.slave wb,

    input   logic       i_cts_n,
    output  logic       o_rts_n,

    output  logic       o_uart_rx_int,
    output  logic       o_uart_tx_int,
    output  logic       o_uart_rxfifo_int,
    output  logic       o_uart_txfifo_int,

    input   logic       i_uart_rx,
    output  logic       o_uart_tx
    );

	// {{{
	// 4MB 8N1, when using 100MHz clock
	parameter [30:0] INITIAL_SETUP = 31'd25;
	parameter [3:0]	LGFLEN = 4;
	parameter [0:0]	HARDWARE_FLOW_CONTROL_PRESENT = 1'b0;

	assign wb.err	= 1'b0;

    reg uart_rx_line_enable;

    logic stb_to_uart_core, ack_from_uart_core;

    assign stb_to_uart_core  = (wb.adr[4]) ? 1'b0 : wb.stb;

    assign wb.ack = (wb.adr[4]) ? 1'b1 : ack_from_uart_core;

    wbuart #(

        .INITIAL_SETUP(INITIAL_SETUP),
        .LGFLEN(LGFLEN),
        .HARDWARE_FLOW_CONTROL_PRESENT(HARDWARE_FLOW_CONTROL_PRESENT)

    ) u_wb_uart (

        .i_clk              (wb.clk),
        .i_reset            (wb.rst),
        .i_wb_cyc           (wb.cyc),
        .i_wb_stb           (stb_to_uart_core),
        .i_wb_we            (wb.we),
        .i_wb_addr          (wb.adr[3:2]),
        .i_wb_sel           (wb.sel),
        .o_wb_stall         (wb.stall),
        .o_wb_ack           (ack_from_uart_core),

    `ifdef NO_MODPORT_EXPRESSIONS
        .i_wb_data          (wb.dat_m),
        .o_wb_data          (wb.dat_s),
    `else
        .i_wb_data          (wb.dat_i),
        .o_wb_data          (wb.dat_o),
    `endif

        .i_uart_rx          ( uart_rx_line_enable ? i_uart_rx : 1'b0 ),
        .o_uart_tx          (o_uart_tx),
        .i_cts_n            (i_cts_n),
        .o_rts_n            (o_rts_n),
        .o_uart_rx_int      (o_uart_rx_int),
        .o_uart_tx_int      (o_uart_tx_int),
        .o_uart_rxfifo_int  (o_uart_rxfifo_int),
        .o_uart_txfifo_int  (o_uart_txfifo_int)

    );


    always @(posedge wb.clk)
      if (wb.rst)
        begin
            uart_rx_line_enable <= 1'b0;
        end
    else if (wb.adr[4:2] == 3'b100 && wb.stb)
        begin
    `ifdef NO_MODPORT_EXPRESSIONS
            uart_rx_line_enable <= wb.dat_m[0];
    `else
            uart_rx_line_enable <= wb.dat_i[0];
    `endif
        end

endmodule
