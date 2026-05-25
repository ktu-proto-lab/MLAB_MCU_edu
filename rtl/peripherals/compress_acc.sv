/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
  Description:
    * Compression Accelerator
    *
    * Reads 32-bit words from Frame BRAM B and writes them into the TX FIFO.
    * The pass-through reference copies words unmodified; students replace the
    * tx_din assignment with their compression algorithm.
    *
    * Register map (word-aligned, byte offsets):
    *   0x00  CTRL    R/W  bit[0]: start - one-shot trigger, self-clears when RUN begins
    *   0x04  STATUS  RO   bit[0]: busy
    *                      bit[1]: done  - stays high after frame completes until next start
    *
    *   Each 32-bit word costs 2 cycles (one FETCH + one WRITE).
    *   WRITE stalls while tx_full is asserted (backpressure, no data loss).
*/
module compress_acc (
    wb_if.slave  wb,

    // Frame BRAM B - source (read-only port)
    output logic        src_en,
    output logic [14:0] src_addr,
    input  logic [31:0] src_rdata,

    // TX FIFO - destination
    output logic        tx_wr_en,
    output logic [31:0] tx_din,
    input  logic        tx_full
);

    localparam int FRAME_WORDS = 19200;

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        FETCH = 2'b01,
        WRITE = 2'b10,
        DONE  = 2'b11
    } state_t;

    state_t      state,      state_next;
    logic [14:0] rd_ptr,     rd_ptr_next;
    logic        ctrl_start, ctrl_start_next;
    logic        csr_busy,   csr_busy_next;
    logic        csr_done,   csr_done_next;
    logic        wb_wr;

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

    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) wb.ack <= 1'b0;
        else         wb.ack <= wb.cyc & wb.stb & ~wb.stall;
    end

    assign wb_wr = wb.cyc & wb.stb & wb.we & ~wb.stall;

    always_comb begin
        case (wb.adr[3:2])
            2'h0:    wb_rdata = {31'h0, ctrl_start};
            2'h1:    wb_rdata = {30'h0, csr_done, csr_busy};
            default: wb_rdata = 32'h0;
        endcase
    end

    // -------------------------------------------------------------------------
    // FSM registers
    // -------------------------------------------------------------------------
    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) begin
            state      <= IDLE;
            rd_ptr     <= 15'h0;
            ctrl_start <= 1'b0;
            csr_busy   <= 1'b0;
            csr_done   <= 1'b0;
        end else begin
            state      <= state_next;
            rd_ptr     <= rd_ptr_next;
            ctrl_start <= ctrl_start_next;
            csr_busy   <= csr_busy_next;
            csr_done   <= csr_done_next;
        end
    end

    // -------------------------------------------------------------------------
    // FSM combinational
    // -------------------------------------------------------------------------
    always_comb begin
        state_next      = state;
        rd_ptr_next     = rd_ptr;
        ctrl_start_next = ctrl_start;
        csr_busy_next   = csr_busy;
        csr_done_next   = csr_done;

        src_en   = 1'b0;
        src_addr = 15'h0;
        tx_wr_en = 1'b0;
        tx_din   = 32'h0;

        if (wb_wr && wb.adr[3:2] == 2'h0)
            ctrl_start_next = wb_wdata[0];

        case (state)
            // -----------------------------------------------------------------
            IDLE: begin
                if (ctrl_start) begin
                    ctrl_start_next = 1'b0;
                    csr_done_next   = 1'b0;
                    csr_busy_next   = 1'b1;
                    rd_ptr_next     = 15'h0;
                    state_next      = FETCH;
                end
            end

            // -----------------------------------------------------------------
            // Issue BRAM read for rd_ptr. Data appears on src_rdata next cycle.
            FETCH: begin
                src_en     = 1'b1;
                src_addr   = rd_ptr;
                state_next = WRITE;
            end

            // -----------------------------------------------------------------
            // src_rdata holds the word fetched in FETCH. Stall on tx_full.
            WRITE: begin
                if (!tx_full) begin
                    tx_wr_en = 1'b1;
                    tx_din   = src_rdata; // TODO: replace with compressed output

                    if (rd_ptr == FRAME_WORDS[14:0] - 15'h1) begin
                        csr_busy_next = 1'b0;
                        csr_done_next = 1'b1;
                        state_next    = DONE;
                    end else begin
                        rd_ptr_next = rd_ptr + 15'h1;
                        state_next  = FETCH;
                    end
                end
            end

            // -----------------------------------------------------------------
            // done stays high until next start is written.
            DONE: begin
                state_next = IDLE;
            end

            default: state_next = IDLE;
        endcase
    end

endmodule
