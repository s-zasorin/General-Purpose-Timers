module digital_filter (
  input logic       clk_i    ,
  input logic       a_i      ,
  input logic       rstn_i   ,
  input logic [3:0] f_coef_i ,

  output      logic af_o
);

  logic [3:0] cnt        ;
  logic       start_pulse;
  logic       end_pulse  ;

  enum logic [1:0] {
    IDLE    = 2'b00,
    CNT_IN  = 2'b01,
    CNT_OUT = 2'b10
  } state_ff, next;

  edge_detector i_detect_impulse
  (
    .clk_i      (clk_i      ),
    .rstn_i     (rstn_i     ),
    .a_i        (a_i        ),
    .edge_rise_o(start_pulse),
    .edge_fall_o(end_pulse  )
  );

  always_ff @(posedge clk_i)
    if (~rstn_i)
      state_ff <= IDLE;
    else
      state_ff <= next;

  always_comb begin
    next = state_ff;
    case (state_ff)
      IDLE   :  if (start_pulse)                                            next = CNT_IN ;
      CNT_IN :  if (end_pulse && (cnt >= f_coef_i))                         next = CNT_OUT; 
                else if (end_pulse && (cnt < f_coef_i) || f_coef_i == 'hx)  next = IDLE   ;    
      CNT_OUT:  if (cnt == 4'b0)                                            next = IDLE   ;
    endcase
  end

  always_ff @(posedge clk_i)
    case (state_ff)
      IDLE   : cnt <= 4'b0      ;
      CNT_IN : cnt <= cnt + 4'b1;
      CNT_OUT: cnt <= cnt - 4'b1;
    endcase

assign af_o = (state_ff == CNT_OUT);

endmodule