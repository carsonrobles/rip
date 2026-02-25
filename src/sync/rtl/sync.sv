module sync #(
  parameter int RANK = 2
) (
  input  clk_i,

  input  async_i,
  output sync_o
);

  logic [RANK-1:0] s;

  always_ff @(posedge clk_i) begin
    s[0] <= async_i;

    for (int i=1; i<RANK; i++) begin
      s[i] <= s[i-1];
    end
  end

  assign sync_o = s[RANK-1];

endmodule
