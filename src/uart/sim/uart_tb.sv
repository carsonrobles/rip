`default_nettype none
`timescale 1ns / 1ps

module uart_tb ();

  initial begin
    $dumpfile("uart_tb.fst");
    $dumpvars(0, uart_tb);
    #1;
  end

  logic        clk_i;
  logic        rst_ni;

  logic       rx_data_valid_o;
  logic [7:0] rx_data_o;

  logic       tx_data_ready_o;
  logic       tx_data_valid_i;
  logic [7:0] tx_data_i;

  logic       rx_i;
  logic       tx_o;

  uart #(
    //.CLKS_PER_BIT ( 6875 ) // CLK=66MHz BAUD = 9600
    .CLKS_PER_BIT ( 868 ) // CLK=100MHz BAUD = 115200
  ) u_dut (
    .clk_i           ( clk_i           ),
    .rst_ni          ( rst_ni          ),
  
    .en_i            ( 1'b1            ),
  
    .rx_data_valid_o ( rx_data_valid_o ),
    .rx_data_o       ( rx_data_o       ),
  
    .tx_data_ready_o ( tx_data_ready_o ),
    .tx_data_valid_i ( tx_data_valid_i ),
    .tx_data_i       ( tx_data_i       ),
  
    .rx_i            ( rx_i            ),
    .tx_o            ( tx_o            )
  );

endmodule
