module clk_div (
    input  wire clk_in,   // Input clock
    input  wire rst,      // Synchronous reset
    output reg  clk_out   // Output clock (clk_in divided by 2)
);

//always @(posedge clk_in) begin
//    if (rst)
//        clk_out <= 1'b0;
//    else
//        clk_out <= ~clk_out;
//end

reg [3:0] count;

always @(posedge clk_in) begin
    if (rst) begin
        count   <= 0;
        clk_out <= 0;
    end else begin
        count <= count + 1;
        if (count == 5) begin
            count   <= 0;
            clk_out <= 1;
        end else begin
            clk_out <= 0;
        end
    end
end

endmodule
