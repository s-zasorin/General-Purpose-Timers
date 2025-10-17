module time_base_unit # (parameter CNT_WIDTH = 32,
                         parameter ARR_WIDTH = 32) (
  input  logic                   clk_i    ,
  input  logic                   aresetn_i,
  input  CSR_GPT__out_t          hw_i     ,
  output logic                   uev_o    ,
  output logic [CNT_WIDTH - 1:0] cnt_o
);

  logic [CNT_WIDTH - 1:0] gen_cnt           ;
  logic                   cnt_en_ff         ;
  logic [CNT_WIDTH - 1:0] cnt_next          ;
  logic [ARR_WIDTH - 1:0] arr_shadow_reg    ;
  logic [ARR_WIDTH - 1:0] arr_compare_reg   ;
  logic                   enable_preload_arr;
  logic                   disable_uev       ;

  always_ff @(posedge clk_i)
    cnt_en_ff <= hw_i.TIM_CR1.CEN;

  always_ff @(posedge clk_i)
    enable_preload_arr <= hw_i.TIM_CR1.APRE;

  always_ff @(posedge clk_i)
    disable_uev <= hw_i.TIM_CR1.UDIS;

// UEV logic
  always_ff @(posedge clk_i)
    if (hw_i.TIMx_EGR.UG)
      uev_o <= 1'b1;
    else if (DIR) begin
      if ((gen_cnt == arr_compare_reg) && ~disable_uev)
        uev_o <= 1'b1;
    end
    else begin
      if ((gen_cnt == {CNT_WIDTH{1'b0}}) && ~disable_uev)
        uev_o <= 1'b1;
    end
    else
      uev_o <= 1'b0;

// General counter logic
  always_ff @(posedge clk_i or negedge aresetn_i) begin
    if (~aresetn_i)
      gen_cnt <= {CNT_WIDTH{1'b0}};
    else if (hw_i.TIMx_EGR.UG)
      gen_cnt <= 
    else if (cnt_en_ff)
      gen_cnt <= cnt_next;
    if (gen_cnt == arr_compare_reg)
      gen_cnt <= {CNT_WIDTH{1'b0}};
  end

  always_comb begin
    if (DIR)
      cnt_next = gen_cnt - 'd1;
    else begin
      case (hw_i.TIM_CR1.CMS)
        2'b00: cnt_next = gen_cnt + 'd1;
        2'b01, 2'b10, 2'b11: begin
          if (uev_o & (gen_cnt = {CNT_WIDTH{1'b0}}))
            cnt_next = gen_cnt + 1'b1;
        end
      endcase
    end
  end
    
endmodule