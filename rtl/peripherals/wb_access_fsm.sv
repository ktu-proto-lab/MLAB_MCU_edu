// Wishbone master control fsm
module wb_access_fsm (
    input  logic        clk,

    // Control
    input  logic        start,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        we,        // write enable: 1 = write, 0 = read
    output logic        done,
    output logic [31:0] rdata,
    output logic        busy,

    // Wishbone interface
    wb_if.master    wb
);

    typedef enum logic [1:0] {
        IDLE, ISSUE, WAIT_ACK, DONE
    } state_t;

    state_t state, next_state;

    logic [31:0] rdata_reg;

    always_ff @(posedge clk or negedge wb.rst) begin
        if (!wb.rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @(posedge clk) begin
        if (state == WAIT_ACK && wb.ack && !we)
`ifdef NO_MODPORT_EXPRESSIONS
            rdata_reg <= wb.dat_s;
`else
            rdata_reg <= wb.dat_i;
`endif
    end

    assign wb.sel = 4'b1111;
    assign wb.adr = (state == ISSUE || state == WAIT_ACK) ? addr : 32'd0;
`ifdef NO_MODPORT_EXPRESSIONS
    assign wb.dat_m = wdata;
`else
    assign wb.dat_o = wdata;
`endif
    assign wb.we  = (state == ISSUE || state == WAIT_ACK) ? we : 1'b0;
    assign wb.cyc = (state == ISSUE || state == WAIT_ACK);
    assign wb.stb = (state == ISSUE || state == WAIT_ACK);

    assign rdata    = rdata_reg;
    assign busy     = (state != IDLE && state != DONE);
    assign done     = (state == DONE);

    always_comb begin
        next_state = state;
        case (state)
            IDLE:     if (start) next_state = ISSUE;
            ISSUE:    next_state = WAIT_ACK;
            WAIT_ACK: if (wb.ack) next_state = DONE;
            DONE:     next_state = IDLE;
        endcase
    end
endmodule
