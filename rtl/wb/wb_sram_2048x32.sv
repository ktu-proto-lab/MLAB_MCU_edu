//*************************************************************************
//         SG13G2 2048x32bit SRAM memory with a wishbone slave wrappe
//*************************************************************************
//
// - Two 1024x32bit memories tied to one arbitered by 12th address bit
// - Enables memory based on cyc and stb
// - Always writes through
// - Wishbone Stall and error signals are tied to low
//

module wb_sram_2048x32
(
    wb_if.slave wb
);

  parameter MEMInitFile_1 = "";
  parameter MEMInitFile_2 = "";

  localparam size = 'h1000;                             // 1024x32 = 4096 bytes
  localparam addr_width = $clog2(size) - 2;             // This will be 10 bits

  logic           valid;
  logic [9:0]     sram_addr;                            // SRAM address
  logic           sram1_me, sram2_me;                   // Memory enable
  logic           sram_we;                              // Write enable
  logic           sram_re;                              // Read enable
  logic [31:0]    sram_bm;                              // Write enable
  logic [31:0]    sram_wdata;                           // SRAM write port
  logic [31:0]    sram_rdata, sram1_rdata, sram2_rdata; // SRAM read port

  logic [3:0]     sram_be;                              // SRAM byte enable

  logic           sram_sel;           // One cycle delayed address 12th bit

  /* Arbiter between memories based on 12th address bit */
  assign sram2_me = wb.adr[12] & valid; // If bit12 is set means sram2 access (starting at address 0d4096)
  assign sram1_me = !sram2_me & valid;  // Invert sram2_me, but only if wb request present
  
  // Mux rdata based on address
  assign sram_rdata = sram_sel ? sram2_rdata : sram1_rdata;

  // All inputs to both SRAMs are shared

  /* Wishbone control */
  assign
    valid    = wb.cyc & wb.stb,
    wb.stall = 1'b0,
    wb.err   = 1'b0;

  always_ff @(posedge wb.clk or negedge wb.rst)
     if (!wb.rst) begin
       wb.ack <= 1'b0;
       sram_sel <= 1'b0;
     end
     else begin
       wb.ack <= valid & ~wb.stall;
       sram_sel <= wb.adr[12]; // Saves address 12th bit (aka. 4KB memory select bit)
     end

  /* Translate logic */
  assign
    sram_addr    = wb.adr[addr_width+1:2], // Change to 32-bit word addressing for SRAM
    sram_we      = wb.we,
    sram_be      = {4{wb.we}} & wb.sel,
    // Convert byte enable to bit mask3
    sram_bm      = {{8{sram_be[3]}}, {8{sram_be[2]}}, {8{sram_be[1]}}, {8{sram_be[0]}}}, 
`ifdef NO_MODPORT_EXPRESSIONS
    sram_wdata   = wb.dat_m,
    wb.dat_s     = sram_rdata;
`else
    sram_wdata   = wb.dat_i, 
    wb.dat_o     = sram_rdata;
`endif
  // Always generate SRAM RE on access (will always write-through)
  assign sram_re = valid;

  /* SRAM instances */
  RM_IHPSG13_1P_1024x32_c2_bm_bist  #(
    .MEMInitFile(MEMInitFile_1)
  ) sram1 (
        .A_CLK        (wb.clk),
        .A_MEN        (sram1_me),
        .A_WEN        (sram_we),   
        .A_REN        (sram_re),
        .A_ADDR       (sram_addr),  // 10 bit address
        .A_DIN        (sram_wdata),
        .A_DLY        (1'b1),       // Internal timing delay setting
        .A_DOUT       (sram1_rdata),
        .A_BM         (sram_bm),
        .A_BIST_CLK   ('0),
        .A_BIST_EN    ('0),
        .A_BIST_MEN   ('0),
        .A_BIST_WEN   ('0),
        .A_BIST_REN   ('0),
        .A_BIST_ADDR  ('0),
        .A_BIST_DIN   ('0),
        .A_BIST_BM    ('0)   
    );

  RM_IHPSG13_1P_1024x32_c2_bm_bist  #(
    .MEMInitFile(MEMInitFile_2)
  ) sram2 (
        .A_CLK        (wb.clk),
        .A_MEN        (sram2_me),
        .A_WEN        (sram_we),   
        .A_REN        (sram_re),
        .A_ADDR       (sram_addr),  
        .A_DIN        (sram_wdata),
        .A_DLY        (1'b1),      
        .A_DOUT       (sram2_rdata),
        .A_BM         (sram_bm),
        .A_BIST_CLK   ('0),
        .A_BIST_EN    ('0),
        .A_BIST_MEN   ('0),
        .A_BIST_WEN   ('0),
        .A_BIST_REN   ('0),
        .A_BIST_ADDR  ('0),
        .A_BIST_DIN   ('0),
        .A_BIST_BM    ('0)   
    );
endmodule
