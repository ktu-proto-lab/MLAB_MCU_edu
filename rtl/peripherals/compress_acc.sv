/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
  Description:
    * Compression Accelerator
    *
    * Reads 8-bit words from an intermediate FIFO (written by sobel_acc) and
    * streams compressed output into the TX FIFO. 
    *
    * The current implementation acts as pass-through which simply copies the words unmodified
    *
    * Students should replace the tx_din assignment with their compression algorithm.
    *
    * Register map (word-aligned, byte offsets):
    *   0x00  CTRL    R/W  bit[0]: auto_start - keep compressing frames; write 0 to stop after current frame
    *   0x04  STATUS  RO   bit[0]: busy
    *                      bit[1]: done  - stays high after a frame completes until the next jump from IDLE to RUN (!fifo_empty && !tx_full)
    *
    *   The input FIFO is FWFT: fifo_dout is valid whenever fifo_empty=0.
    *   fifo_rd_en advances to the next word on the following cycle.
    *   tx_wr_en is gated on !tx_full (backpressure, no data loss).
*/
module compress_acc (
    wb_if.slave  wb,

    // Intermediate FIFO - source (FWFT, 8-bit, one pixel per word)
    input  logic       fifo_empty,
    input  logic [7:0] fifo_dout,
    output logic       fifo_rd_en,

    // TX FIFO - destination
    output logic       tx_wr_en,
    output logic [7:0] tx_din,
    input  logic       tx_full
);

    localparam int TOTAL_PIXELS = 76800; // 320 x 240

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        RUN  = 2'b01,
        DONE = 2'b10
    } state_t;

    state_t      state,           state_next;
    logic [31:0] rd_ptr,          rd_ptr_next;
    logic        ctrl_auto_start, ctrl_auto_start_next;
    logic        csr_busy,        csr_busy_next;
    logic        csr_done,        csr_done_next;
    logic        wb_wr;
    logic [31:0] run_count,      run_count_next;
    logic [7:0]  last_value,     last_value_next;
    logic count_printed, count_printed_next;
    logic done_pending, done_pending_next;
    logic fifo_rd_en_next;

    // -------------------------------------------------------------------------
    // Wishbone protocol
    // -------------------------------------------------------------------------
    logic [31:0] wb_wdata, wb_rdata;

`ifdef NO_MODPORT_EXPRESSIONS
    assign wb_wdata = wb.dat_m;
    assign wb.dat_s = wb_rdata;
`else
    assign wb_wdata = wb.dat_i;
    assign wb.dat_o = wb_rdata;
`endif

    assign wb.stall = 1'b0;
    assign wb.err   = 1'b0;

    // Acknowledge generation
    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) wb.ack <= 1'b0;
        else         wb.ack <= wb.cyc & wb.stb & ~wb.stall;
    end

    assign wb_wr = wb.cyc & wb.stb & wb.we & ~wb.stall;
    
    // Reading logic
    always_comb begin
        case (wb.adr[3:2])
            2'h0:    wb_rdata = {31'h0, ctrl_auto_start};
            2'h1:    wb_rdata = {30'h0, csr_done, csr_busy};
            default: wb_rdata = 32'h0;
        endcase
    end

    // -------------------------------------------------------------------------
    // FSM registers
    // -------------------------------------------------------------------------
    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) begin
            state           <= IDLE;
            rd_ptr          <= 32'h0;
            ctrl_auto_start <= 1'b0;
            csr_busy        <= 1'b0;
            csr_done        <= 1'b0;
            run_count  <= 32'h0;
            last_value <= 8'h0;
	    count_printed <= 1'b0;
	    done_pending <= 1'b0;
	    fifo_rd_en <= 1'b0;

        end else begin
            state           <= state_next;
            rd_ptr          <= rd_ptr_next;
            ctrl_auto_start <= ctrl_auto_start_next;
            csr_busy        <= csr_busy_next;
            csr_done        <= csr_done_next;
            run_count  <= run_count_next;
            last_value <= last_value_next;
	    count_printed <= count_printed_next;
	    fifo_rd_en <= fifo_rd_en_next;
        end
    end

    // -------------------------------------------------------------------------
    // FSM combinational
    // -------------------------------------------------------------------------
    //assign fifo_rd_en = (state == RUN) && !fifo_empty && !tx_full;

    always_comb begin
        state_next           = state;
        rd_ptr_next          = rd_ptr;
        ctrl_auto_start_next = ctrl_auto_start;
        csr_busy_next        = csr_busy;
        csr_done_next        = csr_done;
        run_count_next  = run_count;
        last_value_next = last_value;
	count_printed_next = count_printed;
   

        tx_wr_en = 1'b0;
        tx_din   = 8'h0;
	fifo_rd_en_next = 1'b0;

        if (wb_wr && wb.adr[3:2] == 2'h0) begin
            ctrl_auto_start_next = wb_wdata[0];
            csr_done_next        = 1'b0;
        end

        case (state)
            // -----------------------------------------------------------------
            IDLE: begin
                if (ctrl_auto_start && !fifo_empty) begin
                    csr_done_next = 1'b0;
                    csr_busy_next = 1'b1;
                    rd_ptr_next   = 32'h0;
                    state_next    = RUN;
                end
            end

            // -----------------------------------------------------------------
            // FWFT FIFO: fifo_dout is valid whenever fifo_empty=0.
            // Stall both sides when tx_full is asserted (no data consumed or produced).
            RUN: begin
                if (!fifo_empty && !tx_full) begin
                    //tx_din   = fifo_dout; // TODO: replace with compression

	 	    if(count_printed == 1) begin
		    	tx_din = last_value;  
			count_printed_next = 1'b0;
			tx_wr_en = 1'b1;

			run_count_next  = 32'd0;          // new run starts at 0
                        last_value_next = fifo_dout;
			fifo_rd_en_next = 1'b1;
		    end

		    //the first pixel has a run count of 0 
		    if(run_count == 0) begin
			    if(fifo_rd_en == 1'b0) begin
				fifo_rd_en_next = 1'b1;
			end else begin
			    last_value_next = fifo_dout;
			end
		    end

                    if (fifo_dout == last_value && run_count < 255 && !done_pending) begin
                        run_count_next = run_count + 1;   // extend run
			fifo_rd_en_next = 1'b1;
                    end else begin
			//tx_wr_en (write enable) should only be 1 when we are
			//ready to write the data	
			tx_din = run_count;
			count_printed_next = 1'b1;
			tx_wr_en = 1'b1;
			//fifo_rd_en_next = 1'b0;
                     end
 
		    if(fifo_rd_en) begin
                        if (rd_ptr + 32'h1 >= TOTAL_PIXELS) begin
			    done_pending_next = 1'b1;
		    	    //fifo_rd_en_next = 1'b0;	    
			end else begin
                            rd_ptr_next = rd_ptr + 32'h1;
			end
		    end
		
		    if(done_pending && count_printed == 1'b0) begin
                            csr_busy_next = 1'b0;
                            csr_done_next = 1'b1;
			    done_pending_next = 1'b0;
                            state_next    = DONE;
                    end
                end
            end

            // -----------------------------------------------------------------
            DONE: begin
                if (ctrl_auto_start && !fifo_empty) begin
                    csr_busy_next = 1'b1;
                    rd_ptr_next   = 32'h0;
                    state_next    = RUN;
                end else begin
                    state_next = IDLE;
                end
            end

            default: state_next = IDLE;
        endcase
    end

endmodule
