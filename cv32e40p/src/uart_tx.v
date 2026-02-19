// =============================================================================
// uart_tx.v — 8N1 UART Transmitter, width-clean for Gowin
// =============================================================================

module uart_tx #(
    parameter CLK_FREQ = 27_000_000,
    parameter BAUD     = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       wr,
    input  wire [7:0] data,
    output reg        tx,
    output wire       busy
);

localparam [15:0] CLKS_PER_BIT = CLK_FREQ / BAUD;  // 234 @ 27MHz/115200

localparam [1:0] IDLE  = 2'd0;
localparam [1:0] START = 2'd1;
localparam [1:0] DATA  = 2'd2;
localparam [1:0] STOP  = 2'd3;

reg [1:0]  state;
reg [15:0] clk_cnt;
reg [2:0]  bit_idx;
reg [7:0]  shift;

assign busy = (state != IDLE);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state   <= IDLE;
        tx      <= 1'b1;
        clk_cnt <= 16'd0;
        bit_idx <= 3'd0;
        shift   <= 8'd0;
    end else begin
        case (state)
            IDLE: begin
                tx <= 1'b1;
                if (wr) begin
                    shift   <= data;
                    state   <= START;
                    clk_cnt <= 16'd0;
                end
            end

            START: begin
                tx <= 1'b0;
                if (clk_cnt == CLKS_PER_BIT - 16'd1) begin
                    clk_cnt <= 16'd0;
                    bit_idx <= 3'd0;
                    state   <= DATA;
                end else
                    clk_cnt <= clk_cnt + 16'd1;
            end

            DATA: begin
                tx <= shift[0];
                if (clk_cnt == CLKS_PER_BIT - 16'd1) begin
                    clk_cnt <= 16'd0;
                    shift   <= {1'b0, shift[7:1]};
                    if (bit_idx == 3'd7)
                        state <= STOP;
                    else
                        bit_idx <= bit_idx + 3'd1;
                end else
                    clk_cnt <= clk_cnt + 16'd1;
            end

            STOP: begin
                tx <= 1'b1;
                if (clk_cnt == CLKS_PER_BIT - 16'd1) begin
                    clk_cnt <= 16'd0;
                    state   <= IDLE;
                end else
                    clk_cnt <= clk_cnt + 16'd1;
            end
        endcase
    end
end

endmodule
