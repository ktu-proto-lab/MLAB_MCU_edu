//*************************************************************************
//         SG13G2 1024x32bit SRAM memory with a wishbone slave wrappe
//*************************************************************************
//
// - Enables memory based on cyc and stb
// - Always writes through
// - Wishbone Stall and error signals are tied to low
//

module wb_sram_1024x32
(
    wb_if.slave wb
);

  parameter MEMInitFile = "";

  localparam size = 'h1000;                 // 1024x32 = 4096 bytes
  localparam addr_width = $clog2(size) - 2; // This will be 10 bits

  logic           valid;
  logic [9:0]     sram_addr;      // SRAM address
  logic           sram_me;        // Memory enable
  logic           sram_we;        // Write enable
  logic           sram_re;        // Read enable
  logic [31:0]    sram_bm;        // Write enable
  logic [31:0]    sram_wdata;     // SRAM write port
  logic [31:0]    sram_rdata;     // SRAM read port

  logic [3:0]     sram_be;        // SRAM byte enable

  /* Wishbone control */
  assign
     valid    = wb.cyc & wb.stb,
     wb.stall = 1'b0,
     wb.err   = 1'b0;

  always_ff @(posedge wb.clk or negedge wb.rst)
    if (!wb.rst)
      wb.ack <= 1'b0;
    else
      wb.ack <= valid & ~wb.stall;

  /* Translate logic */
  assign
    sram_addr    = wb.adr[addr_width+1:2], // Change to 32-bit word addressing for SRAM (by shifting wb.adr 2x left)
    sram_me      = valid,
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
  assign sram_re = sram_me;

  /* SRAM instance */
  RM_IHPSG13_1P_1024x32_c2_bm  #(
    // .MEMInitFile(MEMInitFile)
	) sram (
        .A_CLK        (wb.clk),
        .A_MEN        (sram_me),
        .A_WEN        (sram_we),   
        .A_REN        (sram_re),
        .A_ADDR       (sram_addr),  // 11 bit address
        .A_DIN        (sram_wdata),
        .A_DLY        (1'b1),       // Internal timing delay setting
        .A_DOUT       (sram_rdata),
        .A_BM         (sram_bm)
    );

endmodule
