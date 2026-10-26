/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
    *
    * Image Processing Accelerator - Wishbone Slave
  Description:
    * Wishbone-mapped accelerator that reads pixels one byte at a time from the
    * sobel FIFO, processes them, and writes the result one byte at a time to
    * an intermediate FIFO consumed by the compression accelerator.
    *
    * Register map (word-aligned, byte offsets):
    *   0x00  CTRL        R/W  bit[0]: auto_start  - start automatically when FIFO is non-empty
    *                          bit[1]: algo_sel    - 0: idk
    *   0x04  STATUS      RO   bit[0]: busy
    *                          bit[1]: done        - High for one cycle after a frame is finished being processed
    *                          bit[2]: error       - Currently unused
    *   0x08  FRAME_COUNT RO   increments each completed frame; wraps at 2^32
    *
    *   One pixel (1 byte) is consumed from the input FIFO and one processed pixel
    *   is written to the output FIFO per clock cycle when both FIFOs are ready.
*/
module interpol_acc (
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

    // output image size regulate in tb
    localparam int TOTAL_PIXELS_OLD = 76800; // 320 x 240
    localparam int TOTAL_PIXELS_NEW = 1228800; // 1280 x 960

    localparam int IMAGE_W_OLD = 320;
    localparam int IMAGE_H_OLD = 240;

    localparam int IMAGE_W_NEW = 1280;
    localparam int IMAGE_H_NEW = 960;

    localparam int SIZE_COEF_X = IMAGE_W_NEW / IMAGE_W_OLD;
    localparam int SIZE_COEF_Y = IMAGE_H_NEW / IMAGE_H_OLD; 

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        LOAD = 2'b01,   // read one source row into line buffer
        EMIT = 2'b10,   // write the row out SIZE_COEF_Y times, each pixel SIZE_COEF_X times
        DONE = 2'b11
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


    logic [$clog2(IMAGE_W_OLD)-1:0]       in_x,  in_x_next;   // LOAD: source column / EMIT: source column
    logic [$clog2(IMAGE_H_OLD)-1:0]       in_y,  in_y_next;   // source row
    logic [$clog2(SIZE_COEF_X)-1:0] rep_x, rep_x_next;  // horizontal repeat
    logic [$clog2(SIZE_COEF_Y)-1:0] rep_y, rep_y_next;  // vertical repeat
    logic [7:0] line_buffer [IMAGE_W_OLD];
    // -------------------------------------------------------------------------
    // Wishbone protocol
    // -------------------------------------------------------------------------
    logic [31:0] wb_wdata;
    logic [31:0] wb_rdata;

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
    assign fifo_rd_en = (state == LOAD) && !fifo_empty && !out_full;

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
    	    
            in_x            <= '0;
            in_y            <= '0;
            rep_x           <= '0;
            rep_y           <= '0;
        end else begin
            state           <= state_next;
            wr_ptr          <= wr_ptr_next;
            ctrl_auto_start <= ctrl_auto_start_next;
            ctrl_algo_sel   <= ctrl_algo_sel_next;
            csr_busy        <= csr_busy_next;
            csr_done        <= csr_done_next;
            csr_error       <= csr_error_next;
            csr_frame_count <= csr_frame_count_next;

            in_x            <= in_x_next;
            in_y            <= in_y_next;
            rep_x           <= rep_x_next;
            rep_y           <= rep_y_next;
        end
    end


    always_ff @(posedge wb.clk) begin
        if (fifo_rd_en)
            line_buffer[in_x] <= fifo_dout;
    end

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

        in_x_next            = in_x;
        in_y_next            = in_y;
        rep_x_next           = rep_x;
        rep_y_next           = rep_y;

        // Combinational output defaults
        out_wr_en = 1'b0;
        out_din   = 8'h0;

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
                    state_next           = LOAD;

                    in_x_next      = '0;
                    in_y_next      = '0;
                    rep_x_next     = '0;
                    rep_y_next     = '0;
                    state_next     = LOAD;
                end
            end

            // Collect one source row (320 pixels) into line_buffer.
            LOAD: begin
                if (fifo_rd_en) begin
                    if (in_x == IMAGE_W_OLD - 1) begin
                        in_x_next  = '0;
                        state_next = EMIT;
                    end else begin
                        in_x_next = in_x + 1'b1;
                    end
                end
            end

            // -----------------------------------------------------------------
            // FWFT FIFO: fifo_dout is valid whenever fifo_empty=0.
            // Stall when either FIFO is not ready (fifo_rd_en handles both).

            EMIT: begin
                if (!out_full) begin
                    out_wr_en = 1'b1;
                    out_din   = line_buffer[in_x];

                    if (rep_x == SIZE_COEF_X - 1) begin
                        rep_x_next = '0;
                        if (in_x == IMAGE_W_OLD - 1) begin
                            in_x_next = '0;
                            if (rep_y == SIZE_COEF_Y - 1) begin
                                rep_y_next = '0;
                                // Whole source row has been emitted 4 times
                                if (in_y == IMAGE_H_OLD - 1) begin
                                    in_y_next            = '0;
                                    csr_busy_next        = 1'b0;
                                    csr_done_next        = 1'b1;
                                    csr_frame_count_next = csr_frame_count + 32'h1;
                                    state_next           = DONE;
                                end else begin
                                    in_y_next  = in_y + 1'b1;
                                    state_next = LOAD;
                                end
                            end else begin
                                rep_y_next = rep_y + 1'b1;
                            end
                        end else begin
                            in_x_next = in_x + 1'b1;
                        end
                    end else begin
                        rep_x_next = rep_x + 1'b1;
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
                    state_next           = LOAD;
                end else begin
                    state_next = IDLE;
                end
            end

            default: state_next = IDLE;
        endcase
    end
endmodule
