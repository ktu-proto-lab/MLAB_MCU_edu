/*
  Contributors:
    * Dovydas Liutkus
  Description:
    * Vendored copy of WangXuan95 ftdi_245fifo_top with a TX byte-loss fix
    * Renamed to ftdi_245fifo_top_txfix so it can coexist with the unmodified
    * submodule sources in the same project (all submodules are reused).
    *
    * BUG BEING FIXED (measured on Nexys A7 + FT2232H Mini Module over
    * breadboard wires, 2026-07-07):
    *   The FT2232H deasserts TXE# when it commits each 512-byte USB packet.
    *   The FSM pops exactly ONE byte more from the TX FIFO than the chip
    *   accepts. The FSM re-presents its in-flight byte after the pause, but
    *   the extra popped byte is gone: exactly 1 byte lost per 512-byte USB
    *   packet, at any data rate.
    *
    * FIX: ftdi_tx_unpop, inserted between the chip-side TX FIFO and the FSM.
    *   It remembers the last byte handed to the FSM; when TXE# rises and a
    *   byte was popped in the immediately preceding cycle, that byte is
    *   deterministically doomed - it is re-injected ahead of the stream.
    *
    * NOTE: this compensates a MEASURED, deterministic one-byte overshoot.
    *   If the board timing changes the overshoot may disappear, and this patch would then
    *   DUPLICATE one byte per packet instead. Re-run
    *   ftdi_test/python/ftdi_rx_verify.py after any hardware/timing change;
    *   set REWIND=0 to disable the patch without rewiring.
*/

//-----------------------------------------------------------------------------------------------------------------------------
// TX un-pop / replay stage
//-----------------------------------------------------------------------------------------------------------------------------
module ftdi_tx_unpop #(
    parameter DW     = 9,      // {tkeep, tdata} width
    parameter REWIND = 1       // 0 = plain pass-through (patch disabled)
) (
    input  wire          rstn,
    input  wire          clk,          // ftdi_clk domain
    input  wire          ftdi_txe_n,   // raw TXE# as seen by the FPGA
    // from TX FIFO
    output wire          i_rdy,
    input  wire          i_en,
    input  wire [DW-1:0] i_data,
    // to FSM
    input  wire          o_rdy,
    output wire          o_en,
    output wire [DW-1:0] o_data
);

