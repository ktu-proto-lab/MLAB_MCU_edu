//*************************************************************************
//         32-bit to 16-bit Wishbone to PIT Adapter Wrapper
//*************************************************************************
//
// - Connects to the 32-bit system bus (wb_if).
// - Instantiates the original, unmodified 16-bit Verilog PIT core.
// - Translates all data and control signals to make the 16-bit PIT
//   appear as a native 32-bit peripheral to the system.
//
// Author:      Manfredas Lamsargis
// Date:        15.07.2025
// Version:     1.0 (Initial working version)
//

module wb_pit (
    // System-side 32-bit Wishbone interface
    wb_if.slave          wb,

    // PIT's Interrupt Request
    output logic         pit_irq_o
);

    //==================================================
    // Internal Signals
    //==================================================
    logic [1:0]     sel_to_pit;         // Translated 2-bit select for the 16-bit PIT
    logic [15:0]    data_to_pit;        // Translated 16-bit data bus to the PIT
    logic [15:0]    data_from_pit;      // 16-bit data bus from the PIT
    logic           delayed_pit_ack;    // Delayed PIT's acknowledgement signal



    //==================================================
    // 32-bit to 16-bit Wishbone Translation Logic
    //==================================================

    // The PIT is a 16-bit slave, only pass the lower 2 select lines.
    assign sel_to_pit = wb.sel[1:0];

`ifdef NO_MODPORT_EXPRESSIONS
    assign data_to_pit  = wb.dat_m[15:0];               // Truncate 32-bit master data to 16 bits
    assign wb.dat_s     = {16'h0000, data_from_pit};    // Zero-extend 16-bit slave data to 32 bits
`else
    assign data_to_pit  = wb.dat_i[15:0];
    assign wb.dat_o     = {16'h0000, data_from_pit};
`endif

    //==================================================
    // Wishbone Protocol Handling
    //==================================================

    // Ignore stalls and errors, the core does not handle them as of 15.07.25.
    assign wb.stall     = 1'b0;
    assign wb.err       = 1'b0;

    // ACKNOWLEDGEMENT WORKAROUND:
    // The original slave's IP has a bug where it does not send any acknowledgement signal
    // even if pit_top.SINGLE_CYCLE is set to 0. Using single-cycled PIT to avoid this issue.
    // FF delays the ACK by one cycle to create a proper 2-cycle pipelined response.

    // always_ff @(posedge wb.clk) begin
    //     if (wb.rst)
    //         wb.ack <= 0;
    //     else
    //         wb.ack <= delayed_pit_ack;
    // end

    // TODO: MOVE TO ACTIVE-LOW RESET.
    // Done. THX:)
    always_ff @(posedge wb.clk or negedge wb.rst) begin
        if (!wb.rst)
            wb.ack <= 0;
        else
            wb.ack <= delayed_pit_ack;
    end

    // --- PIT Instantiation ---
    pit_top #(

        .DWIDTH        (16),

        .SINGLE_CYCLE   (1'b1)      // See "ACKNOWLEDGEMENT WORKAROUND" comment block above

    ) u_wb_pit (

        // --- Wishbone Connections ---

        // Inputs
        .wb_clk_i       (wb.clk),
        .arst_i         (wb.rst),
        .wb_cyc_i       (wb.cyc),
        .wb_stb_i       (wb.stb),
        .wb_we_i        (wb.we),
        .wb_adr_i       (wb.adr[4:2]),
        .wb_sel_i       (sel_to_pit),
        .wb_dat_i       (data_to_pit),

        // Outputs
        .wb_dat_o       (data_from_pit),
        .wb_ack_o       (delayed_pit_ack),

        // --- PIT signals ---

        // Outputs
        .pit_irq_o      (pit_irq_o),
        .pit_o          (),
        .cnt_flag_o     (),
        .cnt_sync_o     (),

        // Inputs
        .ext_sync_i     (1'b0)      // External sync feature is not used.
    );

endmodule
