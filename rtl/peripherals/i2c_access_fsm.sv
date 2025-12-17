// Performs single byte I2C read / write through I2C master connected as WBs. Also supports direct wishbone accesses

`include "boot_defs.svh"

module i2c_access_fsm (
    input  logic        clk,

    // Command interface 
    input   logic               start,
    input   logic   [31:0]      w_data,
    input   logic               we,            // 0 = read, 1 = write
    output  logic               busy,
    output  logic               done,
    output  logic   [31:0]      r_data,

    input   logic               generate_STA,   // If 1 generate I2C STA
    input   logic               last_read,      // Signal final read in sequential read
    input   logic               generate_NACK,  // Write no acknowledge (NACK) to slave, indicating end of transfer
    input   logic               generate_STO,  // If 1 generate I2C stop condition during writing
    // Signals for direct wb access 
    input   logic               sram_access, // 0 = eeprom, 1 = sram
    input   logic   [31:0]      mem_addr,

    // Wishbone interface
    wb_if.master    wb
);

    typedef enum logic [3:0] {
        I2C_ENABLE,
        IDLE,
        WRITE_TXR,
        WRITE_CR_FOR_WRITE_OP,
        WRITE_CR_FOR_READ_OP,
        POLL_TIP,
        READ_ACK,
        READ_TXR,
        WRITE_CR_STOP_READ_OP,
        SRAM_WRITE,
        SRAM_READ,
        DONE_STATE
    } state_t;

    state_t state, next_state;

    logic wb_start;
    logic [31:0] wb_addr, wb_wdata, wb_rdata;
    logic wb_we, wb_done, wb_busy;

    logic [31:0] next_rdata;

    // Wishbone level control fsm
    wb_access_fsm i_wb_access (
        .clk(clk),
        .start(wb_start),
        .addr(wb_addr),
        .wdata(wb_wdata),
        .we(wb_we),
        .done(wb_done),
        .rdata(wb_rdata),
        .busy(wb_busy),
 
        .wb(wb)
    );

    assign busy = (state != IDLE);
    assign done = (state == DONE_STATE);

    // State register
    always_ff @(posedge clk or negedge wb.rst) begin
        if (!wb.rst) begin
            state   <= I2C_ENABLE;
            r_data  <= 32'd0;
        end
        else begin
            state   <= next_state;
            r_data  <= next_rdata;
        end
    end

    // Next-state logic
    always_comb begin
        // Defaults
        next_state = state;
        wb_start    = 0;
        wb_addr     = 32'd0;
        wb_wdata    = 32'd0;
        wb_we       = 0;
        next_rdata  = 32'd0;

        case (state)
        // Enable I2C core once after reset
            I2C_ENABLE: begin
                wb_addr  = `I2C_CTR;
                wb_wdata = `I2C_EN;  
                wb_we    = 1;
                if (!wb_busy && !wb_done) begin 
                    wb_start = 1;  
                end else if (wb_done) begin
                    next_state = IDLE;
                end
            end
            // Loop enable core in IDLE state
            IDLE: begin
                if (start) begin
                    if (sram_access) // Write to SRAM or interface EEPROM
                        next_state = we ? SRAM_WRITE : SRAM_READ;
                    else
                        next_state = we ? WRITE_TXR : WRITE_CR_FOR_READ_OP; // If reading skip TXR
                end
                    
            end
            // (WRITE) Write into TXR
            WRITE_TXR: begin   
                wb_addr  = `I2C_TXR;
                wb_wdata = w_data;   
                wb_we    = 1;
                if (!wb_busy && !wb_done) begin 
                    wb_start = 1;
                end else if (wb_done) begin
                    next_state = WRITE_CR_FOR_WRITE_OP;
                end
            end
            // (WRITE) Set STA and WR bits in CR 
            WRITE_CR_FOR_WRITE_OP: begin   
                wb_addr  = `I2C_CR;
                wb_wdata = `I2C_WR;
                wb_wdata |= generate_STA ? (`I2C_STA) : 1'b0;
                wb_wdata |= generate_STO ? (`I2C_STO) : 1'b0;
                wb_we    = 1;
                if (!wb_busy && !wb_done) begin
                    wb_start = 1;
                end else if (wb_done) begin
                    next_state = POLL_TIP;
                end
            end
            // (READ) Set RD bit in CR
            WRITE_CR_FOR_READ_OP: begin
                wb_addr  = `I2C_CR;
                // wb_wdata = `I2C_RD;
                wb_wdata = generate_NACK ? (`I2C_RD | `I2C_ACK) : `I2C_RD;
                wb_we    = 1;
                if (!wb_busy && !wb_done) begin
                    wb_start = 1;
                end else if (wb_done) begin
                    next_state = POLL_TIP;
                end
            end
            // (COMMON) Wait for TIP flag to negate
            POLL_TIP: begin         
                wb_addr  = `I2C_SR;
                wb_we    = 0; 
                if (!wb_busy && !wb_done) begin
                    wb_start = 1;  
                end else if (wb_done) begin
                    if (wb_rdata &`I2C_TIP) 
                        next_state = POLL_TIP; // Loop until TIP negates
                    else
                        next_state = we ? READ_ACK : READ_TXR;
                end
            end
            // (WRITE) Check read acknowledge for write operation
            READ_ACK: begin
                wb_addr  = `I2C_SR; 
                wb_we    = 0;
                if (!wb_busy && !wb_done) begin
                    wb_start = 1;
                end else if (wb_done) begin
                    if (wb_rdata & `I2C_RXACK) // If ACK bit set, NACK
                        next_state = WRITE_TXR; // Retry transmission
                    else
                        next_state = DONE_STATE;
                end
            end
            // (READ) Output read data
            READ_TXR: begin
                wb_addr  = `I2C_RXR;
                wb_we    = 0; 
                if (!wb_busy && !wb_done) begin
                    wb_start = 1;
                end else if (wb_done) begin
                    next_rdata = wb_rdata; 
                    // If last read extra state to terminate communication
                    next_state = DONE_STATE;
                end
            end            
            // (READ) Terminate read when signaled from above
            WRITE_CR_STOP_READ_OP: begin
                wb_addr  = `I2C_CR;
                // wb_wdata = `I2C_ACK | `I2C_STO;
                wb_wdata = `I2C_STO;
                wb_we    = 1;
                if (!wb_busy && !wb_done) begin
                    wb_start = 1;
                end else if (wb_done) begin
                    next_state = DONE_STATE;
                end
            end
            // (SRAM)
            SRAM_WRITE: begin
                wb_addr  = mem_addr;
                wb_wdata = w_data; 
                wb_we    = 1;
                if (!wb_busy && !wb_done) begin
                    wb_start = 1;
                end else if (wb_done) begin
                    next_state = last_read ? WRITE_CR_STOP_READ_OP : DONE_STATE;
                end
            end
            SRAM_READ: begin
                wb_addr  = mem_addr;
                wb_we    = 0;                 
                if (!wb_busy && !wb_done) begin
                    wb_start = 1;
                end else if (wb_done) begin
                    next_rdata = wb_rdata; 
                    next_state = DONE_STATE;
                end
            end
            DONE_STATE: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
