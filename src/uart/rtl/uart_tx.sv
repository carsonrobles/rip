module uart_tx #(
  parameter int CLKS_PER_BIT
) (
  input              clk_i,
  input              rst_ni,

  input              en_i,

  output             data_ready_o,
  input              data_valid_i,
  input        [7:0] data_i,

  output logic       ser_o
);

  typedef enum {
    IDLE,
    SEND_BIT,
    WAIT_BIT
  } state_t;

  state_t fsm;
  state_t fsm_d;

  assign data_ready_o = (fsm == IDLE);

  wire go = data_ready_o & data_valid_i;

  logic [7:0] data;

  always_ff @(posedge clk_i) begin
    if (go)
      data <= data_i;
  end

  logic [3:0] bit_cnt;

  always_ff @(posedge clk_i) begin
    if (~rst_ni)
      bit_cnt <= '0;
    else if (fsm == IDLE)
      bit_cnt <= '0;
    else if (fsm == SEND_BIT)
      bit_cnt <= bit_cnt + 1;
  end

  wire [9:0] par = {uart_pkg::UART_STOP_BIT, data, uart_pkg::UART_START_BIT}; 

  always_ff @(posedge clk_i) begin
    if (~rst_ni)
      ser_o <= 1'b1;
    else if (fsm == IDLE)
      ser_o <= 1'b1;
    else if (fsm == SEND_BIT)
      ser_o <= par[bit_cnt];
  end

  localparam int WND_CNT_WIDTH = $clog2(CLKS_PER_BIT);

  logic [WND_CNT_WIDTH-1:0] wnd_cnt;

  always_ff @(posedge clk_i) begin
    if (~rst_ni)
      wnd_cnt <= '0;
    else if ((fsm == IDLE) || (fsm == SEND_BIT))
      wnd_cnt <= '0;
    else
      wnd_cnt <= wnd_cnt + 1;
  end

  always_ff @(posedge clk_i) begin
    if (~rst_ni)
      fsm <= IDLE;
    else if (~en_i)
      fsm <= IDLE;
    else
      fsm <= fsm_d;
  end

  wire last = (bit_cnt == 4'd10);

  always_comb begin
    case (fsm)
      IDLE:
        if (go)
          fsm_d = SEND_BIT;
        else
          fsm_d = IDLE;
      SEND_BIT:
        fsm_d = WAIT_BIT;
      WAIT_BIT:
        if (wnd_cnt == WND_CNT_WIDTH'(CLKS_PER_BIT - 2))
          if (last)
            fsm_d = IDLE;
          else
            fsm_d = SEND_BIT;
        else
          fsm_d = WAIT_BIT;
      default:
        fsm_d = IDLE;
    endcase
  end

endmodule
