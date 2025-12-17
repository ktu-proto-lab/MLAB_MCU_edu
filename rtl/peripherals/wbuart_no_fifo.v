////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	wbuart.v
// {{{
// Project:	wbuart32, a full featured UART with simulator
//
// Purpose:	Unlilke wbuart-insert.v, this is a full blown wishbone core
//		with integrated FIFO support to support the UART transmitter
//	and receiver found within here.  As a result, it's usage may be
//	heavier on the bus than the insert, but it may also be more useful.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2015-2024, Gisselquist Technology, LLC
// {{{
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	GPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
//`default_nettype	none
// }}}
// `define	USE_LITE_UART
module	wbuart #(
		// {{{
		// 4MB 8N1, when using 100MHz clock
		parameter [29:0] INITIAL_SETUP = 31'd868
	) (
		// {{{
		input	wire		i_clk, i_reset_n,
		// Wishbone inputs
		input	wire		i_wb_cyc,
		input	wire		i_wb_stb, i_wb_we,
		input	wire [1:0]	i_wb_addr,
		input	wire [31:0]	i_wb_data,
		input	wire [3:0]	i_wb_sel,
		output	wire		o_wb_stall,
		output	reg		    o_wb_ack,
		output	reg	 [31:0]	o_wb_data,
		//
		input	wire		i_uart_rx,
		output	wire		o_uart_tx,
		output	wire		o_uart_rx_int, o_uart_tx_int
		// }}}
	);

	localparam 	[1:0]   UART_SETUP = 2'b00,
                UART_CRREG = 2'b01,
                UART_RXREG = 2'b10,
                UART_TXREG = 2'b11;


	// Register and signal declarations
	// {{{
	wire	    tx_busy;
    reg         tx_busy_d;
	reg	[29:0]	uart_setup;
    wire [5:0]  cr_reg;
    reg         uart_tx_en, uart_rx_en;
	// Receiver
	wire		rx_stb, rx_break, rx_perr, rx_ferr, ck_uart;
	wire [7:0]	rx_uart_data;
	reg	    	rx_uart_reset;
	reg 		rx_empty, rx_empty_d;
	//
	reg			r_rx_perr;
    reg         r_rx_overflow;
    wire        w_uart_rx;
    wire [13:0] rx_reg;
	// The transmitter
	wire	    tx_break;
	wire [7:0]	tx_data;
    reg  [7:0]  r_tx_data;
	reg	        tx_uart_reset;
    wire        w_uart_tx;
	reg	        tx_empty_n;
    wire [11:0] tx_reg;
	//
    reg         tx_int_en, rx_int_en;
	reg  [1:0]  r_wb_addr;
	reg         r_wb_ack;
	// }}}

	// uart_setup
	// {{{
	// The UART setup parameters: bits per byte, stop bits, parity, and
	// baud rate are all captured within this uart_setup register.
	//

    // ~~~~~~~~~~~~~~~~~~ disable tx/rx lines on reset ~~~~~~~~~~~~~~~~~~~~~

    // always @(posedge i_clk) begin
    //     if(i_reset) begin
    //         uart_setup[30] <= 1'b0;
    //         uart_setup[31] <= 1'b0;
    //     end
    // end

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // w_uart_tx is the tx line coming from txuart module, as long as
    // uart_tx_en is low that line doesn't get connected to this modules
    // o_uart_tx hence forth this signal doesn't reach the physical io pad.
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // TX disabling probably wont be needed.
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    assign  o_uart_tx = ((uart_tx_en)? w_uart_tx : 1'bz);

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // i_uart_rx comes from the physical io pad but as long as uart_rx_en
    // is low it doesn't get connected to w_uart_rx which goes to the rxuart
    // module.
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    assign  w_uart_rx = ((uart_rx_en)? i_uart_rx : 1'b1);

	always @(posedge i_clk or negedge i_reset_n)
	// Under wishbone rules, a write takes place any time i_wb_stb
	// is high.  If that's the case, and if the write was to the
	// setup address, then set us up for the new parameters.
	if (!i_reset_n)
		uart_setup <= INITIAL_SETUP;
	else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_SETUP)&&(i_wb_we))
	begin
		if (i_wb_sel[0])
			uart_setup[7:0] <= i_wb_data[7:0];
		if (i_wb_sel[1])
			uart_setup[15:8] <= i_wb_data[15:8];
		if (i_wb_sel[2])
			uart_setup[23:16] <= i_wb_data[23:16];
		if (i_wb_sel[3])
			uart_setup[29:24] <= i_wb_data[29:24];
	end

    always @(posedge i_clk or negedge i_reset_n) begin
        if(!i_reset_n)
            uart_rx_en <= 1'b0;
        else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_CRREG)&&(i_wb_we)&&(i_wb_sel[0]))
            uart_rx_en <= i_wb_data[0];
    end

    always @(posedge i_clk or negedge i_reset_n) begin
        if(!i_reset_n)
            uart_tx_en <= 1'b0;
        else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_CRREG)&&(i_wb_we)&&(i_wb_sel[0]))
            uart_tx_en <= i_wb_data[3];
    end

    assign cr_reg = { tx_uart_reset, tx_int_en, uart_tx_en, rx_uart_reset,
                rx_int_en, uart_rx_en };

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// The UART receiver
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// The receiver itself
	// {{{
	// Here's our UART receiver.  Basically, it accepts our setup wires, 
	// the UART input, a clock, and a reset line, and produces outputs:
	// a stb (true when new data is ready), and an 8-bit data out value
	// valid when stb is high.
