// =============================================================================
// dmem.v — Data Memory, 4KB, byte-enable write, synchronous read
// Reduced from 8KB to fit Tang Nano 9K LUT budget
// =============================================================================

module dmem (
    input  wire        clk,
    input  wire        en,
    input  wire [3:0]  we,
    input  wire [10:0] addr,   // word address (only [9:0] used for 4KB)
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

reg [7:0] mem0 [0:1023];
reg [7:0] mem1 [0:1023];
reg [7:0] mem2 [0:1023];
reg [7:0] mem3 [0:1023];

wire [9:0] a = addr[9:0];

always @(posedge clk) begin
    if (en) begin
        if (we[0]) mem0[a] <= wdata[7:0];
        if (we[1]) mem1[a] <= wdata[15:8];
        if (we[2]) mem2[a] <= wdata[23:16];
        if (we[3]) mem3[a] <= wdata[31:24];
        rdata <= {mem3[a], mem2[a], mem1[a], mem0[a]};
    end
end

endmodule
