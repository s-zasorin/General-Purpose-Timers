module fdts_generator (
  input        logic clk_i    ,
  input        logic aresetn_i,
  input  [1:0] logic ckd_i    ,

  output       logic clk_dts_o
);

  logic [1:0] cnt;

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      cnt <= 'b0;
    else if (cnt == ckd_i)
      cnt <= 'b0;
    else
      cnt <= cnt + 'b1;

assign clk_dts_o = (cnt == ckd_i);

endmodule