module digital_filter (
  input       logic clk_i    ,
  input       logic a_i      ,
  input       logic aresetn_i,
  input [3:0] logic icf_i    ,

  output      logic af_o
);

  logic [3:0] cnt_in;
  logic [3:0] cnt_out;

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      cnt_in <= 'b0;
    else if (cnt_in == icf_i)
      cnt_in <= 'b0
    else if (a_i)
      cnt_in <= cnt_in + 'b1;

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      cnt_out <= 'b0;
    else if (cnt_in == icf_i)
      cnt_out <= icf_i;
    else if (cnt_in != icf_i)
      cnt_out <= cnt_out - 'b1;

assign af_o = (cnt_out != 'b0);

endmodule