`ifdef	USE_LITE_UART
	// {{{
	rxuartlite	#(.CLOCKS_PER_BAUD(INITIAL_SETUP[23:0]))
		rx(i_clk, w_uart_rx, rx_stb, rx_uart_data);
	assign	rx_break = 1'b0;
	assign	rx_perr  = 1'b0;
	assign	rx_ferr  = 1'b0;
	assign	ck_uart  = 1'b0;
	// }}}
`else
	// {{{
	// The full receiver also produces a break value (true during a break
	// cond.), and parity/framing error flags--also valid when stb is true.
	rxuart	#(.INITIAL_SETUP(INITIAL_SETUP)) rx(i_clk, (i_reset_n)&&(~rx_uart_reset),
			{1'b0,uart_setup}, w_uart_rx,
			rx_stb, rx_uart_data, rx_break,
			rx_perr, rx_ferr, ck_uart);
	// The real trick is ... now that we have this extra data, what do we do
	// with it?
	// }}}
`endif
	// }}}


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //      NEEDS TO BE TESTED --- refer to wbuart_insert.v line 88.


    always @(posedge i_clk or negedge i_reset_n) begin
        if(!i_reset_n)
            rx_int_en <= 1'b0;
        else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_CRREG)&&(i_wb_we)&&(i_wb_sel[0]))
            rx_int_en <= i_wb_data[1];
    end

    // A flag is raised when rx has overflowed and is cleared on next rx_reg
    // read

    always @(posedge i_clk or negedge i_reset_n) begin
        if(!i_reset_n) begin
            rx_empty <= 1'b0;
            rx_empty_d <= 1'b0;
            r_rx_overflow <= 1'b0;
		end else if(rx_stb && (!rx_empty_d)) begin
            rx_empty_d <= 1'b1;
        end else if(rx_stb && (rx_empty_d)) begin
            r_rx_overflow <= 1'b0;
        end
        else if(rx_empty && !r_wb_ack && (r_wb_addr[1:0] == UART_RXREG)) begin
            rx_empty <= 1'b0;
            rx_empty_d <= 1'b0;
			r_rx_overflow <= 1'b0;
		end
		else if (!rx_empty && i_wb_stb && (i_wb_addr[1:0] == UART_RXREG)) begin
			rx_empty <= rx_empty_d;
	    end
    end

	assign	o_uart_rx_int = rx_int_en ? rx_empty_d : 1'b0;

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	// r_rx_perr -- parity and framing errors
	// {{{
	// Now, let's deal with those RX UART errors: both the parity and frame
	// errors.  As you may recall, these are valid only when rx_stb is
	// valid, so we need to hold on to them until the user reads them via
	// a UART read request..

	always @(posedge i_clk)
	if ((rx_uart_reset)||(rx_break))
	begin
		// Clear the error
		r_rx_perr <= 1'b0;
	end else if ((i_wb_stb)
			&&(i_wb_addr[1:0] == UART_RXREG)&&(i_wb_we))
	begin
		// Reset the error lines if a '1' is ever written to
		// them, otherwise leave them alone.
		//
		if (i_wb_sel[1])
		begin
			r_rx_perr <= (r_rx_perr)&&(~i_wb_data[9]);
		end
	end else if (rx_stb)
	begin
		// On an rx_stb, capture any parity or framing error
		// indications.  These aren't kept with the data rcvd,
		// but rather kept external to the FIFO.  As a result,
		// if you get a parity or framing error, you will never
		// know which data byte it was associated with.
		// For now ... that'll work.
		r_rx_perr <= (r_rx_perr)||(rx_perr);
	end
	// }}}

	// rx_uart_reset
	// {{{
	always @(posedge i_clk or negedge i_reset_n)
	if (!i_reset_n)
		rx_uart_reset <= 1'b1;
	else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_SETUP)&&(i_wb_we))
		// The receiver reset, always set on a master reset
		// request.
		rx_uart_reset <= 1'b1;
	else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_CRREG)&&(i_wb_we)&&i_wb_sel[0])
		// Writes to the control register will command a receive
		// reset anytime bit[1] is set.
		rx_uart_reset <= i_wb_data[2]; 
	else
		rx_uart_reset <= 1'b0;

    // rx_reg
	// {{{
	// Finally, we'll construct a 32-bit value from these various wires,
	// to be returned over the bus on any read.  These include the data
	// that would be read from the FIFO, an error indicator set upon
	// reading from an empty FIFO, a break indicator, and the frame and
	// parity error signals.
	assign	rx_reg = { ck_uart, rx_break, r_rx_overflow, rx_ferr, r_rx_perr,
                rx_empty, rx_uart_data};
	// }}}
    //
	////////////////////////////////////////////////////////////////////////
	//
	// The UART transmitter
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//


	// Break logic
`ifndef	USE_LITE_UART
	// {{{
	// A break in a UART controller is any time the UART holds the line
	// low for an extended period of time.  Here, we capture the wb_data[9]
	// wire, on writes, as an indication we wish to break.  As long as you
	// write unsigned characters to the interface, this will never be true
	// unless you wish it to be true.  Be aware, though, writing a valid
	// value to the interface will bring it out of the break condition.
	reg	r_tx_break;
	always @(posedge i_clk or negedge i_reset_n)
	if (!i_reset_n)
		r_tx_break <= 1'b0;
	else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_TXREG)&&(i_wb_we)
		&&(i_wb_sel[1]))
		r_tx_break <= i_wb_data[10];

	assign	tx_break = r_tx_break;
	// }}}
