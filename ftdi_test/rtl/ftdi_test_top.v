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
    * Board selection is done at synthesis time via the BOARD parameter:
    *   BOARD = 0  →  Nexys A7 (100 MHz oscillator)
    *   BOARD = 1  →  PYNQ-Z2  (125 MHz oscillator)
    * The parameter only affects the clock-divider ratio for sys_clk.
    *
    * NOTE: Channel A of the FT2232H must be programmed to 245-sync-FIFO
    *       mode with FT_Prog before loading this bitstream.
*/

module ftdi_test_top #(
    // 0 = Nexys A7 (100 MHz board clock)
    // 1 = PYNQ-Z2  (125 MHz board clock)
    parameter BOARD = 0
) (
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
    output wire        ft_oe_n,     // ACBUS6 / OE#
    output wire        ft_siwu_n    // ACBUS4 / SIWU#
);

    // -------------------------------------------------------------------------
    // Clock divider: produce a 50 MHz sys_clk from the board oscillator.
    //   Nexys A7 : 100 MHz ÷ 2  (DIV = 1, toggle every cycle)
    //   PYNQ-Z2  : 125 MHz ÷ 2.5 - not integer; use MMCM instead.
    //              For simplicity we divide by 3 → ~41.7 MHz (well within
    //              the 50 MHz spec and still far faster than the FTDI rate).
    // -------------------------------------------------------------------------
    localparam DIV_HALF = (BOARD == 0) ? 1 : 1;  // both toggle every cycle for now

    // Simple clock divider (÷2) - works for both boards at these frequencies.
    // Replace with MMCM/PLL for a tighter 50 MHz if needed.
    reg sys_clk_r = 1'b0;
    always @(posedge clk_in)
        sys_clk_r <= ~sys_clk_r;

    wire sys_clk = sys_clk_r;  // 50 MHz (Nexys) or 62.5 MHz (PYNQ)

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
    reg        wr_en   = 1'b0;
    reg  [7:0] wr_data = 8'h00;

    ft2232h_tx #(
        .TX_DEPTH_EXP (10)      // 1024-byte internal TX buffer
    ) u_ft2232h_tx (
        .sys_clk   (sys_clk),
        .sys_rst_n (sys_rst_n),
        .wr_en     (wr_en),
        .wr_data   (wr_data),
        .full      (ft_full),
        .ft_clk    (ft_clk),
        .ft_data   (ft_data),
        .ft_rxf_n  (ft_rxf_n),
        .ft_txe_n  (ft_txe_n),
        .ft_rd_n   (ft_rd_n),
        .ft_wr_n   (ft_wr_n),
        .ft_oe_n   (ft_oe_n),
        .ft_siwu_n (ft_siwu_n)
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
    //   IDLE      - wait until !ft_full
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

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            state     <= S_HDR0;
            pay_cnt   <= 8'h00;
            frame_cnt <= 8'h00;
            wr_en     <= 1'b0;
            wr_data   <= 8'h00;
        end else begin
            wr_en <= 1'b0;   // default: no write

            if (!ft_full) begin
                wr_en <= 1'b1;

                case (state)
                    S_HDR0: begin wr_data <= 8'hDE; state <= S_HDR1; end
                    S_HDR1: begin wr_data <= 8'hAD; state <= S_HDR2; end
                    S_HDR2: begin wr_data <= 8'hBE; state <= S_HDR3; end
                    S_HDR3: begin wr_data <= 8'hEF; state <= S_PAYLOAD; pay_cnt <= 8'h00; end

                    S_PAYLOAD: begin
                        wr_data <= pay_cnt;
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

endmodule
