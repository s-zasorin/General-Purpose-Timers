module divider_output (
  input  logic       clk_i  ,
  input  logic       ic_en_i,
  input  logic       rst_i  ,
  input  logic       cce_i  ,
  input  logic [1:0] icps_i ,

  output logic       clk_o
);

  logic [3:0] div_cnt    ;
  logic [3:0] div_value  ;
  logic       cg_enable  ;
  logic       gated_clock;

  always_comb begin
    case (icps_i)
      2'b00:   div_value = 4'b0;
      2'b01:   div_value = 4'd2;
      2'b10:   div_value = 4'd4;
      2'b11:   div_value = 4'd8;
      default: div_value = 4'd0;
    endcase
  end

  always_ff @(posedge clk_i)
    if (rst_i)
      div_cnt <= 4'b0;
    else if (ic_en_i) begin
      if (div_cnt > div_value)
        div_cnt <= 4'b0;
      else
        div_cnt <= div_cnt + 'b1;
    end
  
  assign cg_enable = (div_value == div_cnt) && ic_en_i;

  clock_gate i_cg
  (
    .clk_i      (clk_i      ),
    .en_i       (cg_enable  ),
    .gated_clk_o(gated_clock)
  );

  assign clk_o = cce_i ? gated_clock : 1'b0;

endmodule