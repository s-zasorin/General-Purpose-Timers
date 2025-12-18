module stretch_signal #(parameter PSC_WIDTH = 16) (
  input  logic                   clk_i ,
  input  logic                   rstn_i,
  input  logic [PSC_WIDTH - 1:0] psc_i ,
  input  logic                   a_i   ,

  output logic                   a_o
);

  logic [2 * PSC_WIDTH - 1:0] cnt;
  logic                       limit;
  logic [2 * PSC_WIDTH - 1:0] extend_psc;

  enum logic {
    IDLE = 1'b0,
    CNT  = 1'b1
  } state_ff, next;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      state_ff <= IDLE;
    else
      state_ff <= next;
  
  always_comb begin
    next = state_ff;
    case (state_ff)
      IDLE: if (a_i)   next = CNT ;
      CNT : if (limit) next = IDLE;
    endcase
  end

  assign extend_psc = psc_i << 1'b1      ;
  assign limit      = (cnt == extend_psc);

  always_ff @(posedge clk_i) begin
    case (state_ff)
      IDLE: cnt <= {PSC_WIDTH{1'b0}};
      CNT : cnt <= cnt + 'b1;
    endcase
  end
  
  assign a_o = psc_i == 'b0 ? a_i : (state_ff == CNT) && (cnt != extend_psc);

endmodule