`include "project_defs.svh"


module i2c_debouncer (
    input clk,
    input in,
    output out
  );
 
  reg [`I2C_DEBOUNCER_REG_SIZE-1:0] ctr_d, ctr_q;
  reg [1:0] sync_d, sync_q;
 
  assign out = ctr_q == {`I2C_DEBOUNCER_REG_SIZE{1'b1}};
 
  always @(*) begin
    sync_d[0] = in;
    sync_d[1] = sync_q[0];
    ctr_d = ctr_q + 1'b1;
 
    if (ctr_q == {`I2C_DEBOUNCER_REG_SIZE{1'b1}}) begin
      ctr_d = ctr_q;
    end
 
    if (!sync_q[1])
      ctr_d = `I2C_DEBOUNCER_REG_SIZE'd0;
  end
 
  always @(posedge clk) begin
    ctr_q <= ctr_d;
    sync_q <= sync_d;
  end
 
endmodule