reg           txe_n_d   = 1'b1;
reg           popped_d  = 1'b0;   // a byte was handed to the FSM in the previous cycle
reg           replay    = 1'b0;
reg [DW-1:0]  last_data = {DW{1'b0}};

wire pop      = o_en & o_rdy;
wire txe_rise = ftdi_txe_n & ~txe_n_d;

assign o_en   = replay ? 1'b1      : i_en;
assign o_data = replay ? last_data : i_data;
assign i_rdy  = o_rdy & ~replay;

generate if (REWIND) begin

    always @ (posedge clk or negedge rstn)
        if (~rstn) begin
            txe_n_d   <= 1'b1;
            popped_d  <= 1'b0;
            replay    <= 1'b0;
            last_data <= {DW{1'b0}};
        end else begin
            txe_n_d  <= ftdi_txe_n;
            popped_d <= pop;
            if (pop)
                last_data <= o_data;
            if (txe_rise & popped_d & ~replay)
                replay <= 1'b1;          // byte popped last cycle was rejected by the chip
            else if (replay & pop)
                replay <= 1'b0;          // replayed byte handed over again
        end

end endgenerate

endmodule




//-----------------------------------------------------------------------------------------------------------------------------
// ftdi_245fifo_top with ftdi_tx_unpop inserted (otherwise identical to upstream)
//-----------------------------------------------------------------------------------------------------------------------------
module ftdi_245fifo_top_txfix #(
    parameter  TX_EW      = 2 ,          // TX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit ...
    parameter  TX_EA      = 10,          // TX FIFO depth = 2^TX_EA
    parameter  RX_EW      = 2 ,          // RX data stream width
    parameter  RX_EA      = 10,          // RX FIFO depth = 2^RX_EA
    parameter  CHIP_TYPE  = "FTx232H",   // "FTx232H", "FT600", "FT601"
    parameter  SIMULATION = 0            // kept for interface compatibility (asserts omitted)
) (
    input  wire                    rstn_async,
    // user send interface (FPGA -> USB -> PC), AXI-stream slave
    input  wire                    tx_clk,
    output wire                    tx_tready,
    input  wire                    tx_tvalid,
    input  wire   [(8<<TX_EW)-1:0] tx_tdata,
    input  wire   [(1<<TX_EW)-1:0] tx_tkeep,
    input  wire                    tx_tlast,
    // user recv interface (PC -> USB -> FPGA), AXI-stream master
    input  wire                    rx_clk,
    input  wire                    rx_tready,
    output wire                    rx_tvalid,
    output wire   [(8<<RX_EW)-1:0] rx_tdata,
    output wire   [(1<<RX_EW)-1:0] rx_tkeep,
    output wire                    rx_tlast,
    // FTDI 245FIFO interface
    input  wire                    ftdi_clk,
    input  wire                    ftdi_rxf_n,
    input  wire                    ftdi_txe_n,
    output wire                    ftdi_oe_n,
    output wire                    ftdi_rd_n,
    output wire                    ftdi_wr_n,
    inout       [(8<<((CHIP_TYPE=="FT601") ? 2 : (CHIP_TYPE=="FT600") ? 1 : 0))-1:0] ftdi_data,
    inout       [(1<<((CHIP_TYPE=="FT601") ? 2 : (CHIP_TYPE=="FT600") ? 1 : 0))-1:0] ftdi_be
);


localparam  CHIP_EW               = (CHIP_TYPE=="FT601") ? 2 : (CHIP_TYPE=="FT600") ? 1 : 0;
localparam  CHIP_DRIVE_AT_NEGEDGE = 0;                   // same as upstream for FTx232H


//-----------------------------------------------------------------------------------------------------------------------------
// tri-state driver for inout pins
//-----------------------------------------------------------------------------------------------------------------------------
wire                    ftdi_master_oe;
wire [(8<<CHIP_EW)-1:0] ftdi_data_out;
wire [(1<<CHIP_EW)-1:0] ftdi_be_out;

assign ftdi_data = ftdi_master_oe ? ftdi_data_out : {(8<<CHIP_EW){1'bZ}};
assign ftdi_be   = ftdi_master_oe ? ftdi_be_out   : {(1<<CHIP_EW){1'bZ}};


//-----------------------------------------------------------------------------------------------------------------------------
// generate reset
//-----------------------------------------------------------------------------------------------------------------------------
wire rstn_ftdi;
wire rstn_tx;
wire rstn_rx;

resetn_sync u_resetn_sync_usb (rstn_async, ftdi_clk, rstn_ftdi);
resetn_sync u_resetn_sync_tx  (rstn_async,  tx_clk , rstn_tx );
resetn_sync u_resetn_sync_rx  (rstn_async,  rx_clk , rstn_rx );


//-----------------------------------------------------------------------------------------------------------------------------
// internal streams
//-----------------------------------------------------------------------------------------------------------------------------
localparam TX_FIFO_EW = (TX_EW > CHIP_EW) ? TX_EW : CHIP_EW;
localparam RX_FIFO_EW = (RX_EW > CHIP_EW) ? RX_EW : CHIP_EW;

wire                       tx_a_tready , tx_a_tvalid;
wire      [(8<<TX_EW)-1:0] tx_a_tdata;
wire      [(1<<TX_EW)-1:0] tx_a_tkeep;
wire                       tx_a_tlast;

wire                       tx_b_tready , tx_b_tvalid;
wire      [(8<<TX_EW)-1:0] tx_b_tdata;
wire      [(1<<TX_EW)-1:0] tx_b_tkeep;
wire                       tx_b_tlast;

wire                       tx_c_tready , tx_c_tvalid;
wire [(8<<TX_FIFO_EW)-1:0] tx_c_tdata;
wire [(1<<TX_FIFO_EW)-1:0] tx_c_tkeep;

wire                       tx_d_tready , tx_d_tvalid;
wire [(8<<TX_FIFO_EW)-1:0] tx_d_tdata;
wire [(1<<TX_FIFO_EW)-1:0] tx_d_tkeep;

wire                       tx_e_tready , tx_e_tvalid;
wire [(8<<TX_FIFO_EW)-1:0] tx_e_tdata;
wire [(1<<TX_FIFO_EW)-1:0] tx_e_tkeep;

wire                       tx_f_tready , tx_f_tvalid;
wire    [(8<<CHIP_EW)-1:0] tx_f_tdata;
wire    [(1<<CHIP_EW)-1:0] tx_f_tkeep;

wire                       tx_g_tready , tx_g_tvalid;
wire    [(8<<CHIP_EW)-1:0] tx_g_tdata;
wire    [(1<<CHIP_EW)-1:0] tx_g_tkeep;

wire                       tx_h_tready , tx_h_tvalid;
wire    [(8<<CHIP_EW)-1:0] tx_h_tdata;
wire    [(1<<CHIP_EW)-1:0] tx_h_tkeep;

// NEW: stream between the unpop stage and the FSM
wire                       tx_i_tready , tx_i_tvalid;
wire    [(8<<CHIP_EW)-1:0] tx_i_tdata;
wire    [(1<<CHIP_EW)-1:0] tx_i_tkeep;

wire                       rx_a_almost_full , rx_a_tvalid;
wire    [(8<<CHIP_EW)-1:0] rx_a_tdata;
wire    [(1<<CHIP_EW)-1:0] rx_a_tkeep;
wire                       rx_a_tlast;

wire                       rx_b_tready , rx_b_tvalid;
wire    [(8<<CHIP_EW)-1:0] rx_b_tdata;
wire    [(1<<CHIP_EW)-1:0] rx_b_tkeep;
wire                       rx_b_tlast;

wire                       rx_c_tready , rx_c_tvalid;
wire    [(8<<CHIP_EW)-1:0] rx_c_tdata;
wire    [(1<<CHIP_EW)-1:0] rx_c_tkeep;
wire                       rx_c_tlast;

wire                       rx_d_tready , rx_d_tvalid;
wire [(8<<RX_FIFO_EW)-1:0] rx_d_tdata;
wire [(1<<RX_FIFO_EW)-1:0] rx_d_tkeep;
wire                       rx_d_tlast;

wire                       rx_e_tready , rx_e_tvalid;
wire [(8<<RX_FIFO_EW)-1:0] rx_e_tdata;
wire [(1<<RX_FIFO_EW)-1:0] rx_e_tkeep;
wire                       rx_e_tlast;

wire                       rx_f_tready , rx_f_tvalid;
wire      [(8<<RX_EW)-1:0] rx_f_tdata;
wire      [(1<<RX_EW)-1:0] rx_f_tkeep;
wire                       rx_f_tlast;


//-----------------------------------------------------------------------------------------------------------------------------
// TX chain (identical to upstream until tx_h)
//-----------------------------------------------------------------------------------------------------------------------------
fifo2 # (
    .DW                  ( 1 + (1<<TX_EW) + (8<<TX_EW)           )
) u_tx_fifo2_1 (
    .rstn                ( rstn_tx                               ),
    .clk                 ( tx_clk                                ),
    .i_rdy               ( tx_tready                             ),
    .i_en                ( tx_tvalid                             ),
    .i_data              ( {tx_tlast, tx_tkeep, tx_tdata}        ),
    .o_rdy               ( tx_a_tready                           ),
    .o_en                ( tx_a_tvalid                           ),
    .o_data              ( {tx_a_tlast, tx_a_tkeep, tx_a_tdata}  )
);

axi_stream_packing #(
    .EW                  ( TX_EW                                 ),
    .SUBMIT_IMMEDIATE    ( TX_EW >= TX_FIFO_EW                   )
) u_tx_packing (
    .rstn                ( rstn_tx                               ),
    .clk                 ( tx_clk                                ),
    .i_tready            ( tx_a_tready                           ),
    .i_tvalid            ( tx_a_tvalid                           ),
    .i_tdata             ( tx_a_tdata                            ),
    .i_tkeep             ( tx_a_tkeep                            ),
    .i_tlast             ( tx_a_tlast                            ),
    .o_tready            ( tx_b_tready                           ),
    .o_tvalid            ( tx_b_tvalid                           ),
    .o_tdata             ( tx_b_tdata                            ),
    .o_tkeep             ( tx_b_tkeep                            ),
    .o_tlast             ( tx_b_tlast                            )
);

axi_stream_resizing #(
    .IEW                 ( TX_EW                                 ),
    .OEW                 ( TX_FIFO_EW                            )
) u_tx_upsizing (
    .rstn                ( rstn_tx                               ),
    .clk                 ( tx_clk                                ),
    .i_tready            ( tx_b_tready                           ),
    .i_tvalid            ( tx_b_tvalid                           ),
    .i_tdata             ( tx_b_tdata                            ),
    .i_tkeep             ( tx_b_tkeep                            ),
    .i_tlast             ( tx_b_tlast                            ),
    .o_tready            ( tx_c_tready                           ),
    .o_tvalid            ( tx_c_tvalid                           ),
    .o_tdata             ( tx_c_tdata                            ),
    .o_tkeep             ( tx_c_tkeep                            ),
    .o_tlast             (                                       )
);

fifo_async #(
    .DW                  ( (1<<TX_FIFO_EW) + (8<<TX_FIFO_EW)     ),
    .EA                  ( TX_EA                                 )
) u_tx_fifo_async (
    .i_rstn              ( rstn_tx                               ),
    .i_clk               ( tx_clk                                ),
    .i_tready            ( tx_c_tready                           ),
    .i_tvalid            ( tx_c_tvalid                           ),
    .i_tdata             ( {tx_c_tkeep, tx_c_tdata}              ),
    .o_rstn              ( rstn_ftdi                             ),
    .o_clk               ( ftdi_clk                              ),
    .o_tready            ( tx_d_tready                           ),
    .o_tvalid            ( tx_d_tvalid                           ),
    .o_tdata             ( {tx_d_tkeep, tx_d_tdata}              )
);

fifo2 # (
    .DW                  ( (1<<TX_FIFO_EW) + (8<<TX_FIFO_EW)     )
) u_tx_fifo2_2 (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_rdy               ( tx_d_tready                           ),
    .i_en                ( tx_d_tvalid                           ),
    .i_data              ( {tx_d_tkeep, tx_d_tdata}              ),
    .o_rdy               ( tx_e_tready                           ),
    .o_en                ( tx_e_tvalid                           ),
    .o_data              ( {tx_e_tkeep, tx_e_tdata}              )
);

axi_stream_resizing #(
    .IEW                 ( TX_FIFO_EW                            ),
    .OEW                 ( CHIP_EW                               )
) u_tx_downsizing (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_tready            ( tx_e_tready                           ),
    .i_tvalid            ( tx_e_tvalid                           ),
    .i_tdata             ( tx_e_tdata                            ),
    .i_tkeep             ( tx_e_tkeep                            ),
    .i_tlast             ( 1'b0                                  ),
    .o_tready            ( tx_f_tready                           ),
    .o_tvalid            ( tx_f_tvalid                           ),
    .o_tdata             ( tx_f_tdata                            ),
    .o_tkeep             ( tx_f_tkeep                            ),
    .o_tlast             (                                       )
);

fifo_delay_submit #(
    .DW                  ( (1<<CHIP_EW) + (8<<CHIP_EW)           )
) u_tx_fifo_delay_submit (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_rdy               ( tx_f_tready                           ),
    .i_en                ( tx_f_tvalid                           ),
    .i_data              ( {tx_f_tkeep, tx_f_tdata}              ),
    .o_rdy               ( tx_g_tready                           ),
    .o_en                ( tx_g_tvalid                           ),
    .o_data              ( {tx_g_tkeep, tx_g_tdata}              )
);

fifo2 # (
    .DW                  ( (1<<CHIP_EW) + (8<<CHIP_EW)           )
) u_tx_fifo2_3 (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_rdy               ( tx_g_tready                           ),
    .i_en                ( tx_g_tvalid                           ),
    .i_data              ( {tx_g_tkeep, tx_g_tdata}              ),
    .o_rdy               ( tx_h_tready                           ),
    .o_en                ( tx_h_tvalid                           ),
    .o_data              ( {tx_h_tkeep, tx_h_tdata}              )
);


