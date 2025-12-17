`ifdef UART_NO_FIFO

`include "../../rtl/peripherals/wbuart_no_fifo.v"
`include "../../rtl/peripherals/rxuart.v"
`include "../../rtl/peripherals/txuart.v"
`include "../../rtl/wb/wb_uart_no_fifo.sv"

`else
`include "../../rtl/peripherals/wbuart.v"
`include "../../rtl/peripherals/rxuart.v"
`include "../../rtl/peripherals/txuart.v"
`include "../../rtl/peripherals/ufifo.v"
`include "../../rtl/wb/wb_uart.sv"
`endif
