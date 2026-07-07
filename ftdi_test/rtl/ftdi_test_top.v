/*
  Contributors:
    * Dovydas Liutkus
  Description:
    * Top-level for the FT2232H TX interface test
    *
    * Sends a repeating frame to the PC via the FT2232H Mini Module in
    * 245-sync-FIFO mode.  Each frame is:
    *
    *   1. Magic header: 0xDE 0xAD 0xBE 0xEF  (4 bytes, fixed)
    *   2. Payload     : 0x00 .. 0xFF          (256 bytes, incrementing counter)
    *
    * Total frame = 260 bytes.  Frames are sent back-to-back as fast as
    * the ft2232h_tx wrapper allows.
    *
    * The PC-side script (python/ftdi_rx_verify.py) receives the stream,
    * locates the magic header, and verifies each payload byte.
    *
    * NOTE: Channel A of the FT2232H must be programmed to 245-sync-FIFO
    *       mode with FT_Prog before loading this bitstream.
*/

module ftdi_test_top (
    input  wire        clk_in,      // on-board oscillator

    // Status LEDs
    output wire [3:0]  led,

    // FT2232H Mini Module - Channel A, 245-sync-FIFO mode
    input  wire        ft_clk,      // ACBUS5 / CLKOUT  (60 MHz from chip)
    inout  wire [7:0]  ft_data,     // ADBUS[7:0]
    input  wire        ft_rxf_n,    // ACBUS0 / RXF#
    input  wire        ft_txe_n,    // ACBUS1 / TXE#
    output wire        ft_rd_n,     // ACBUS2 / RD#
    output wire        ft_wr_n,     // ACBUS3 / WR#
    output wire        ft_oe_n      // ACBUS6 / OE#
);

    reg sys_clk_r = 1'b0;
    always @(posedge clk_in)
        sys_clk_r <= ~sys_clk_r;

    wire sys_clk = sys_clk_r;

    // -------------------------------------------------------------------------
    // Reset: hold sys_rst_n low for 256 cycles after power-on
    // -------------------------------------------------------------------------
    reg [7:0] rst_cnt = 8'hFF;
    reg       sys_rst_n = 1'b0;

    always @(posedge sys_clk) begin
        if (rst_cnt != 8'h00) begin
            rst_cnt  <= rst_cnt - 8'h01;
            sys_rst_n <= 1'b0;
        end else begin
            sys_rst_n <= 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // ft2232h_tx wrapper
    // -------------------------------------------------------------------------
    wire       ft_full;
    wire        wr_en;     // combinational - asserted whenever FIFO has room
    reg  [7:0] wr_data;   // combinational - byte for the current FSM state

    ft2232h_tx #(
        .TX_DEPTH_EXP (10)      // 1024-byte internal TX buffer
    ) u_ft2232h_tx (
        .sys_clk   (sys_clk),
        .sys_rst_n (sys_rst_n),
        .wr_en     (wr_en),
        .wr_data   (wr_data),
        .wr_last   (1'b0),
        .full      (ft_full),
        .ft_clk    (ft_clk),
        .ft_data   (ft_data),
        .ft_rxf_n  (ft_rxf_n),
        .ft_txe_n  (ft_txe_n),
        .ft_rd_n   (ft_rd_n),
        .ft_wr_n   (ft_wr_n),
        .ft_oe_n   (ft_oe_n)
    );

    // -------------------------------------------------------------------------
    // Pattern generator - magic-word header + 256-byte counter payload
    //
    // Frame layout (260 bytes):
    //   Byte  0 : 0xDE  \
    //   Byte  1 : 0xAD   > magic header
    //   Byte  2 : 0xBE  /
    //   Byte  3 : 0xEF  /
    //   Byte  4 : 0x00  \
    //   ...               > payload (counter 0x00..0xFF)
    //   Byte259 : 0xFF  /
    //
    // State machine:
    //   HDR0..3   - send the four header bytes
    //   PAYLOAD   - send 256 counter bytes, then back to IDLE
    // -------------------------------------------------------------------------
    localparam [2:0]
        S_HDR0    = 3'd0,
        S_HDR1    = 3'd1,
        S_HDR2    = 3'd2,
        S_HDR3    = 3'd3,
        S_PAYLOAD = 3'd4;

    reg [2:0]  state      = S_HDR0;
    reg [7:0]  pay_cnt    = 8'h00;   // payload byte counter
    reg [7:0]  frame_cnt  = 8'h00;   // wrapping frame counter (for LED)

    // We always have a byte ready, so hold tx_tvalid (wr_en) high.  A master
    // may keep tvalid asserted regardless of tready - that is legal.  But the
    // FSM must only advance when the byte was actually ACCEPTED (tvalid &
    // tready = wr_en & ~ft_full), otherwise a byte presented during a full
    // cycle is silently skipped while the counter moves on -> dropped bytes.
    //
    // PACED MODE: offer 1 byte per 8 sys_clk cycles (~6.25 MB/s at 50 MHz),
    // well below the USB drain rate (~35-42 MB/s). The chip's TX buffer then
    // never fills, TXE# never pauses mid-stream, and the burst-restart byte
    // drop (see README "Status") should never trigger - the link should be
    // lossless. Replace with `assign wr_en = sys_rst_n;` for full-rate
    // (saturating) mode.
    reg [2:0] pace = 3'd0;
    always @(posedge sys_clk) pace <= pace + 3'd1;
    assign wr_en = sys_rst_n & (pace == 3'd0);
    wire beat = wr_en & ~ft_full;   // a byte was actually accepted this cycle

    always @(*) begin
        case (state)
            S_HDR0:    wr_data = 8'hDE;
            S_HDR1:    wr_data = 8'hAD;
            S_HDR2:    wr_data = 8'hBE;
            S_HDR3:    wr_data = 8'hEF;
            S_PAYLOAD: wr_data = pay_cnt;
            default:   wr_data = 8'h00;
        endcase
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            state     <= S_HDR0;
            pay_cnt   <= 8'h00;
            frame_cnt <= 8'h00;
        end else if (beat) begin
            case (state)
                S_HDR0: state <= S_HDR1;
                S_HDR1: state <= S_HDR2;
                S_HDR2: state <= S_HDR3;
                S_HDR3: begin state <= S_PAYLOAD; pay_cnt <= 8'h00; end

                S_PAYLOAD: begin
                    if (pay_cnt == 8'hFF) begin
                        state     <= S_HDR0;
                        frame_cnt <= frame_cnt + 8'h01;
                    end
                    pay_cnt <= pay_cnt + 8'h01;
                end

                default: state <= S_HDR0;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // LEDs
    //   [3]   - ft_clk heartbeat (blinks at ~5 Hz if 60 MHz clock is live)
    //   [2:0] - low 3 bits of frame counter (rolls over every 8 frames)
    // -------------------------------------------------------------------------
    wire ft_clk_beat;

    clock_beat #(
        .CLK_FREQ  (60_000_000),
        .BEAT_FREQ (5)
    ) u_ft_clk_beat (
        .clk  (ft_clk),
        .beat (ft_clk_beat)
    );

    assign led[3]   = ft_clk_beat;
    assign led[2:0] = frame_cnt[2:0];



// ILA - trigger on ft_wr_n=0 to confirm FPGA is writing to FT2232H
ila_0 u_ila (
    .clk     ( ft_clk      ),   // 60 MHz from FT2232H - all FT signals are synchronous to this

    .probe0  ( ft_rxf_n    ),   // [0:0] RXF# : PC has data for FPGA (active low)
    .probe1  ( ft_txe_n    ),   // [0:0] TXE# : FT2232H can accept TX data (active low)
    .probe2  ( ft_oe_n     ),   // [0:0] OE#
    .probe3  ( ft_rd_n     ),   // [0:0] RD#
    .probe4  ( ft_wr_n     ),   // [0:0] WR#  : trigger on this going low
    .probe5  ( ft_data     ),   // [7:0] data bus
    .probe6  ( ft_full     ),   // [0:0] TX FIFO full (sys_clk domain, async here)
    .probe7  ( wr_en       )    // [0:0] pattern generator write enable (sys_clk domain, async here)
);




endmodule