//-----------------------------------------------------------------------------------------------------------------------------
// NEW: un-pop stage compensating the one-byte overshoot at TXE# rise
//-----------------------------------------------------------------------------------------------------------------------------
ftdi_tx_unpop #(
    .DW                  ( (1<<CHIP_EW) + (8<<CHIP_EW)           ),
    .REWIND              ( 1                                     )
) u_tx_unpop (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .ftdi_txe_n          ( ftdi_txe_n                            ),
    .i_rdy               ( tx_h_tready                           ),
    .i_en                ( tx_h_tvalid                           ),
    .i_data              ( {tx_h_tkeep, tx_h_tdata}              ),
    .o_rdy               ( tx_i_tready                           ),
    .o_en                ( tx_i_tvalid                           ),
    .o_data              ( {tx_i_tkeep, tx_i_tdata}              )
);


ftdi_245fifo_fsm #(
    .CHIP_EW             ( CHIP_EW                               ),
    .CHIP_DRIVE_AT_NEGEDGE ( CHIP_DRIVE_AT_NEGEDGE               )
) u_ftdi_245fifo_fsm (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .tx_tready           ( tx_i_tready                           ),
    .tx_tvalid           ( tx_i_tvalid                           ),
    .tx_tdata            ( tx_i_tdata                            ),
    .tx_tkeep            ( tx_i_tkeep                            ),
    .rx_almost_full      ( rx_a_almost_full                      ),
    .rx_tvalid           ( rx_a_tvalid                           ),
    .rx_tdata            ( rx_a_tdata                            ),
    .rx_tkeep            ( rx_a_tkeep                            ),
    .rx_tlast            ( rx_a_tlast                            ),
    .ftdi_rxf_n          ( ftdi_rxf_n                            ),
    .ftdi_txe_n          ( ftdi_txe_n                            ),
    .ftdi_oe_n           ( ftdi_oe_n                             ),
    .ftdi_rd_n           ( ftdi_rd_n                             ),
    .ftdi_wr_n           ( ftdi_wr_n                             ),
    .ftdi_master_oe      ( ftdi_master_oe                        ),
    .ftdi_data_out       ( ftdi_data_out                         ),
    .ftdi_be_out         ( ftdi_be_out                           ),
    .ftdi_data_in        ( ftdi_data                             ),
    .ftdi_be_in          ( ftdi_be                               )
);