`else
	// {{{
	assign	tx_break = 1'b0;
	// }}}
`endif

	// TX-Reset logic
	// {{{
	// This is nearly identical to the RX reset logic above.  Basically,
	// any time someone writes to bit [28] the transmitter will go through
	// a reset cycle.  Keep bit [28] low, and everything will proceed as
	// normal.
	always @(posedge i_clk or negedge i_reset_n)
	if(!i_reset_n)
		tx_uart_reset <= 1'b1;
	else if ((i_wb_stb)&&(i_wb_addr[1:0] ==  UART_SETUP)&&(i_wb_we))
		tx_uart_reset <= 1'b1;
	else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_CRREG)&&(i_wb_we) && i_wb_sel[0])
		tx_uart_reset <= i_wb_data[5];
	else
		tx_uart_reset <= 1'b0;
	// }}}

	// The actuall transmitter itself
`ifdef	USE_LITE_UART
	// {{{
	txuartlite #(.CLOCKS_PER_BAUD(INITIAL_SETUP[23:0])) tx(i_clk, (tx_empty_n), tx_data,
			w_uart_tx, tx_busy);
	// }}}
`else

	// The *full* transmitter impleemntation
	// {{{
	// Finally, the UART transmitter module itself.  Note that we haven't
	// connected the reset wire.  Transmitting is as simple as setting
	// the stb value (here set to tx_empty_n) and the data.  When these
	// are both set on the same clock that tx_busy is low, the transmitter
	// will move on to the next data byte.  Really, the only thing magical
	// here is that tx_empty_n wire--thus, if there's anything in the FIFO,
	// we read it here.  (You might notice above, we register a read any
	// time (tx_empty_n) and (!tx_busy) are both true---the condition for
	// starting to transmit a new byte.)
	txuart	#(.INITIAL_SETUP(INITIAL_SETUP)) tx(i_clk, i_reset_n, {1'b0,uart_setup},
			r_tx_break, (tx_empty_n), tx_data,
			1'b0, w_uart_tx, tx_busy);
	// }}}
