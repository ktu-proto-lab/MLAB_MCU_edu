`include "boot_defs.svh"

module bootloader_top (
        wb_if.master    wb,
        input   logic   clk,
        output  logic   rst_core_n
);

    typedef enum logic [3:0] {
        WRITE_SLAVE_ADDR_W_BIT,
        WRITE_WORD_ADDR_BYTE0,
        WRITE_WORD_ADDR_BYTE1,
        WRITE_SLAVE_ADDR_R_BIT,
        READ_DATA_BYTE0,
        READ_DATA_BYTE1,
        READ_DATA_BYTE2,
        READ_DATA_BYTE3,
        WRITE_MEM,
        READ_MEM,
        WRITE_DATA_BYTE,
        WRITE_DATA_BYTE0,
        WRITE_DATA_BYTE1,
        WRITE_DATA_BYTE2,
        WRITE_DATA_BYTE3,
        BOOT_FINISH
    } state_t;

    state_t state, next_state;
    logic next_rst_core_n, sram_access;
    logic   [31:0] mem_index, next_mem_index;
    logic   [31:0] mem_addr, mem_addr_reg;   // Byte address for SRAM writes
    
    logic   [`EEPROM_PAGE_SIZE-3:0] page_buffer_index, next_page_buffer_index;
    logic   [15:0] addr_pointer, next_addr_pointer;
    logic   [31:0] data_word;

    logic start, we;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic done, busy;
    logic generate_STA;
    logic generate_NACK;
    logic generate_STO;

    i2c_access_fsm i_i2c_fsm (
        .clk(clk),

        .start(start),
        .w_data(wdata),
        .we(we),
        .busy(busy),
        .done(done),
        .r_data(rdata),

        .generate_STA(generate_STA),
        .last_read(last_read),
        .generate_NACK(generate_NACK),
        .generate_STO(generate_STO),

        .sram_access(sram_access),
        .mem_addr(mem_addr),
        .wb(wb)
    );

    assign mem_addr = mem_addr_reg;

    // If mem_index on last mem location assert last_read
    assign last_read = (mem_index == (`IMEM_SIZE+`DMEM_SIZE-4));

    always_ff @(posedge clk or negedge wb.rst) begin
        if(!wb.rst) begin
            state       <= WRITE_SLAVE_ADDR_W_BIT;
            mem_index   <= '0;      // Keep track which memory index to know when to switch writing from IMEM to DMEM
            rst_core_n  <=  0;      // Put core in reset TODO: Check if halt can be used instead
            data_word   <= 32'd0;   // Set Zeros to register upon reset
            page_buffer_index <= '0; // Keep track of page buffer
            addr_pointer <= `EEPROM_READ_ADDR;
        end
        else begin
            state       <= next_state;
            mem_index   <= next_mem_index;
            page_buffer_index <= next_page_buffer_index;
            addr_pointer <= next_addr_pointer;
            rst_core_n  <= next_rst_core_n;
            case (state)
                READ_DATA_BYTE0: if (done) data_word[7:0] <= rdata[7:0];
                READ_DATA_BYTE1: if (done) data_word[15:8] <= rdata[7:0]; 
                READ_DATA_BYTE2: if (done) data_word[23:16] <= rdata[7:0]; 
                READ_DATA_BYTE3: if (done) data_word[31:24] <= rdata[7:0];
                READ_MEM: if (done) data_word <= rdata;
            endcase
        end
    end

    always_comb begin
        // Defaults
        next_state      = state; 
        next_mem_index  = mem_index;
        next_page_buffer_index = page_buffer_index;
        next_rst_core_n = rst_core_n;
        start           = 0;
        wdata           = '0;
        we              = 0; // read by default
        sram_access     = 0; // If 1 means access sram
        mem_addr_reg    = '0;
        generate_STA    = 0;
        generate_NACK   = 0;
        generate_STO    = 0;
        next_addr_pointer = addr_pointer;
        
        case(state)
            // Perform 24CS512 EEPROM Seqential Read
            WRITE_SLAVE_ADDR_W_BIT: begin       // Generate STA condition and send address with write bit,
                we      = 1; 
                wdata   = `EEPROM_ADDR_PLUS_W_BIT; 
                generate_STA = 1;
                if (!busy && !done) begin
                    start   = 1;  
                end else if (done) begin
                    next_state = WRITE_WORD_ADDR_BYTE0;            
                end
            end
            WRITE_WORD_ADDR_BYTE0: begin        // Set EEPROM address pointer to 0
                we      = 1;
                wdata   = addr_pointer[15:8];
                if (!busy && !done) begin
                    start   = 1;
                end else if (done) begin
                    next_state = WRITE_WORD_ADDR_BYTE1;            
                end
            end
            WRITE_WORD_ADDR_BYTE1: begin
                we      = 1;
                wdata   = addr_pointer[7:0];
                if (!busy && !done) begin
                    start   = 1;
                end else if (done) begin
                    if (mem_index > 0) begin    // if mem_index is more than zero – bootloader writes back to eeprom
                        next_state = READ_MEM;
                        if (mem_index == (`IMEM_SIZE+`DMEM_SIZE)) begin    //reset mem_index 
                            next_mem_index = 0;
                        end
                    end else begin
                        next_state = WRITE_SLAVE_ADDR_R_BIT;
                    end
                end
            end
            WRITE_SLAVE_ADDR_R_BIT: begin       // Generate STA condition and send address with read bit
                we      = 1;                     
                wdata   = `EEPROM_ADDR_PLUS_R_BIT;  
                generate_STA = 1;
                if (!busy && !done) begin
                    start   = 1;         
                end else if (done) begin
                    next_state = READ_DATA_BYTE0;            
                end
            end
            READ_DATA_BYTE0:    begin           // Start reading
                we = 0;  
                if (!busy && !done) begin
                    start   = 1;                              
                end else if (done) begin
                    // data_word[7:0]    = rdata[7:0]; 
                    next_state      = READ_DATA_BYTE1;            
                end
            end
            READ_DATA_BYTE1:    begin  
                we = 0;            
                if (!busy && !done) begin
                    start   = 1;
                end else if (done) begin
                    // data_word[15:8]    = rdata[7:0]; 
                    next_state      = READ_DATA_BYTE2;            
                end
            end
            READ_DATA_BYTE2:    begin    
                we = 0;          
                if (!busy && !done) begin
                    start   = 1;
                end else if (done) begin
                    // data_word[23:16]    = rdata[7:0]; 
                    next_state      = READ_DATA_BYTE3;            
                end
            end
            READ_DATA_BYTE3:    begin
                we = 0;
                generate_NACK = (last_read) ? 1 : 0;              
                if (!busy && !done) begin
                    start   = 1;
                end else if (done) begin
                    // data_word[31:24]    = rdata[7:0]; 
                    next_state      = WRITE_MEM;  
                end
            end

            WRITE_MEM: begin
                // Calculate SRAM address
                if(mem_index < `IMEM_SIZE)              // TODO maybe make mem_addr registered???   
                    mem_addr_reg = `IMEM_BASE_ADDR + mem_index;
                else
                    mem_addr_reg = `DMEM_BASE_ADDR + mem_index - `IMEM_SIZE;
                we      = 1; // 0 = read, 1 = write
                sram_access = 1; // Access sram
                wdata   = data_word;
                if (!busy && !done) begin
                    start   = 1;           
                end else if (done) begin
                    next_mem_index = mem_index + 4;
                    next_addr_pointer = `EEPROM_WRITE_ADDR;
