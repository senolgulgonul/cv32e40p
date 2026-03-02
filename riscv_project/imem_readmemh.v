// =============================================================================
// imem.v — Loads firmware.hex compiled from C by RISC-V GCC
// Place firmware.hex in the same folder as your .gprj file
// =============================================================================

module imem (
    input  wire        clk,
    input  wire [10:0] i_addr,
    output reg  [31:0] i_rdata,
    input  wire [10:0] d_addr,
    output reg  [31:0] d_rdata
);

reg [31:0] mem [0:1023];

initial $readmemh("firmware.hex", mem);

always @(posedge clk) begin
    i_rdata <= mem[i_addr[9:0]];
    d_rdata <= mem[d_addr[9:0]];
end

endmodule
