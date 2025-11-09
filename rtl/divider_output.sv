module divider_output (
  input  logic       clk_i    ,
  input  logic       aresetn_i,
  input  logic       cce_i    ,
  input  logic [1:0] icps_i   ,

  output logic       clk_o
);

  logic [3:0] div_cnt;
  logic [3:0] div_value;

  always_comb begin
    case (icps_i)
      2'b00:   div_value = 4'b0;
      2'b01:   div_value = 4'd2;
      2'b10:   div_value = 4'd4;
      2'b11:   div_value = 4'd8;
      default: div_value = 4'd0;
    endcase
  end

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      div_cnt <= 4'b0;
    else if (div_cnt == div_value)
      div_cnt <= 4'b0;
    else
      div_cnt <= div_cnt + 'b1;
  
  assign clk_o = cce_i ? ((div_cnt == div_value) ? 1'b1 : 1'b0) : 1'b0;
endmodule