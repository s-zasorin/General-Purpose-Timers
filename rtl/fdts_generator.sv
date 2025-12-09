module fdts_generator (
  input  logic       clk_i,
  input  logic       rst_i,
  input  logic [1:0] ckd_i,

  output logic       clk_dts_o
);

  logic [1:0] cnt        ;
  logic       cg_enable  ;
  logic       gated_clock;

  always_ff @(posedge clk_i)
    if (rst_i)
      cnt <= 'b0;
    else if (cnt > ckd_i)
      cnt <= 'b0;
    else
      cnt <= cnt + 'b1;

  assign cg_enable = (cnt == ckd_i);

  clock_gate i_cg
  (
    .clk_i      (clk_i      ),
    .en_i       (cg_enable  ),
    .gated_clk_o(gated_clock)
  );

assign clk_dts_o = gated_clock;

endmodule