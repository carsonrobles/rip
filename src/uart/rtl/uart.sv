module uart #(
  // set this to (frequency of clk_i) / (baud rate)
  parameter int CLKS_PER_BIT = 10
) (
  input        clk_i,
  input        rst_ni,

  input        en_i,

  output       rx_data_valid_o,
  output [7:0] rx_data_o,

  output       tx_data_ready_o,
  input        tx_data_valid_i,
  input  [7:0] tx_data_i,

  input        rx_i,
  output       tx_o
);

  uart_rx #(
    .CLKS_PER_BIT ( CLKS_PER_BIT )
  ) u_rx (
    .clk_i        ( clk_i           ),
    .rst_ni       ( rst_ni          ),

    .en_i         ( en_i            ),

    .data_valid_o ( rx_data_valid_o ),
    .data_o       ( rx_data_o       ),

    .ser_i        ( rx_i            )
  );

  uart_tx #(
    .CLKS_PER_BIT ( CLKS_PER_BIT )
  ) u_tx (
    .clk_i        ( clk_i           ),
    .rst_ni       ( rst_ni          ),

    .en_i         ( en_i            ),

    .data_ready_o ( tx_data_ready_o ),
    .data_valid_i ( tx_data_valid_i ),
    .data_i       ( tx_data_i       ),

    .ser_o        ( tx_o            )
  );

endmodule
