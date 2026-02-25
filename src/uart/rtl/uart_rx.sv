module uart_rx #(
  parameter int CLKS_PER_BIT
) (
  input              clk_i,
  input              rst_ni,

  input              en_i,

  output logic       data_valid_o,
  output       [7:0] data_o,

  input              ser_i
);

  typedef enum {
    IDLE,
    WAIT_CENTER,
    RECV_BIT,
    WAIT_BIT
  } state_t;

  state_t fsm;
  state_t fsm_d;

  logic [3:0] bit_cnt;

  always_ff @(posedge clk_i) begin
    if (~rst_ni)
      bit_cnt <= '0;
    else if (fsm == IDLE)
      bit_cnt <= '0;
    else if (fsm == RECV_BIT)
      bit_cnt <= bit_cnt + 1;
  end

  localparam int WND_CNT_WIDTH = $clog2(CLKS_PER_BIT);

  logic [WND_CNT_WIDTH-1:0] wnd_cnt;

  always_ff @(posedge clk_i) begin
    if (~rst_ni)
      wnd_cnt <= '0;
    else if ((fsm == IDLE) || (fsm == RECV_BIT))
      wnd_cnt <= '0;
    else
      wnd_cnt <= wnd_cnt + 1;
  end

  logic ser_q;

  always_ff @(posedge clk_i) begin
    ser_q <= ser_i;
  end

  wire start = (ser_q == uart_pkg::UART_STOP_BIT) & (ser_i == uart_pkg::UART_START_BIT);
  wire last  = (bit_cnt == 4'd9);

  always_ff @(posedge clk_i) begin
    if (~rst_ni)
      data_valid_o <= 1'b0;
    else if (fsm == IDLE)
      data_valid_o <= 1'b0;
    else if (fsm == RECV_BIT)
      data_valid_o <= last;
  end

  logic [8:0] data;

  always_ff @(posedge clk_i) begin
    if (fsm == RECV_BIT)
      data <= {ser_i, data[8:1]};
  end

  assign data_o = data[7:0];

  always_ff @(posedge clk_i) begin
    if (~rst_ni)
      fsm <= IDLE;
    else if (~en_i)
      fsm <= IDLE;
    else
      fsm <= fsm_d;
  end

  always_comb begin
    case (fsm)
      IDLE:
        if (start)
          fsm_d = WAIT_CENTER;
        else
          fsm_d = IDLE;
      WAIT_CENTER:
        if (wnd_cnt == WND_CNT_WIDTH'(CLKS_PER_BIT / 2))
          if (ser_i == uart_pkg::UART_START_BIT)
            fsm_d = RECV_BIT;
          else
            fsm_d = IDLE;
        else
          fsm_d = WAIT_CENTER;
      RECV_BIT:
        if (last)
          fsm_d = IDLE;
        else
          fsm_d = WAIT_BIT;
      WAIT_BIT:
        if (wnd_cnt == WND_CNT_WIDTH'(CLKS_PER_BIT - 2))
          fsm_d = RECV_BIT;
        else
          fsm_d = WAIT_BIT;
      default:
        fsm_d = IDLE;
    endcase
  end

endmodule
