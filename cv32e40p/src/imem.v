// =============================================================================
// imem.v — CV32E40P: print "Hello CV32!\r\n" then walk LEDs
// Fix: uart delay uses 2000 cycles (fits in 12-bit signed imm, max=2047)
//      3000 was wrong — overflows 12-bit, loads garbage value
// All encodings Python-verified
// =============================================================================

module imem (
    input  wire        clk,
    input  wire [10:0] i_addr,
    output reg  [31:0] i_rdata,
    input  wire [10:0] d_addr,
    output reg  [31:0] d_rdata
);

reg [31:0] mem [0:1023];

initial begin
    mem[0]  = 32'h00000013; mem[1]  = 32'h00000013;
    mem[2]  = 32'h00000013; mem[3]  = 32'h00000013;
    mem[4]  = 32'h00000013; mem[5]  = 32'h00000013;
    mem[6]  = 32'h00000013; mem[7]  = 32'h00000013;
    mem[8]  = 32'h00000013; mem[9]  = 32'h00000013;
    mem[10] = 32'h00000013; mem[11] = 32'h00000013;
    mem[12] = 32'h00000013; mem[13] = 32'h00000013;
    mem[14] = 32'h00000013; mem[15] = 32'h00000013;
    mem[16] = 32'h00000013; mem[17] = 32'h00000013;
    mem[18] = 32'h00000013; mem[19] = 32'h00000013;
    mem[20] = 32'h00000013; mem[21] = 32'h00000013;
    mem[22] = 32'h00000013; mem[23] = 32'h00000013;
    mem[24] = 32'h00000013; mem[25] = 32'h00000013;
    mem[26] = 32'h00000013; mem[27] = 32'h00000013;
    mem[28] = 32'h00000013; mem[29] = 32'h00000013;
    mem[30] = 32'h00000013; mem[31] = 32'h00000013;
    mem[32] = 32'h00000013; mem[33] = 32'h00000013;
    mem[34] = 32'h00000013; mem[35] = 32'h00000013;
    mem[36] = 32'h00000013; mem[37] = 32'h00000013;

    // =========================================================
    // _start @ 0x000
    // =========================================================
    mem[0]  = 32'h200002B7;   // lui x5,0x20000        x5=0x20000000
    mem[1]  = 32'h00011137;   // lui x2,0x11            sp=0x11000
    mem[2]  = 32'hFFC10113;   // addi x2,x2,-4          sp=0x10FFC
    mem[3]  = 32'h000005B7;   // lui x11,0
    mem[4]  = 32'h20058593;   // addi x11,x11,0x200     x11=string @ 0x200
    mem[5]  = 32'h04C000EF;   // jal x1,+76             call uart_puts @ 0x060
    mem[6]  = 32'h00100313;   // addi x6,x0,1           LED=1

    // main_loop @ 0x01C (word 7)
    mem[7]  = 32'h0062A023;   // sw x6,0(x5)            write LED
    mem[8]  = 32'h001E83B7;   // lui x7,0x1E8
    mem[9]  = 32'h48038393;   // addi x7,x7,1152        x7=2,000,000
    mem[10] = 32'hFFF38393;   // addi x7,x7,-1
    mem[11] = 32'hFE039EE3;   // bne x7,x0,-4
    mem[12] = 32'h00131413;   // slli x8,x6,1
    mem[13] = 32'h00535493;   // srli x9,x6,5
    mem[14] = 32'h00946333;   // or x6,x8,x9
    mem[15] = 32'h03F37313;   // andi x6,x6,0x3F
    mem[16] = 32'hFDDFF06F;   // jal x0,-36             → main_loop @ 0x01C

    // =========================================================
    // uart_putc @ 0x044 (word 17)
    // arg: x10 = char to send
    // Delay = 2000 cycles (fits in 12-bit, > 1 char @ 115200/27MHz)
    // =========================================================
    mem[17] = 32'h00A2A223;   // sw x10,4(x5)           write char
    mem[18] = 32'h7D000393;   // addi x7,x0,2000        ← FIXED (was 3000)
    mem[19] = 32'hFFF38393;   // addi x7,x7,-1
    mem[20] = 32'hFE039EE3;   // bne x7,x0,-4           delay loop
    mem[21] = 32'h00008067;   // jalr x0,x1,0           ret

    // =========================================================
    // uart_puts @ 0x060 (word 24)
    // arg: x11 = string pointer
    // =========================================================
    mem[24] = 32'hFF810113;   // addi x2,x2,-8
    mem[25] = 32'h00112223;   // sw x1,4(x2)
    mem[26] = 32'h00812023;   // sw x8,0(x2)
    mem[27] = 32'h00058413;   // addi x8,x11,0          s0=ptr

    // loop @ 0x070 (word 28)
    mem[28] = 32'h00044503;   // lbu x10,0(x8)
    mem[29] = 32'h00050863;   // beq x10,x0,+16         → exit @ 0x084
    mem[30] = 32'hFCDFF0EF;   // jal x1,-52             call uart_putc @ 0x044
    mem[31] = 32'h00140413;   // addi x8,x8,1
    mem[32] = 32'hFF1FF06F;   // jal x0,-16             → loop @ 0x070

    // exit @ 0x084 (word 33)
    mem[33] = 32'h00412083;   // lw x1,4(x2)
    mem[34] = 32'h00012403;   // lw x8,0(x2)
    mem[35] = 32'h00810113;   // addi x2,x2,8
    mem[36] = 32'h00008067;   // jalr x0,x1,0           ret

    // =========================================================
    // Exception handler @ 0x100 (word 64)
    // =========================================================
    mem[64] = 32'h0000006F;   // jal x0,0

    // =========================================================
    // String "Hello CV32!\r\n\0" @ 0x200 (word 128)
    // =========================================================
    mem[128] = 32'h6C6C6548;  // "Hell"
    mem[129] = 32'h5643206F;  // "o CV"
    mem[130] = 32'h0D213233;  // "32!\r"
    mem[131] = 32'h0000000A;  // "\n\0"
end

always @(posedge clk) begin
    i_rdata <= mem[i_addr[9:0]];
    d_rdata <= mem[d_addr[9:0]];
end

endmodule