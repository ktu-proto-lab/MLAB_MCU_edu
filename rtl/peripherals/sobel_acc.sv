/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
    *
    * Image Processing Accelerator - Wishbone Slave
  Description:
    * Wishbone-mapped accelerator that reads pixels from Frame BRAM A, processes
    * them, and writes results to Frame BRAM B.
    *
    * Register map (word-aligned, byte offsets):
    *   0x00  CTRL        R/W  bit[0]: start      - write 1 to begin; self-clears when done
    *                          bit[1]: auto_start  - start automatically on frame_ready
    *                          bit[2]: algo_sel    - 0: inversion (default)  1: Sobel (student impl)
    *   0x04  STATUS      RO   bit[0]: busy
    *                          bit[1]: done        - held until next CTRL write
    *                          bit[2]: frame_ready - set when BRAM A is full; cleared on start
    *                          bit[3]: error
    *   0x08  FRAME_COUNT RO   increments each completed frame; wraps at 2^32
    *
    * frame_ready_i is asserted by the camera interface for one cycle when a
    * full frame has been written.
    *
    *   Each 32-bit word (4 pixels) costs 2 cycles (one FETCH + one WRITE).
*/
module sobel_acc (
    wb_if.slave  wb,

    input  logic        frame_ready_i,

    input  logic        fifo_empty,
    input  logic [31:0] fifo_dout,
    output logic        fifo_rd_en,

    output logic        dst_en,
    output logic        dst_we,
    output logic [14:0] dst_addr,
    output logic [31:0] dst_wdata,
    input  logic [31:0] dst_rdata
);

    localparam int FRAME_WORDS = 19200;

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
    logic        csr_frame_ready, csr_frame_ready_next;
    logic        csr_error,       csr_error_next;
    logic [31:0] csr_frame_count, csr_frame_count_next;
    logic        wb_wr, do_start;

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

    assign do_start = (wb_wr && wb.adr[3:2] == 2'h0 && wb_wdata[0]) ||
                      (ctrl_auto_start && csr_frame_ready && state == IDLE);

    assign fifo_rd_en = (state == RUN) && !fifo_empty;

    // -------------------------------------------------------------------------
    // Wishbone read mux (purely combinational)
    // -------------------------------------------------------------------------
    always_comb begin
        case (wb.adr[3:2])
            2'h0:    wb_rdata = {29'h0, ctrl_algo_sel, ctrl_auto_start, csr_busy};
            2'h1:    wb_rdata = {28'h0, csr_error, csr_frame_ready, csr_done, csr_busy};
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
            csr_frame_ready <= 1'b0;
            csr_error       <= 1'b0;
            csr_frame_count <= 32'h0;
        end else begin
            state           <= state_next;
            wr_ptr          <= wr_ptr_next;
            ctrl_auto_start <= ctrl_auto_start_next;
            ctrl_algo_sel   <= ctrl_algo_sel_next;
            csr_busy        <= csr_busy_next;
            csr_done        <= csr_done_next;
            csr_frame_ready <= csr_frame_ready_next;
            csr_error       <= csr_error_next;
            csr_frame_count <= csr_frame_count_next;
        end
    end

    // -------------------------------------------------------------------------
    // FSM registers
    // -------------------------------------------------------------------------
    always_comb begin
        // Default: hold all registers
        state_next           = state;
        wr_ptr_next          = wr_ptr;
        ctrl_auto_start_next = ctrl_auto_start;
        ctrl_algo_sel_next   = ctrl_algo_sel;
        csr_busy_next        = csr_busy;
        csr_done_next        = csr_done;
        csr_frame_ready_next = csr_frame_ready;
        csr_error_next       = csr_error;
        csr_frame_count_next = csr_frame_count;

        // Combinational output defaults
        dst_en    = 1'b0;
        dst_we    = 1'b0;
        dst_addr  = 15'h0;
        dst_wdata = 32'h0;

        // Latch frame_ready pulse from camera interface
        if (frame_ready_i)
            csr_frame_ready_next = 1'b1;

        // CPU write to CTRL register: update config bits, clear done
        if (wb_wr && wb.adr[3:2] == 2'h0) begin
            ctrl_auto_start_next = wb_wdata[1];
            ctrl_algo_sel_next   = wb_wdata[2];
            csr_done_next        = 1'b0;
        end

        case (state)
            // -----------------------------------------------------------------
            IDLE: begin
                if (do_start) begin
                    csr_frame_ready_next = 1'b0;
                    csr_done_next        = 1'b0;
                    csr_error_next       = 1'b0;
                    csr_busy_next        = 1'b1;
                    wr_ptr_next          = 32'h0;
                    state_next           = RUN;
                end
            end

            // -----------------------------------------------------------------
            // FWFT FIFO: fifo_dout is valid whenever fifo_empty=0.
            // Consume one word per cycle; stall naturally when FIFO is empty.
            RUN: begin
                if (!fifo_empty) begin
                    dst_en    = 1'b1;
                    dst_we    = 1'b1;
                    dst_addr  = wr_ptr[14:0];
                    // algo_sel=0: inversion   algo_sel=1: STUDENT SOBEL HERE
                    dst_wdata = ctrl_algo_sel ? fifo_dout : ~fifo_dout;

                    wr_ptr_next = wr_ptr + 32'h1;

                    if (wr_ptr + 32'h1 >= FRAME_WORDS) begin
                        csr_busy_next        = 1'b0;
                        csr_done_next        = 1'b1;
                        csr_frame_count_next = csr_frame_count + 32'h1;
                        state_next           = DONE;
                    end
                end
            end

            // -----------------------------------------------------------------
            DONE: begin
                if (do_start) begin
                    csr_frame_ready_next = 1'b0;
                    csr_done_next        = 1'b0;
                    csr_error_next       = 1'b0;
                    csr_busy_next        = 1'b1;
                    wr_ptr_next          = 32'h0;
                    state_next           = RUN;
                end else if (wb_wr && wb.adr[3:2] == 2'h0) begin
                    state_next = IDLE;
                end
            end

            default: state_next = IDLE;
        endcase
    end
endmodule