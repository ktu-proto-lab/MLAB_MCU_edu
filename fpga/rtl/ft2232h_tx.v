// =============================================================================
// ft2232h_tx.v
// FT2232H Mini Module — TX-only (FPGA->PC) wrapper
// =============================================================================
//
// PURPOSE
//   Wraps the ftdi_245fifo_top IP (WangXuan95/FPGA-ftdi245fifo) and presents
//   a simple 8-bit FIFO write interface to the rest of the design.
//   The compression accelerator pushes bytes in; they come out on the PC
//   as a raw byte stream via the FT2232H USB bridge.
//
// DESIGN-SIDE INTERFACE (your clock domain, sys_clk)
//   - Write a byte : assert wr_en, put byte on wr_data
//   - Check space  : sample ~full before asserting wr_en
//   - That's it.   No clock-domain work needed on your side.
//
// FT2232H MINI MODULE CONNECTIONS
//   Channel A must be programmed to 245-sync-FIFO mode using FT_Prog.
//   See pin table below for the exact PYNQ-Z2 XDC constraints needed.
//
//   FT2232H pin  | Mini Module net | This module signal
//   -------------|-----------------|-------------------
//   ADBUS[7:0]   | CN2 pins 1–8    | ft_data[7:0]   (inout)
//   ACBUS0 (RXF#)| CN2 pin 9       | ft_rxf_n       (input)
//   ACBUS1 (TXE#)| CN2 pin 10      | ft_txe_n       (input)
//   ACBUS2 (RD#) | CN2 pin 11      | ft_rd_n        (output)
//   ACBUS3 (WR#) | CN2 pin 12      | ft_wr_n        (output)
//   ACBUS4 (SIWU)| CN2 pin 13      | ft_siwu_n      (output, tie 1)
//   ACBUS5 (CLK) | CN2 pin 14      | ft_clk         (input, 60 MHz)
//   ACBUS6 (OE#) | CN2 pin 15      | ft_oe_n        (output)
//   GND          | CN2 pin 16      | GND
//
// DEPENDENCY
//   Requires all .v files from RTL/ftdi_245fifo/ in the IP repository:
//     https://github.com/WangXuan95/FPGA-ftdi245fifo
//   Add these files to your Vivado project alongside this wrapper.
//
// PARAMETERS
//   TX_DEPTH_EXP : log2 of the internal TX buffer depth (default 10 = 1024 B)
//                  Increase to 11 or 12 if you want a deeper buffer.
//
// =============================================================================

