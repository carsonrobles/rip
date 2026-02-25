`default_nettype none
`timescale 1ns / 1ps

module sync_fifo_tb ();

  initial begin
    $dumpfile("sync_fifo_tb.fst");
    $dumpvars(0, sync_fifo_tb);
    #1;
  end

  logic        clk_i;
  logic        rst_ni;

  logic        push_i;
  wire         full_o;
  logic [31:0] data_i;

  logic        pop_i;
  wire         empty_o;
  wire  [31:0] data_o;

  sync_fifo #(
    .WIDTH ( 32 ),
    .DEPTH ( 16 )
  ) u_dut (
    .clk_i   ( clk_i   ),
    .rst_ni  ( rst_ni  ),

    .push_i  ( push_i  ),
    .full_o  ( full_o  ),
    .data_i  ( data_i  ),

    .pop_i   ( pop_i   ),
    .empty_o ( empty_o ),
    .data_o  ( data_o  )
  );

endmodule
