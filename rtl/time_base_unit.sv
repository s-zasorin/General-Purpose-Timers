module time_base_unit # (parameter CNT_WIDTH = 32,
                         parameter ARR_WIDTH = 32,
                         parameter PSC_WIDTH = 16) (
  input  logic                   clk_i    ,
  input  logic                   aresetn_i,
  input  logic [CNT_WIDTH - 1:0] cnt_i    ,
  input  logic                   cen_i    ,
  input  logic [ARR_WIDTH - 1:0] arr_i    ,
  input  logic [PSC_WIDTH - 1:0] psc_i    ,
  input  logic                   dir_i    ,
  input  logic                   apre_i   ,
  input  logic [1:0]             cms_i    ,
  input  logic                   udis_i   ,
  input  logic                   ug_i     ,

  output logic                   uif_o    ,
  output logic                   uev_o    ,
  output logic [CNT_WIDTH - 1:0] cnt_o
);

  logic [CNT_WIDTH - 1:0] gen_cnt           ;
  logic                   cnt_en_ff         ;
  logic [CNT_WIDTH - 1:0] cnt_next          ;
  logic [ARR_WIDTH - 1:0] arr_shadow_reg    ;
  logic [ARR_WIDTH - 1:0] arr_compare_reg   ;
  logic [PSC_WIDTH - 1:0] psc_shadow_reg    ;
  logic                   enable_preload_arr;

  always_ff @(posedge clk_i)
    cnt_en_ff <= cen_i;

  always_ff @(posedge clk_i)
    enable_preload_arr <= apre_i;

// Preload ARR

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      arr_shadow_reg <= {ARR_WIDTH{1'b0}};
    else if ((~dir_i  && (gen_cnt == (arr_shadow_reg - 'b1)) && ~udis_i) || (dir_i && (gen_cnt == ({CNT_WIDTH{1'b0}} + 'b1)) && ~udis_i))
      arr_shadow_reg <= arr_i;

// Preload PSC
  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      psc_shadow_reg <= {PSC_WIDTH{1'b0}};
    else if ((~dir_i  && (gen_cnt == (arr_shadow_reg - 'b1)) && ~udis_i) || (dir_i && (gen_cnt == ({CNT_WIDTH{1'b0}} + 'b1)) && ~udis_i))
      psc_shadow_reg <= psc_i;

// UEV logic
  always_ff @(posedge clk_i)
    if (ug_i)
      uev_o <= 1'b1;
    else if (~dir_i  && (gen_cnt == arr_shadow_reg  ) && ~udis_i)
      uev_o <= 1'b1;
    else if (dir_i && (gen_cnt == {CNT_WIDTH{1'b0}}) && ~udis_i)
      uev_o <= 1'b1;
    else
      uev_o <= 1'b0;

// General counter logic
  always_ff @(posedge clk_i or negedge aresetn_i) begin
    if (~aresetn_i)
      gen_cnt <= {CNT_WIDTH{1'b0}};
    else if (ug_i)
      gen_cnt <= (~dir_i || cms_i == 2'b0) ? {CNT_WIDTH{1'b0}} : arr_shadow_reg;
    else if (cnt_en_ff)
      gen_cnt <= cnt_next;
    if (dir_i) begin
    end
    if (gen_cnt == arr_shadow_reg)
      gen_cnt <= {CNT_WIDTH{1'b0}};
  end

  always_comb begin
    if (dir_i)
      cnt_next = gen_cnt - 'd1;
    else begin
      case (cms_i)
        2'b00: cnt_next = gen_cnt + 'd1;
        2'b01, 2'b10, 2'b11: begin
          if (uev_o & (gen_cnt = {CNT_WIDTH{1'b0}}))
            cnt_next = gen_cnt + 1'b1;
        end
      endcase
    end
  end
    
endmodule