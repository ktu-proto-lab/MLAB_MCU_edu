/*
  Contributors:
    * Dovydas Liutkus (dovliu2@ktu.lt)
    *
    * Image Processing Accelerator - Wishbone Slave
  Description:
    * Wishbone-mapped accelerator that reads pixels from Frame BRAM A, processes
    * them, and writes results to Frame BRAM B.  The initial processing stage is
    * pixel inversion (255 - pixel).  Students replace this with Sobel edge
    * detection in a later milestone.
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
    * frame_ready_i is asserted by the camera interface (or a fill counter on
    * BRAM A) for one cycle when a full frame has been written.
    *
    *   Each 32-bit word (4 pixels) costs 2 cycles (one FETCH + one WRITE).
*/
module sobel_acc (
    // 32-bit Wishbone slave
    wb_if.slave  wb,

    // Asserted for one cycle by the camera interface when BRAM A is full
    input  logic        frame_ready_i,

    // Input FIFO (FWFT) - pixel data from camera interface
    input  logic        fifo_empty,
    input  logic [31:0] fifo_dout,   // valid whenever fifo_empty=0
    output logic        fifo_rd_en,

    // Frame BRAM B - destination (write only by this module)
    output logic        dst_en,
    output logic        dst_we,
    output logic [14:0] dst_addr,
    output logic [31:0] dst_wdata,
    input  logic [31:0] dst_rdata
);

    localparam int FRAME_WORDS = 19200; // 320×240 bytes / 4

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
    // CSRs
    // -------------------------------------------------------------------------
    logic        ctrl_auto_start;
    logic        ctrl_algo_sel;
    logic        csr_busy;
    logic        csr_done;
    logic        csr_frame_ready;
    logic        csr_error;
    logic [31:0] csr_frame_count;

    // Read mux
    always_comb begin
        case (wb.adr[3:2])
            2'h0:    wb_rdata = {29'h0, ctrl_algo_sel, ctrl_auto_start, csr_busy};
            2'h1:    wb_rdata = {28'h0, csr_error, csr_frame_ready, csr_done, csr_busy};
            2'h2:    wb_rdata = csr_frame_count;
            default: wb_rdata = 32'h0;
        endcase
    end

    // -------------------------------------------------------------------------
    // FSM
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        RUN  = 2'b01,
        DONE = 2'b10
    } state_t;

    state_t      state;
    logic [31:0] wr_ptr;
    logic wb_wr, do_start;
    
    assign wb_wr = wb.cyc & wb.stb & wb.we & ~wb.stall;

    assign do_start = (wb_wr && wb.adr[3:2] == 2'h0 && wb_wdata[0]) ||
                      (ctrl_auto_start && csr_frame_ready && state == IDLE);

    assign fifo_rd_en = (state == RUN) && !fifo_empty;


    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst) begin
            state           <= IDLE;
            ctrl_auto_start <= 1'b0;
            ctrl_algo_sel   <= 1'b0;
            csr_busy        <= 1'b0;
            csr_done        <= 1'b0;
            csr_frame_ready <= 1'b0;
            csr_error       <= 1'b0;
            csr_frame_count <= 32'h0;
            wr_ptr          <= 32'h0;
            dst_en          <= 1'b0;
            dst_we          <= 1'b0;
            dst_addr        <= 15'h0;
            dst_wdata       <= 32'h0;
        end else begin
            dst_en     <= 1'b0;
            dst_we     <= 1'b0;

            // Latch frame_ready from camera interface into CSR
            if (frame_ready_i)
                csr_frame_ready <= 1'b1;

            // CPU writes to CTRL register
            if (wb_wr && wb.adr[3:2] == 2'h0) begin
                ctrl_auto_start <= wb_wdata[1];
                ctrl_algo_sel   <= wb_wdata[2];
                csr_done        <= 1'b0; // any CTRL write clears done
            end

            case (state)
                // ---------------------------------------------------------
                IDLE: begin
                    if (do_start) begin
                        csr_frame_ready <= 1'b0;
                        csr_done        <= 1'b0;
                        csr_error       <= 1'b0;
                        csr_busy        <= 1'b1;
                        wr_ptr          <= 32'h0;
                        state           <= RUN;
                    end
                end

                // ---------------------------------------------------------
                // First Word Fall Through (FWFT) - fifo_dout is already valid when fifo_empty=0.
                // Consume one word per cycle, stall when FIFO is empty.
                RUN: begin
                    if (!fifo_empty) begin
                        dst_en    <= 1'b1;
                        dst_we    <= 1'b1;
                        dst_addr  <= wr_ptr[14:0];

                        // algo_sel=0: inversion. algo_sel=1: STUDENT SOBEL HERE.
                        dst_wdata <= ctrl_algo_sel ? fifo_dout : ~fifo_dout;

                        wr_ptr <= wr_ptr + 32'h1;

                        if (wr_ptr + 32'h1 >= FRAME_WORDS) begin
                            csr_busy        <= 1'b0;
                            csr_done        <= 1'b1;
                            csr_frame_count <= csr_frame_count + 32'h1;
                            state           <= DONE;
                        end
                    end
                end

                // ---------------------------------------------------------
                DONE: begin
                    if (do_start) begin
                        csr_frame_ready <= 1'b0;
                        csr_done        <= 1'b0;
                        csr_error       <= 1'b0;
                        csr_busy        <= 1'b1;
                        wr_ptr          <= 32'h0;
                        state           <= RUN;
                    end else if (wb_wr && wb.adr[3:2] == 2'h0) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
