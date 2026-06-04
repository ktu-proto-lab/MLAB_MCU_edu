// =============================================================================
// ft2232h_tx_usage_example.v
// Shows how to connect the compression accelerator output to ft2232h_tx.
// This is NOT a complete top-level — just an integration reference.
// =============================================================================

// ---- Inside your SoC top-level ----

// Compression accelerator produces bytes one at a time.
// It should check `ft_full` before asserting `comp_byte_valid`.
// If `ft_full` is high, it must stall (backpressure).

wire        comp_byte_valid;   // from compression accelerator: 1 = byte ready
wire [7:0]  comp_byte_data;    // from compression accelerator: byte value
wire        ft_full;           // from ft2232h_tx: stall when high

// Compression accelerator should implement backpressure like this:
//   always @(posedge sys_clk) begin
//       if (!ft_full && data_available) begin
//           // drive comp_byte_valid = 1, comp_byte_data = next_byte
//           // advance internal read pointer
//       end
//   end

ft2232h_tx #(
    .TX_DEPTH_EXP ( 10 )    // 1024-byte internal TX buffer
) u_ft2232h (
    // System clock and reset
    .sys_clk    ( sys_clk       ),
    .sys_rst_n  ( sys_rst_n     ),

    // From compression accelerator
    .wr_en      ( comp_byte_valid & ~ft_full ),
    .wr_data    ( comp_byte_data             ),
    .full       ( ft_full                    ),

    // To FT2232H Mini Module — constrain these in your XDC
    .ft_clk     ( ft_clk        ),
    .ft_data    ( ft_data       ),
    .ft_rxf_n   ( ft_rxf_n      ),
    .ft_txe_n   ( ft_txe_n      ),
    .ft_rd_n    ( ft_rd_n       ),
    .ft_wr_n    ( ft_wr_n       ),
    .ft_oe_n    ( ft_oe_n       ),
    .ft_siwu_n  ( ft_siwu_n     )
);

// =============================================================================
// XDC constraints (PYNQ-Z2, assuming Pmod JA for the FT2232H Mini Module)
// Adjust pin numbers to match your actual wiring.
// =============================================================================
//
// ## FT2232H 60 MHz clock — must be declared as a primary clock
// set_property PACKAGE_PIN <PIN> [get_ports ft_clk]
// set_property IOSTANDARD LVCMOS33 [get_ports ft_clk]
// create_clock -period 16.667 -name ft_clk [get_ports ft_clk]
//
// ## Declare ft_clk and sys_clk as asynchronous clock groups
// set_clock_groups -asynchronous -group [get_clocks sys_clk] \
//                                -group [get_clocks ft_clk]
//
// ## Data bus (bidirectional — needs IOBUF, handled inside IP)
// set_property PACKAGE_PIN <PIN> [get_ports {ft_data[0]}]
// set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[0]}]
// ... repeat for ft_data[1] through ft_data[7] ...
//
// ## Control signals
// set_property PACKAGE_PIN <PIN> [get_ports ft_rxf_n]
// set_property PACKAGE_PIN <PIN> [get_ports ft_txe_n]
// set_property PACKAGE_PIN <PIN> [get_ports ft_rd_n]
// set_property PACKAGE_PIN <PIN> [get_ports ft_wr_n]
// set_property PACKAGE_PIN <PIN> [get_ports ft_oe_n]
// set_property PACKAGE_PIN <PIN> [get_ports ft_siwu_n]
// set_property IOSTANDARD LVCMOS33 [get_ports ft_*]