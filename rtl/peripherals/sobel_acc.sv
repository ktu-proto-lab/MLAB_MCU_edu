/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
    *
    * Image Processing Accelerator - Wishbone Slave
  Description:
    * Wishbone-mapped accelerator that reads pixels one byte at a time from the
    * camera FIFO, processes them, and writes the result one byte at a time to
    * an intermediate FIFO consumed by the compression accelerator.
    *
    * Register map (word-aligned, byte offsets):
    *   0x00  CTRL        R/W  bit[0]: auto_start  - start automatically when FIFO is non-empty
    *                          bit[1]: algo_sel    - 0: inversion (default)  1: Sobel (student impl)
    *   0x04  STATUS      RO   bit[0]: busy
    *                          bit[1]: done        - High for one cycle after a frame is finished being processed
    *                          bit[2]: error       - Currently unused
    *   0x08  FRAME_COUNT RO   increments each completed frame; wraps at 2^32
    *
    *   One pixel (1 byte) is consumed from the input FIFO and one processed pixel
    *   is written to the output FIFO per clock cycle when both FIFOs are ready.
*/
module sobel_acc (
    wb_if.slave  wb,

    // Camera FIFO - source (FWFT, 8-bit, one pixel per word)
    input  logic       fifo_empty,
    input  logic [7:0] fifo_dout,
    output logic       fifo_rd_en,

    // Intermediate FIFO - destination (8-bit, one pixel per word)
    output logic       out_wr_en,
    output logic [7:0] out_din,
    input  logic       out_full
    );

    localparam int FRAME_W      = 640;
    localparam int FRAME_H      = 480;
    localparam int TOTAL_PIXELS = FRAME_W * FRAME_H; // 320 x 240 = 76800 // 640 x 480 = 307200

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        RUN  = 2'b01,
        DONE = 2'b10
    } state_t;

    state_t      state,           state_next;
    logic [31:0] wr_ptr,          wr_ptr_next;
    logic        ctrl_auto_start, ctrl_auto_start_next;
    logic        ctrl_algo_sel,   ctrl_algo_sel_next;
    logic        csr_busy,        csr_busy_next;
    logic        csr_done,        csr_done_next;
    logic        csr_error,       csr_error_next;
    logic [31:0] csr_frame_count, csr_frame_count_next;
    logic        wb_wr;
    logic        has_incoming_data;

    // -------------------------------------------------------------------------
    // Wishbone protocol
    // -------------------------------------------------------------------------
    logic [31:0] wb_wdata;
    logic [31:0] wb_rdata;

    // -------------------------------------------------------------------------
    // Sobel
    // -------------------------------------------------------------------------
    reg [7:0] rows [0:1][0:FRAME_W-1];
    logic [7:0] run1, run2, run3;
    logic signed [10:0] Gx, Gy;
    logic [11:0] G_sum;
    logic [31:0] line, width;
    logic [2:0] top, middle, bottom;
    
    // uncomment if running sobel_acc_tb with multiple images
    //logic last_frame, last_frame_next;

`ifdef NO_MODPORT_EXPRESSIONS
    assign wb_wdata = wb.dat_m;
    assign wb.dat_s = wb_rdata;
`else
    assign wb_wdata = wb.dat_i;
    assign wb.dat_o = wb_rdata;
