module sync_cell (
  input  logic clk_i,
  input  logic a_i  ,
  output logic a_o
);

  logic [1:0] a_ff;

  always_ff @(posedge clk_i) begin
    a_ff[0] <= a_i    ;
    a_ff[1] <= a_ff[0];
  end

  assign a_o = a_ff[1];
  
endmodule