module prescaler #(parameter PSC_WIDTH = 16) (
  input  logic                   clk_i       ,
  input  logic                   clk_psc_en_i,
  input  logic                   rstn_i      ,
  input  logic                   uev_i       ,
  input  logic [PSC_WIDTH - 1:0] psc_i       ,

  output logic                   clk_o
);
  logic [PSC_WIDTH - 1:0] psc_shadow_reg;
  logic [PSC_WIDTH - 1:0] cnt           ;
  logic                   cg_enable     ;
  logic                   gated_clock   ;

  always_ff @(posedge clk_i)
    if (rstn_i)
      psc_shadow_reg <= {PSC_WIDTH{1'b0}};
    else if (uev_i)
      psc_shadow_reg <= psc_i            ;
  
  always_ff @(posedge clk_i)
    if (rstn_i)
      cnt <= {PSC_WIDTH{1'b0}};
    else if (clk_psc_en_i) begin
      if (cnt == psc_shadow_reg)
        cnt <= {PSC_WIDTH{1'b0}};
      else
        cnt <= cnt + 'b1;
    end
  
  assign cg_enable = (cnt == psc_shadow_reg) && clk_psc_en_i;

  clock_gate i_cg
  (
    .clk_i      (clk_i      ),
    .en_i       (cg_enable  ),
    .gated_clk_o(gated_clock)
  );

  assign clk_o = gated_clock;
endmodule