`endif

    assign wb.stall = 1'b0;
    assign wb.err   = 1'b0;

    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst)
            wb.ack <= 1'b0;
        else
            wb.ack <= wb.cyc & wb.stb & ~wb.stall;
    end

    // -------------------------------------------------------------------------
    // Combinational helpers
    // -------------------------------------------------------------------------

    assign wb_wr = wb.cyc & wb.stb & wb.we & ~wb.stall;

    // Consume from input FIFO only when we can simultaneously write to output FIFO.
    assign fifo_rd_en = (state == RUN) && !fifo_empty && !out_full;

    assign has_incoming_data = (!fifo_empty || (wr_ptr + 1 >= TOTAL_PIXELS && wr_ptr + 1 < TOTAL_PIXELS+FRAME_W+3)) ? 1'b1 : 1'b0; 

    // -------------------------------------------------------------------------
    // Wishbone read mux (purely combinational)
    // -------------------------------------------------------------------------
    always_comb begin
        case (wb.adr[3:2])
            2'h0:    wb_rdata = {30'h0, ctrl_algo_sel, ctrl_auto_start};
            2'h1:    wb_rdata = {29'h0, csr_error, csr_done, csr_busy};
            2'h2:    wb_rdata = csr_frame_count;
            default: wb_rdata = 32'h0;
        endcase
    end

    // -------------------------------------------------------------------------
    // FSM registers
    // -------------------------------------------------------------------------
    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) begin
            state           <= IDLE;
            wr_ptr          <= 32'h0;
            ctrl_auto_start <= 1'b0;
            ctrl_algo_sel   <= 1'b0;
            csr_busy        <= 1'b0;
            csr_done        <= 1'b0;
            csr_error       <= 1'b0;
            csr_frame_count <= 32'h0;
            //last_frame      <= 32'h0;
        end else begin
            state           <= state_next;
            wr_ptr          <= wr_ptr_next;
            ctrl_auto_start <= ctrl_auto_start_next;
            ctrl_algo_sel   <= ctrl_algo_sel_next;
            csr_busy        <= csr_busy_next;
            csr_done        <= csr_done_next;
            csr_error       <= csr_error_next;
            csr_frame_count <= csr_frame_count_next;
            //last_frame      <= last_frame_next;
        end
    end

    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) begin
            run1 <= 0;
            run2 <= 0;
            run3 <= 0;
            line <= 0;
            width <= 0;
        end 
        else if(ctrl_algo_sel && !out_full && state == RUN && has_incoming_data) begin

            if (width == FRAME_W-1) begin
                if(line == 1)line <= 0; 
                else line <= line + 1;
            end

            if(width == FRAME_W-1 || wr_ptr == 2) width <= 0;
            else width <= width + 1;

            rows[line][width] <= run1;

            run1 <= run2;
            run2 <= run3;
            run3 <= fifo_dout;

        end
    end


    assign out_wr_en = ctrl_algo_sel ? ((wr_ptr > FRAME_W + 1) && !out_full && has_incoming_data && state==RUN) : state==RUN; 
    
    assign out_din = ctrl_algo_sel ? ((G_sum > 255) ? 255 : G_sum) : ~fifo_dout;

    
    // -------------------------------------------------------------------------
    // FSM combinational
    // -------------------------------------------------------------------------
    always_comb begin
        // Defaults
        state_next           = state;
        wr_ptr_next          = wr_ptr;
        ctrl_auto_start_next = ctrl_auto_start;
        ctrl_algo_sel_next   = ctrl_algo_sel;
        csr_busy_next        = csr_busy;
        csr_done_next        = csr_done;
        csr_error_next       = csr_error;
        csr_frame_count_next = csr_frame_count;

        Gx = 0;
        Gy = 0;
        G_sum = 0;

        // Combinational output defaults
        //out_wr_en = 1'b0;
        //out_din   = 8'h0;
        
        // CPU write to CTRL register: update config bits, clear done
        if (wb_wr && wb.adr[3:2] == 2'h0) begin
            ctrl_auto_start_next = wb_wdata[0];
            ctrl_algo_sel_next   = wb_wdata[1];
            csr_done_next        = 1'b0;
        end

        case (state)
            // -----------------------------------------------------------------
            IDLE: begin
                if (ctrl_auto_start && !fifo_empty) begin
                    csr_done_next        = 1'b0;
                    csr_error_next       = 1'b0;
                    csr_busy_next        = 1'b1;
                    wr_ptr_next          = 32'h0;
                    //last_frame_next      = 32'h0;
                    state_next           = RUN;
                end
            end

            // -----------------------------------------------------------------
            // FWFT FIFO: fifo_dout is valid whenever fifo_empty=0.
            // Stall when either FIFO is not ready (fifo_rd_en handles both).
            RUN: begin
                    if(ctrl_algo_sel) begin //Sobelio algoritmas

                        
                        if (!out_full && has_incoming_data) begin

                        // kad sobel_acc_tb pagautu kada baigiasi frame (siaip tai redundant ant kitu tb)
                        /*
                            if(last_frame != csr_frame_count && wr_ptr == FRAME_W + 5)begin
                                csr_done_next = 1'b0;
                                last_frame_next = csr_frame_count;
                            end
                        */
                            
                            if(line == 0) begin
                                top = 0;
                                bottom = 1;
                            end
                            else begin
                                top = 1;
                                bottom = 0;
                            end
                        

                        if(wr_ptr > TOTAL_PIXELS + 1)begin // paskutine eilute
          
                            top = 0;
                            bottom = 1;

                            if(wr_ptr == TOTAL_PIXELS + 2)begin
                                Gx = rows[top][1] + rows[bottom][1]*2 + rows[bottom][1]  - rows[top][0] - rows[bottom][0]*2 - rows[bottom][0];
                                Gy = rows[top][0] + rows[top][0]*2 + rows[top][1] - rows[bottom][0] - rows[bottom][0]*2 - rows[bottom][1];
                            end
                            else if(wr_ptr <= TOTAL_PIXELS + FRAME_W)begin
                                Gx = rows[top][width+2] + rows[bottom][width+2]*2 + rows[bottom][width+2] - rows[top][width] - rows[bottom][width]*2 - rows[bottom][width];
                                Gy = rows[top][width] + rows[top][width+1]*2 + rows[top][width+2] - rows[bottom][width] - rows[bottom][width+1]*2 - rows[bottom][width+2];
                            end
                            else if (wr_ptr == TOTAL_PIXELS + FRAME_W + 1)begin
                                Gx = rows[top][width+1] + rows[top][width+1]*2 + rows[bottom][width+1] - rows[top][width] - rows[top][width]*2 - rows[bottom][width];
                                Gy = rows[top][width] + rows[top][width+1]*2 + rows[top][width+1] - rows[bottom][width] - rows[bottom][width+1]*2 - rows[bottom][width+1];
                            end
                            
                        end
                        else if(wr_ptr > FRAME_W*2 && width < FRAME_W-2) begin // main thingy

                            Gx = rows[top][width+2] + rows[bottom][width+2]*2 + run3 - rows[top][width] - rows[bottom][width]*2 - run1;
                            Gy = rows[top][width] + rows[top][width+1]*2 + rows[top][width+2] - run1 - run2*2 - run3; 
   
                        end
                        else if (wr_ptr> FRAME_W + 1 && wr_ptr < FRAME_W*2 + 2)begin // pirma eilute
              
                            top = 0;
                            bottom = 1;
                            
                            if(wr_ptr == FRAME_W + 2)begin
                                Gx = rows[top][1] + rows[top][1]*2 + run3 - rows[top][0] - rows[top][0]*2 - run2;
                                Gy = rows[top][1] + rows[top][0]*2 + rows[top][0] - run2 - run2*2 - run3;
                            end
                            else if(wr_ptr <= FRAME_W*2)begin
                                Gx = rows[top][width+2] + rows[top][width+2]*2 + run3 - rows[top][width] - rows[top][width]*2 - run1;
                                Gy = rows[top][width] + rows[top][width+1]*2 + rows[top][width+2] - run1 - run2*2 - run3;
                            end
                            else if (wr_ptr == FRAME_W*2+1)begin
                                Gx = rows[top][width+1] + rows[top][width+1]*2 + run2 - rows[top][width] - rows[top][width]*2 - run1;
                                Gy = rows[top][width] + rows[top][width+1]*2 + rows[top][width+1] - run1 - run2*2 - run2;
                            end
   
                        end
                        else if (wr_ptr > FRAME_W*2 && width == FRAME_W-2)begin // paskutinis eilutes pixel

                            Gx = rows[top][width+1] + rows[bottom][width+1]*2 + run2 - rows[top][width] - rows[bottom][width]*2 - run1;
                            Gy = rows[top][width] + rows[top][width+1]*2 + rows[top][width+1] - run1 - run2*2 - run2;

                        end
                        else if(wr_ptr > FRAME_W*2 && width == FRAME_W-1) begin // pirmas eilutes pixel

                            Gx = rows[bottom][1] + rows[top][1]*2 + run3 - rows[bottom][0] - rows[top][0]*2 - run2;
                            Gy = rows[bottom][0] + rows[bottom][0]*2 + rows[bottom][1] - run2 - run2*2 - run3;
                            
                        end
                        
                        
                        G_sum = (Gx[10] ? -Gx : Gx) + (Gy[10] ? -Gy : Gy);

                        wr_ptr_next = wr_ptr + 32'h1;
                        end
                        

                    end else begin 
                        wr_ptr_next = wr_ptr + 32'h1;
                    end


                    
                        
                    if(ctrl_algo_sel) begin
                        if (has_incoming_data && wr_ptr_next >= TOTAL_PIXELS+FRAME_W+2) begin
                            csr_frame_count_next = csr_frame_count + 32'h1;
                            wr_ptr_next          = FRAME_W + 2;

                            //csr_done_next        = 1'b1;

                            

                            if(!ctrl_auto_start)begin 
                                state_next      = DONE;
                                csr_busy_next   = 1'b0;
                                csr_done_next   = 1'b1;

                            end
                        end
                    end else begin
                        if (wr_ptr + 32'h1 >= TOTAL_PIXELS) begin
                        csr_busy_next        = 1'b0;
                        csr_done_next        = 1'b1;
                        csr_frame_count_next = csr_frame_count + 32'h1;
                        state_next           = DONE;
                        end
                    end
                end
            

            // -----------------------------------------------------------------
            DONE: begin
                // If auto_start jump straight into RUN state for the next frame
                if (ctrl_auto_start && !fifo_empty) begin
                    csr_done_next        = 1'b0;
                    csr_error_next       = 1'b0;
                    csr_busy_next        = 1'b1;
                    wr_ptr_next          = 32'h0;
                    state_next           = RUN;

                end else begin
                    state_next = IDLE;
                end
            end

            default: state_next = IDLE;
        endcase
    end
endmodule
