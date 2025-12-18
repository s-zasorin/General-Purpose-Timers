module pulse_sync (
  input  logic clk_i,
  input  logic a_i  ,
  output logic a_o
);

  logic [2:0] a_ff;

  always_ff @(posedge clk_i) begin
    a_ff[0] <= a_i    ;
    a_ff[1] <= a_ff[0];
    a_ff[2] <= a_ff[1];
  end

  assign a_o = a_ff[2] ^ a_ff[1];
endmodule