module ft2232h_tx #(
    parameter TX_DEPTH_EXP = 10   // TX buffer depth = 2^TX_DEPTH_EXP bytes
) (
    // -------------------------------------------------------------------------
    // Design-side interface  (sys_clk domain)
    // -------------------------------------------------------------------------
    input  wire       sys_clk,    // Your FPGA system clock (e.g. 50 MHz)
    input  wire       sys_rst_n,  // Active-low synchronous reset

    // Write port — push one byte per cycle when wr_en=1 and full=0
    input  wire       wr_en,      // Write enable
    input  wire [7:0] wr_data,    // Byte to send
    output wire       full,       // High when internal TX buffer is full
                                  // Do NOT assert wr_en when full=1

    // -------------------------------------------------------------------------
    // FT2232H chip interface  (ft_clk domain, 60 MHz from chip)
    // -------------------------------------------------------------------------
    input  wire       ft_clk,     // 60 MHz CLKOUT from FT2232H Channel A
    inout  wire [7:0] ft_data,    // Bidirectional data bus ADBUS[7:0]
    input  wire       ft_rxf_n,   // RXF# — data available from PC (unused here)
    input  wire       ft_txe_n,   // TXE# — OK to write to chip when low
    output wire       ft_rd_n,    // RD#  — keep high (TX-only)
    output wire       ft_wr_n,    // WR#  — controlled by IP
    output wire       ft_oe_n,    // OE#  — controlled by IP
    output wire       ft_siwu_n   // SIWU# — tie high per datasheet
);

    // -------------------------------------------------------------------------
    // Tie SIWU# high (send-immediate / wake-up, not needed here)
    // -------------------------------------------------------------------------
    assign ft_siwu_n = 1'b1;

    // -------------------------------------------------------------------------
    // AXI-Stream TX signals (design -> IP -> FT2232H -> PC)
    // -------------------------------------------------------------------------
    wire       tx_tready;   // IP is ready to accept a byte
    wire       tx_tvalid;   // We want to send a byte
    wire [7:0] tx_tdata;    // The byte
    wire       tx_tkeep;    // Byte enable: always 1 for 8-bit single-byte mode
    wire       tx_tlast;    // Packet last: tie high so each byte is sent immediately

    // -------------------------------------------------------------------------
    // AXI-Stream RX signals (PC -> FT2232H -> IP -> design, unused)
    // We have to wire up the RX AXI-stream port of the IP even though we
    // don't use it.  Tie rx_tready=1 so the IP can drain any bytes the PC
    // sends, preventing its RX buffer from filling and blocking TX.
    // -------------------------------------------------------------------------
    wire       rx_tvalid;
    wire [7:0] rx_tdata;
    wire       rx_tkeep;
    wire       rx_tlast;

    // -------------------------------------------------------------------------
    // Map design-side FIFO write port onto AXI-stream TX
    //
    // The IP's tx_tready is the "not-full" signal from AXI-stream perspective.
    // We expose it directly as the full flag (inverted).
    // tx_tvalid goes high when the user asserts wr_en (and the IP is ready).
    // tx_tlast is tied high so each individual byte transfer is flushed
    // immediately rather than waiting to fill a wider word — important for
    // keeping latency low in a streaming pipeline.
    // -------------------------------------------------------------------------
    assign full      = ~tx_tready;
    assign tx_tvalid = wr_en & tx_tready;  // Only commit transfer when ready
    assign tx_tdata  = wr_data;
    assign tx_tkeep  = 1'b1;
    assign tx_tlast  = 1'b1;

    // -------------------------------------------------------------------------
    // Instantiate ftdi_245fifo_top from WangXuan95/FPGA-ftdi245fifo
    //
    // Parameters for FT2232H:
    //   CHIP_TYPE = "FTx232H"   (covers FT232H and FT2232H, 8-bit data bus)
    //   TX_EW = 0               (TX AXI-stream width: 2^0 = 1 byte)
    //   TX_EA = TX_DEPTH_EXP    (TX buffer depth: 2^TX_DEPTH_EXP)
    //   RX_EW = 0               (RX AXI-stream width: 1 byte)
    //   RX_EA = 6               (RX buffer depth: 64 bytes — minimal, TX only)
    // -------------------------------------------------------------------------
    ftdi_245fifo_top #(
        .CHIP_TYPE ( "FTx232H"    ),
        .TX_EW     ( 0            ),
        .TX_EA     ( TX_DEPTH_EXP ),
        .RX_EW     ( 0            ),
        .RX_EA     ( 6            )   // 64-byte RX buffer, drain from PC
    ) u_ftdi (
        // Global reset (async)
        .rstn_async   ( sys_rst_n   ),

        // FT2232H chip pins
        .ftdi_clk     ( ft_clk      ),
        .ftdi_rxf_n   ( ft_rxf_n    ),
        .ftdi_txe_n   ( ft_txe_n    ),
        .ftdi_oe_n    ( ft_oe_n     ),
        .ftdi_rd_n    ( ft_rd_n     ),
        .ftdi_wr_n    ( ft_wr_n     ),
        .ftdi_data    ( ft_data     ),
        .ftdi_be      (             ),  // FT2232H has no BE pins, leave open

        // TX AXI-stream (design -> PC)
        .tx_clk       ( sys_clk     ),
        .tx_tready    ( tx_tready   ),
        .tx_tvalid    ( tx_tvalid   ),
        .tx_tdata     ( tx_tdata    ),
        .tx_tkeep     ( tx_tkeep    ),
        .tx_tlast     ( tx_tlast    ),

        // RX AXI-stream (PC -> design, drained and discarded)
        .rx_clk       ( sys_clk     ),
        .rx_tready    ( 1'b1        ),
        .rx_tvalid    ( rx_tvalid   ),
        .rx_tdata     ( rx_tdata    ),
        .rx_tkeep     ( rx_tkeep    ),
        .rx_tlast     ( rx_tlast    )
    );

endmodule