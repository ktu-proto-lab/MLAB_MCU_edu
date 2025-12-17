// Description: This module is a reset synchronizer. Reset is asserted async and deasserted sync. Reset is active-low
// Using at least 4 DFFs is recommended


module areset_sync #(
    parameter int unsigned NumRegs = 4
) (
   input  logic clk_i,
   input  logic i_rst_async,        // Asynchronous reset
   output logic o_rst_sync          // Asynchronous Reset with de-assertion synchronized
);

    logic [NumRegs-1:0] synch_regs_q;   // Synchronization shift register

    always @(posedge clk_i or negedge i_rst_async) begin
        if (~i_rst_async) begin
            synch_regs_q <= '0;
        end else begin
            synch_regs_q <= {synch_regs_q[NumRegs-2:0], 1'b1};
        end
    end

    assign o_rst_sync = synch_regs_q[NumRegs-1];

endmodule
