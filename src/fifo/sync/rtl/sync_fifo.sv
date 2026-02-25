// TODO: split into control and data
// TODO: add assertions for over/underflow

module sync_fifo #(
  parameter  int WIDTH = 32,
  parameter  int DEPTH = 8,

  localparam int  PTR_WIDTH = $clog2(DEPTH)
) (
  input              clk_i,
  input              rst_ni,

  input              push_i,
  output             full_o,
  input  [WIDTH-1:0] data_i,

  input              pop_i,
  output             empty_o,
  output [WIDTH-1:0] data_o
);

  wire wr = push_i;
  wire rd = pop_i;

  logic [PTR_WIDTH:0] wr_ptr;
  logic [PTR_WIDTH:0] rd_ptr;

  always_ff @(posedge clk_i) begin
    if (~rst_ni) wr_ptr <= '0;
    else if (wr) wr_ptr <= wr_ptr + 1;
  end

  always_ff @(posedge clk_i) begin
    if (~rst_ni) rd_ptr <= '0;
    else if (rd) rd_ptr <= rd_ptr + 1;
  end

  wire ptr_cmp = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]);

  assign full_o  = ptr_cmp & (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]);
  assign empty_o = ptr_cmp & (wr_ptr[PTR_WIDTH] == rd_ptr[PTR_WIDTH]);

  logic [WIDTH-1:0] mem [DEPTH];

  always_ff @(posedge clk_i) begin
    if (wr)
      mem[wr_ptr[PTR_WIDTH-1:0]] <= data_i;
  end

  // TODO: output flop
  assign data_o = mem[rd_ptr[PTR_WIDTH-1:0]];

endmodule
