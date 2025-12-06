module prescaler #(parameter PSC_WIDTH = 16) (
  input  logic                   clk_i       ,
  input  logic                   clk_psc_en_i,
  input  logic                   rst_i       ,
  input  logic                   uev_i       ,
  input  logic [PSC_WIDTH - 1:0] psc_i       ,

  output logic                   clk_o
);
  logic [PSC_WIDTH - 1:0] psc_shadow_reg;
  logic [PSC_WIDTH - 1:0] cnt;

  always_ff @(posedge clk_i)
    if (rst_i)
      psc_shadow_reg <= {PSC_WIDTH{1'b0}};
    else if (uev_i)
      psc_shadow_reg <= psc_i            ;
  
  always_ff @(posedge clk_i)
    if (rst_i)
      cnt <= {PSC_WIDTH{1'b0}};
    else if (clk_psc_en_i) begin
      if (cnt == psc_shadow_reg)
        cnt <= {PSC_WIDTH{1'b0}};
      else
        cnt <= cnt + 'b1;
    end
  
  assign clk_o = (psc_shadow_reg == 'b0) ? clk_i : (cnt == psc_shadow_reg);
endmodule