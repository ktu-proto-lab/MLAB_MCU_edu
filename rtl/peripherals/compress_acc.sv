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

    logic [31:0] run_count,       run_count_next;
    logic [7:0]  last_value,      last_value_next;
    logic [2:0]  output_phase,    output_phase_next;
    logic [8:0]	 next_pixel, 	  next_pixel_next;
    //logic count_printed, count_printed_next;
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
	    //count_printed <= 1'b0;
	    done_pending <= 1'b0;
	    fifo_rd_en <= 1'b0;

            output_phase <= 2'b00;
            next_pixel <= 8'b00000000;

        end else begin
            state           <= state_next;
            rd_ptr          <= rd_ptr_next;
            ctrl_auto_start <= ctrl_auto_start_next;
            csr_busy        <= csr_busy_next;
            csr_done        <= csr_done_next;
            run_count  <= run_count_next;
            last_value <= last_value_next;
    	    //count_printed <= count_printed_next;
    	    done_pending <= done_pending_next;
    	    fifo_rd_en <= fifo_rd_en_next;
            output_phase <= output_phase_next;
            next_pixel <= next_pixel_next;

	    //$display("%b", run_count);
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
	//count_printed_next = count_printed;
	done_pending_next = done_pending;
	fifo_rd_en_next = fifo_rd_en;
	output_phase_next = output_phase;
	next_pixel_next = next_pixel;
 
        tx_wr_en = 1'b0;
        tx_din   = 8'h0;

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
    	        if(!tx_full) begin
    		    // Default values
    		    fifo_rd_en_next = 0;
    		    tx_wr_en = 0;
    		    tx_din = 0;


		    // $display("%d", output_phase);
        	    if(output_phase == 0) begin
        	         // Read phase
        	         if(!fifo_empty && !done_pending) begin
				$display("%d", rd_ptr);
            	             if (rd_ptr == 0) begin
                                 // First pixel: store, start run
                                 last_value_next = fifo_dout;
                                 run_count_next  = 0;
                                 fifo_rd_en_next = 1;
                                 rd_ptr_next     = rd_ptr + 1;
            	             end 
		             else begin
                                 // Compare current pixel with last_value
                                 if (fifo_dout == last_value && run_count < 255) begin
                                     run_count_next  = run_count + 1;
                                     fifo_rd_en_next = 1;
                                     rd_ptr_next     = rd_ptr + 1;
                                     // Check if this is the last pixel
                                     if (rd_ptr + 1 > TOTAL_PIXELS) begin
                                         done_pending_next = 1;  // need to flush after reading
                                     end
                                 end 
			         else begin
                                     // Change or end of run detected
                                     next_pixel_next = fifo_dout;
                                     output_phase_next = 1;
                                     // Do NOT read the new pixel yet; we will after output completes
                                         // If we have reached end, set done_pending so we know to flush later
                                         if (rd_ptr + 1 > TOTAL_PIXELS) begin
                                             done_pending_next = 1;
                                         end
        	                 end
			     end
			 end
        	    end

                     // If done_pending is set and we have no pending output, we need to flush
                     if (done_pending && output_phase == 0) begin
                         // Start flushing the final run
                         output_phase_next = 1;
                     end
                     else if (output_phase == 1) begin
                         // Output run count
                         tx_din          = run_count;
                         tx_wr_en        = 1;
                         output_phase_next = 2;   // next phase: output pixel value
                     end
                     else if (output_phase == 2) begin
                         // Output pixel value
                         tx_din          = last_value;
                         tx_wr_en        = 1;
                         // After output, start new run or enter finishing phase
                         if (done_pending) begin
			     output_phase_next = 3;
                         end 
			 else begin
                             // Start new run using the saved next_pixel
                             last_value_next = next_pixel;
                             run_count_next  = 1;
                             fifo_rd_en_next = 1;
                             rd_ptr_next     = rd_ptr + 1;
                             output_phase_next = 0;
                         end
                     end
		     else if(output_phase == 3) begin
		         csr_busy_next = 1'b0;
                         csr_done_next = 1'b1;
                         done_pending_next = 1'b0;
                         state_next = DONE;
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