//-----------------------------------------------------------------------------------------------------------------------------
// RX chain (identical to upstream)
//-----------------------------------------------------------------------------------------------------------------------------
fifo4 # (
    .DW                  ( 1 + (1<<CHIP_EW) + (8<<CHIP_EW)       )
) u_rx_fifo4 (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_almost_full       ( rx_a_almost_full                      ),
    .i_rdy               (                                       ),
    .i_en                ( rx_a_tvalid                           ),
    .i_data              ( {rx_a_tlast, rx_a_tkeep, rx_a_tdata}  ),
    .o_rdy               ( rx_b_tready                           ),
    .o_en                ( rx_b_tvalid                           ),
    .o_data              ( {rx_b_tlast, rx_b_tkeep, rx_b_tdata}  )
);

axi_stream_packing #(
    .EW                  ( CHIP_EW                               )
) u_rx_packing (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_tready            ( rx_b_tready                           ),
    .i_tvalid            ( rx_b_tvalid                           ),
    .i_tdata             ( rx_b_tdata                            ),
    .i_tkeep             ( rx_b_tkeep                            ),
    .i_tlast             ( rx_b_tlast                            ),
    .o_tready            ( rx_c_tready                           ),
    .o_tvalid            ( rx_c_tvalid                           ),
    .o_tdata             ( rx_c_tdata                            ),
    .o_tkeep             ( rx_c_tkeep                            ),
    .o_tlast             ( rx_c_tlast                            )
);