`endif

	// Transmit interrupts
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // NEEDS TO BE TESTED --- refer to wbuart_insert.v line 127.
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    always @(posedge i_clk or negedge i_reset_n) begin
        if(!i_reset_n)
            tx_int_en <= 1'b0;
        else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_CRREG)&&(i_wb_we)&&(i_wb_sel[0]))
            tx_int_en <= i_wb_data[4];
    end

	assign	o_uart_tx_int = ((tx_int_en)? ~tx_busy : 1'b0);

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // NEEDS TO BE TESTED --- FIFO nolonger exists so data is saved in reg.
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    always @(posedge i_clk) begin
        tx_busy_d <= tx_busy;

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // clears tx_empty_n after passing r_tx_data to txuart module for
        // transmission indicating that another write is allowed to r_tx_data
        // from core.
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // if (!tx_busy_d && tx_busy) begin
        //     tx_empty_n <= 1'b0;
        // end
    end

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // When a write happens to tx_byte read data from wishbone
    // and store it in r_tx_data, raise tx_empty_n indicating data is ready
    // for transmission
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    always @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            tx_empty_n <= 1'b0;
            r_tx_data <= 8'b0;
		end else if ((i_wb_stb)&&(i_wb_addr[1:0] == UART_TXREG)&&(i_wb_we)&&(i_wb_sel[0])) begin
            r_tx_data <= i_wb_data[7:0];
            tx_empty_n <= 1'b1;
        end
		else if (!tx_busy_d && tx_busy) begin
            tx_empty_n <= 1'b0;
        end
    end

    assign tx_data = r_tx_data;

    assign tx_reg = { w_uart_tx, tx_break, tx_busy, tx_empty_n, r_tx_data };

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Bus / register handling
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// r_wb_addr
	// {{{
	// You may recall from above that reads take two clocks.  Hence, we
	// need to delay the address decoding for a clock until the data is
	// ready.  We do that here.
	always @(posedge i_clk)
		r_wb_addr <= i_wb_addr;
	// }}}

	// r_wb_ack
	// {{{

	always @(posedge i_clk or negedge i_reset_n) // We'll ACK in two clocks
		if (!i_reset_n)
			r_wb_ack <= 1'b0;
		else
			r_wb_ack <= i_wb_stb;

	// }}}

	// o_wb_ack
	// {{{
	always @(posedge i_clk or negedge i_reset_n) // Okay, time to set the ACK
		if (!i_reset_n)
			o_wb_ack <= 1'b0;
		else
			o_wb_ack <= (r_wb_ack)&&(i_wb_cyc);
	// }}}

	// o_wb_data
	// {{{
	// Finally, set the return data.  This data must be valid on the same
	// clock o_wb_ack is high.  On all other clocks, it is irrelelant--since
	// no one cares, no one is reading it, it gets lost in the mux in the
	// interconnect, etc.  For this reason, we can just simplify our logic.
	always @(posedge i_clk)
	casez(r_wb_addr)
	UART_SETUP: o_wb_data <= uart_setup;
    UART_CRREG: o_wb_data <= { 26'b0, cr_reg };
    UART_RXREG: o_wb_data <= { 18'b0, rx_reg };
	UART_TXREG: o_wb_data <= { 20'b0, tx_reg };
	endcase
	// }}}

	// o_wb_stall
	// {{{
	// This device never stalls.  Sure, it takes two clocks, but they are
	// pipelined, and nothing stalls that pipeline.  (Creates FIFO errors,
	// perhaps, but doesn't stall the pipeline.)  Hence, we can just
	// set this value to zero.
	assign	o_wb_stall = 1'b0;
	// }}}
	// }}}

	// Make verilator happy
	// {{{
	// verilator lint_off UNUSED
	wire	unused;
	assign	unused = &{ 1'b0, i_wb_data[31] };
	// verilator lint_on UNUSED
	// }}}
endmodule
