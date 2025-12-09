module clock_gate (
  input  logic clk_i      ,
  input  logic en_i       ,
  output logic gated_clk_o
);

  logic n_latch_clk;

  always_latch begin
    if (~clk_i)
      n_latch_clk = en_i;
  end

  assign gated_clk_o = n_latch_clk & clk_i;

endmodule