axi_stream_resizing #(
    .IEW                 ( CHIP_EW                               ),
    .OEW                 ( RX_FIFO_EW                            )
) u_rx_upsizing (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_tready            ( rx_c_tready                           ),
    .i_tvalid            ( rx_c_tvalid                           ),
    .i_tdata             ( rx_c_tdata                            ),
    .i_tkeep             ( rx_c_tkeep                            ),
    .i_tlast             ( rx_c_tlast                            ),
    .o_tready            ( rx_d_tready                           ),
    .o_tvalid            ( rx_d_tvalid                           ),
    .o_tdata             ( rx_d_tdata                            ),
    .o_tkeep             ( rx_d_tkeep                            ),
    .o_tlast             ( rx_d_tlast                            )
);

fifo_async #(
    .DW                  ( 1 + (1<<RX_FIFO_EW) + (8<<RX_FIFO_EW) ),
    .EA                  ( RX_EA                                 )
) u_rx_fifo_async (
    .i_rstn              ( rstn_ftdi                             ),
    .i_clk               ( ftdi_clk                              ),
    .i_tready            ( rx_d_tready                           ),
    .i_tvalid            ( rx_d_tvalid                           ),
    .i_tdata             ( {rx_d_tlast, rx_d_tkeep, rx_d_tdata}  ),
    .o_rstn              ( rstn_rx                               ),
    .o_clk               ( rx_clk                                ),
    .o_tready            ( rx_e_tready                           ),
    .o_tvalid            ( rx_e_tvalid                           ),
    .o_tdata             ( {rx_e_tlast, rx_e_tkeep, rx_e_tdata}  )
);

