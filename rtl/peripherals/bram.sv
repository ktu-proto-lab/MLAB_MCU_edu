// 32-bit wide single-port synchronous BRAM for frame storage.
// Word-addressed; default depth is one QVGA frame (320×240 = 76800 bytes =
// 19200 32-bit words).

module bram #(
    parameter int          DEPTH       = 19200,  // 320×240 bytes / 4
    parameter              MEMInitFile = ""
)(
    input  logic        clk,
    input  logic        en,
    input  logic        we,
    input  logic [14:0] addr,   // word address
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);

    // (* ram_style = "block" *)
    logic [31:0] mem [0:DEPTH-1];

    initial begin
        if (MEMInitFile != "")
            $readmemh(MEMInitFile, mem);
    end

    // No-change mode: output register holds its value during writes.
    always_ff @(posedge clk) begin
        if (en) begin
            if (we)
                mem[addr] <= wdata;
            else
                rdata <= mem[addr];
        end
    end

endmodule
