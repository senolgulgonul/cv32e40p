// =============================================================================
// top.v — CV32E40P SoC for Tang Nano 9K with UART TX
// UART inlined (not separate module) for better LUT optimization
// Peripherals:
//   0x20000000 : LED register (W: bits[5:0], R: current pattern)
//   0x20000004 : UART TX     (W: byte to send, R: bit0=busy)
// =============================================================================

module top (
    input  wire clk_27mhz,
    input  wire rst_n,
    output wire uart_tx,
    output wire [5:0] led
);

wire clk = clk_27mhz;

// ---------------------------------------------------------------------------
// Power-on reset stretcher
// ---------------------------------------------------------------------------
reg [8:0] rst_cnt = 9'h1FF;
reg       rst_reg = 1'b1;

always @(posedge clk) begin
    if (~rst_n) begin
        rst_cnt <= 9'h1FF;
        rst_reg <= 1'b1;
    end else if (rst_cnt != 9'h0) begin
        rst_cnt <= rst_cnt - 9'h1;
        rst_reg <= 1'b1;
    end else
        rst_reg <= 1'b0;
end

wire rst = rst_reg;

// ---------------------------------------------------------------------------
// OBI signals
// ---------------------------------------------------------------------------
wire        instr_req;
wire [31:0] instr_addr;
wire [31:0] instr_rdata;
wire        instr_gnt;
wire        instr_rvalid;

wire        data_req;
wire        data_we;
wire [3:0]  data_be;
wire [31:0] data_addr;
wire [31:0] data_wdata;
wire [31:0] data_rdata;
wire        data_gnt;
wire        data_rvalid;

// ---------------------------------------------------------------------------
// CV32E40P
// ---------------------------------------------------------------------------
cv32e40p_top #(
    .COREV_PULP       (0),
    .COREV_CLUSTER    (0),
    .FPU              (0),
    .FPU_ADDMUL_LAT   (0),
    .FPU_OTHERS_LAT   (0),
    .ZFINX            (0),
    .NUM_MHPMCOUNTERS (0)
) u_core (
    .clk_i               (clk),
    .rst_ni              (~rst),
    .pulp_clock_en_i     (1'b1),
    .scan_cg_en_i        (1'b0),
    .boot_addr_i         (32'h0000_0000),
    .mtvec_addr_i        (32'h0000_0100),
    .dm_halt_addr_i      (32'h0000_0000),
    .hart_id_i           (32'h0000_0000),
    .dm_exception_addr_i (32'h0000_0000),
    .instr_req_o         (instr_req),
    .instr_gnt_i         (instr_gnt),
    .instr_rvalid_i      (instr_rvalid),
    .instr_addr_o        (instr_addr),
    .instr_rdata_i       (instr_rdata),
    .data_req_o          (data_req),
    .data_gnt_i          (data_gnt),
    .data_rvalid_i       (data_rvalid),
    .data_we_o           (data_we),
    .data_be_o           (data_be),
    .data_addr_o         (data_addr),
    .data_wdata_o        (data_wdata),
    .data_rdata_i        (data_rdata),
    .irq_i               (32'h0),
    .irq_ack_o           (),
    .irq_id_o            (),
    .debug_req_i         (1'b0),
    .debug_havereset_o   (),
    .debug_running_o     (),
    .debug_halted_o      (),
    .fetch_enable_i      (1'b1),
    .core_sleep_o        ()
);

// ---------------------------------------------------------------------------
// IMEM
// ---------------------------------------------------------------------------
wire [31:0] imem_ddata;

imem u_imem (
    .clk     (clk),
    .i_addr  (instr_addr[12:2]),
    .i_rdata (instr_rdata),
    .d_addr  (data_addr[12:2]),
    .d_rdata (imem_ddata)
);

// Instruction OBI
reg instr_pending;
always @(posedge clk or posedge rst)
    if (rst) instr_pending <= 1'b0;
    else     instr_pending <= instr_gnt;

assign instr_gnt    = instr_req & ~instr_pending;
assign instr_rvalid = instr_pending;

// ---------------------------------------------------------------------------
// DMEM
// ---------------------------------------------------------------------------
wire [31:0] dmem_rdata;
wire sel_dmem   = data_req && (data_addr[31:13] == 19'h8);
wire sel_imem_d = data_req && (data_addr[31:13] == 19'h0);
wire sel_led    = data_req && (data_addr == 32'h2000_0000);
wire sel_uart   = data_req && (data_addr == 32'h2000_0004);

dmem u_dmem (
    .clk   (clk),
    .en    (sel_dmem),
    .we    (data_we ? data_be : 4'b0),
    .addr  (data_addr[12:2]),
    .wdata (data_wdata),
    .rdata (dmem_rdata)
);

// ---------------------------------------------------------------------------
// LED peripheral
// ---------------------------------------------------------------------------
reg [5:0] led_reg;
always @(posedge clk or posedge rst)
    if (rst)                     led_reg <= 6'h3F;
    else if (sel_led && data_we && data_gnt)
        led_reg <= ~data_wdata[5:0];

assign led = led_reg;

// ---------------------------------------------------------------------------
// UART TX — inlined 8N1, 115200 baud @ 27MHz
// CLKS_PER_BIT = 27000000/115200 = 234
// ---------------------------------------------------------------------------
localparam [7:0] CLKS_PER_BIT = 8'd234;

reg [1:0]  uart_state;
reg [7:0]  uart_clk_cnt;
reg [2:0]  uart_bit_idx;
reg [7:0]  uart_shift;
reg        uart_tx_r;
reg        uart_busy;

localparam U_IDLE  = 2'd0;
localparam U_START = 2'd1;
localparam U_DATA  = 2'd2;
localparam U_STOP  = 2'd3;

wire uart_wr = sel_uart && data_we && data_gnt;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        uart_state   <= U_IDLE;
        uart_tx_r    <= 1'b1;
        uart_clk_cnt <= 8'd0;
        uart_bit_idx <= 3'd0;
        uart_shift   <= 8'd0;
        uart_busy    <= 1'b0;
    end else begin
        case (uart_state)
            U_IDLE: begin
                uart_tx_r <= 1'b1;
                uart_busy <= 1'b0;
                if (uart_wr) begin
                    uart_shift   <= data_wdata[7:0];
                    uart_state   <= U_START;
                    uart_clk_cnt <= 8'd0;
                    uart_busy    <= 1'b1;
                end
            end
            U_START: begin
                uart_tx_r <= 1'b0;
                if (uart_clk_cnt == CLKS_PER_BIT - 8'd1) begin
                    uart_clk_cnt <= 8'd0;
                    uart_bit_idx <= 3'd0;
                    uart_state   <= U_DATA;
                end else
                    uart_clk_cnt <= uart_clk_cnt + 8'd1;
            end
            U_DATA: begin
                uart_tx_r <= uart_shift[0];
                if (uart_clk_cnt == CLKS_PER_BIT - 8'd1) begin
                    uart_clk_cnt <= 8'd0;
                    uart_shift   <= {1'b0, uart_shift[7:1]};
                    if (uart_bit_idx == 3'd7)
                        uart_state <= U_STOP;
                    else
                        uart_bit_idx <= uart_bit_idx + 3'd1;
                end else
                    uart_clk_cnt <= uart_clk_cnt + 8'd1;
            end
            U_STOP: begin
                uart_tx_r <= 1'b1;
                if (uart_clk_cnt == CLKS_PER_BIT - 8'd1) begin
                    uart_clk_cnt <= 8'd0;
                    uart_state   <= U_IDLE;
                    uart_busy    <= 1'b0;
                end else
                    uart_clk_cnt <= uart_clk_cnt + 8'd1;
            end
        endcase
    end
end

assign uart_tx = uart_tx_r;

// ---------------------------------------------------------------------------
// Data OBI with pending tracker + registered selects
// ---------------------------------------------------------------------------
reg data_pending;
reg sel_dmem_r, sel_imem_d_r, sel_led_r, sel_uart_r;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_pending <= 1'b0;
        sel_dmem_r   <= 1'b0;
        sel_imem_d_r <= 1'b0;
        sel_led_r    <= 1'b0;
        sel_uart_r   <= 1'b0;
    end else begin
        data_pending <= data_gnt;
        sel_dmem_r   <= sel_dmem   & data_gnt;
        sel_imem_d_r <= sel_imem_d & data_gnt;
        sel_led_r    <= sel_led    & data_gnt;
        sel_uart_r   <= sel_uart   & data_gnt;
    end
end

assign data_gnt    = data_req & ~data_pending;
assign data_rvalid = data_pending;

reg [31:0] data_rdata_r;
always @(*) begin
    if      (sel_imem_d_r) data_rdata_r = imem_ddata;
    else if (sel_dmem_r)   data_rdata_r = dmem_rdata;
    else if (sel_led_r)    data_rdata_r = {26'h0, ~led_reg};
    else if (sel_uart_r)   data_rdata_r = {31'h0, uart_busy};
    else                   data_rdata_r = 32'h0;
end

assign data_rdata = data_rdata_r;

endmodule