`ifdef BOOT_WRITEBACK
                    next_state = (last_read) ? WRITE_SLAVE_ADDR_W_BIT : READ_DATA_BYTE0;
`else
                    next_state = (last_read) ? BOOT_FINISH : READ_DATA_BYTE0;
`endif            
                end   
            end
            
            READ_MEM: begin
                if(mem_index < `IMEM_SIZE)              // TODO maybe make mem_addr registered???   
                    mem_addr_reg = `IMEM_BASE_ADDR + mem_index;
                else
                    mem_addr_reg = `DMEM_BASE_ADDR + mem_index - `IMEM_SIZE;
                we      = 0; // 0 = read, 1 = write
                sram_access = 1; // Access sram
                if (!busy && !done) begin
                    start   = 1;           
                end else if (done) begin
                    next_mem_index = mem_index + 4;
                    next_state = WRITE_DATA_BYTE0;
                end
            end
            
            WRITE_DATA_BYTE0:    begin           // Start writing
                we = 1;                     
                wdata   = data_word[7:0];
                if (!busy && !done) 
                    start   = 1;                              
                else if (done)
                    next_state      = WRITE_DATA_BYTE1;
            end
            WRITE_DATA_BYTE1:    begin           // Start writing
                we = 1;                     
                wdata   = data_word[15:8];
                if (!busy && !done) 
                    start   = 1;                              
                else if (done)
                    next_state      = WRITE_DATA_BYTE2;
            end
            WRITE_DATA_BYTE2:    begin           // Start writing
                we = 1;                     
                wdata   = data_word[23:16];
                if (!busy && !done) 
                    start   = 1;                              
                else if (done)
                    next_state      = WRITE_DATA_BYTE3;
            end
            WRITE_DATA_BYTE3:    begin           // Start writing
                we = 1;                     
                wdata   = data_word[31:24];
                generate_STO = (page_buffer_index == ({{`EEPROM_PAGE_SIZE-2}{1'b1}})) ? 1'b1 : 1'b0;
                
                if (!busy && !done) 
                    start   = 1;                              
                else if (done)                    
                    if (mem_index == (`IMEM_SIZE+`DMEM_SIZE)) begin
                        next_state = BOOT_FINISH;
                    end else if (page_buffer_index == ({{`EEPROM_PAGE_SIZE-2}{1'b1}})) begin
                        next_page_buffer_index=0;
                        next_state = WRITE_SLAVE_ADDR_W_BIT;
                        next_addr_pointer = addr_pointer + {`EEPROM_PAGE_SIZE{1'b1}}+1;
                    end else begin
                        next_page_buffer_index = page_buffer_index + 1;
                        next_state = READ_MEM;
                    end
                
            end
            

            BOOT_FINISH: begin      // IDLE state after boot is finised
                next_rst_core_n = 1;
            end

        endcase
    end

endmodule