axi_stream_resizing #(
    .IEW                 ( RX_FIFO_EW                            ),
    .OEW                 ( RX_EW                                 )
) u_rx_downsizing (
    .rstn                ( rstn_rx                               ),
    .clk                 ( rx_clk                                ),
    .i_tready            ( rx_e_tready                           ),
    .i_tvalid            ( rx_e_tvalid                           ),
    .i_tdata             ( rx_e_tdata                            ),
    .i_tkeep             ( rx_e_tkeep                            ),
    .i_tlast             ( rx_e_tlast                            ),
    .o_tready            ( rx_f_tready                           ),
    .o_tvalid            ( rx_f_tvalid                           ),
    .o_tdata             ( rx_f_tdata                            ),
    .o_tkeep             ( rx_f_tkeep                            ),
    .o_tlast             ( rx_f_tlast                            )
);

fifo2 #(
    .DW                  ( 1 + (1<<RX_EW) + (8<<RX_EW)           )
) u_rx_fifo2 (
    .rstn                ( rstn_rx                               ),
    .clk                 ( rx_clk                                ),
    .i_rdy               ( rx_f_tready                           ),
    .i_en                ( rx_f_tvalid                           ),
    .i_data              ( {rx_f_tlast, rx_f_tkeep, rx_f_tdata}  ),
    .o_rdy               ( rx_tready                             ),
    .o_en                ( rx_tvalid                             ),
    .o_data              ( {rx_tlast, rx_tkeep, rx_tdata}        )
);

endmodule
