`default_nettype none
`timescale 1ns / 1ps

module sync_tb ();

  initial begin
    $dumpfile("sync_tb.fst");
    $dumpvars(0, sync_tb);
    #1;
  end

  logic clk_i;
  logic async_i;
  logic sync_o;

  sync u_dut (
    .clk_i   ( clk_i   ),
    .async_i ( async_i ),
    .sync_o  ( sync_o  )
  );

endmodule
