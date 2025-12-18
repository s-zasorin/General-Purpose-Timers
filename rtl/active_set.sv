module active_set #(parameter CH_PAIRS_NUM = 2,
                    parameter CNT_WIDTH    = 32,
                    parameter PSC_WIDTH    = 32) (
  input logic clk_i ,
  input logic rstn_i,
  input logic copy_i,
  // ### PROGRAM SET ###

  // TIM_CR1
  input logic       cen_i                    ,
  input logic       udis_i                   ,
  input logic       opm_i                    ,
  input logic [1:0] cms_i                    ,
  input logic       apre_i                   ,
  input logic [1:0] ckd_i                    ,

  // TIM_CR2
  input logic       ti1s_i                   ,
  input logic [2:0] mms_i                    ,
  input logic       ccds_i                   ,

  // TIM_EGR
  input logic       ug_i                     ,
  input logic       tg_i                     ,

  // TIM_CCMR
  input logic [1:0] icxpsc_i [2 * CH_PAIRS_NUM - 1:0],
  input logic [3:0] icxf_i   [2 * CH_PAIRS_NUM - 1:0],
  input logic       ocxfe_i  [2 * CH_PAIRS_NUM - 1:0],
  input logic       ocxpe_i  [2 * CH_PAIRS_NUM - 1:0],
  input logic [2:0] ocxm_i   [2 * CH_PAIRS_NUM - 1:0],
  input logic       ocxce_i  [2 * CH_PAIRS_NUM - 1:0],
  input logic [1:0] ccxs_i   [2 * CH_PAIRS_NUM - 1:0],

  // TIM_CCER
  input logic [2 * CH_PAIRS_NUM - 1:0] ccxe_i ,
  input logic [2 * CH_PAIRS_NUM - 1:0] ccxp_i ,
  input logic [2 * CH_PAIRS_NUM - 1:0] ccxnp_i,

  // TIM_DIER
  input logic                          uie_i  ,
  input logic [2 * CH_PAIRS_NUM - 1:0] ccxie_i,
  input logic                          tie_i  ,
  input logic                          ude_i  ,
  input logic [2 * CH_PAIRS_NUM - 1:0] ccxde_i,
  input logic                          tde_i  ,

  // TIM_ARR 
  input logic [CNT_WIDTH        - 1:0] arr_i  ,

  // TIM_PSC 
  input logic [PSC_WIDTH        - 1:0] psc_i  ,

  // TIM_CNT
  input logic [CNT_WIDTH        - 1:0] cnt_i ,

  // TIM_SMCR
  input logic [2:0]                    sms_i ,
  input logic [2:0]                    ts_i  ,
  input logic                          msm_i ,
  input logic [3:0]                    etf_i ,
  input logic [1:0]                    etps_i,
  input logic                          ece_i ,
  input logic                          etp_i ,

  // ### ACTIVE SET ###

  // TIM_CR1
  output logic                          udis_o,
  output logic                          opm_o ,
  output logic [1:0]                    cms_o ,
  output logic                          apre_o,
  output logic [1:0]                    ckd_o ,

  // TIM_CR2
  output logic                          ti1s_o, 
  output logic [2:0]                    mms_o ,  
  output logic                          ccds_o, 

  // TIM_EGR
  output logic                          ug_o  ,
  output logic                          tg_o  ,

  // TIM_CCMR
  output logic [1:0]                    icxpsc_o [2 * CH_PAIRS_NUM - 1:0],
  output logic [3:0]                    icxf_o   [2 * CH_PAIRS_NUM - 1:0],
  output logic                          ocxfe_o  [2 * CH_PAIRS_NUM - 1:0],
  output logic                          ocxpe_o  [2 * CH_PAIRS_NUM - 1:0],
  output logic [2:0]                    ocxm_o   [2 * CH_PAIRS_NUM - 1:0],
  output logic                          ocxce_o  [2 * CH_PAIRS_NUM - 1:0],
  output logic [1:0]                    ccxs_o   [2 * CH_PAIRS_NUM - 1:0],

  // TIM_CCER
  output logic [2 * CH_PAIRS_NUM - 1:0] ccxe_o ,
  output logic [2 * CH_PAIRS_NUM - 1:0] ccxp_o ,
  output logic [2 * CH_PAIRS_NUM - 1:0] ccxnp_o,

  // TIM_DIER
  output logic                          uie_o  ,
  output logic [2 * CH_PAIRS_NUM - 1:0] ccxie_o,
  output logic                          tie_o  ,
  output logic                          ude_o  ,
  output logic [2 * CH_PAIRS_NUM - 1:0] ccxde_o,
  output logic                          tde_o  ,

  // TIM_ARR
  output logic [CNT_WIDTH        - 1:0] arr_o  ,

  // TIM_PSC
  output logic [PSC_WIDTH        - 1:0] psc_o  ,

  // TIM_CNT
  output logic [CNT_WIDTH        - 1:0] cnt_o ,

  // TIM_SMCR
  output logic [2:0]                    sms_o ,
  output logic [2:0]                    ts_o  ,
  output logic                          msm_o ,
  output logic [3:0]                    etf_o ,
  output logic [1:0]                    etps_o,
  output logic                          ece_o ,
  output logic                          etp_o 
);

// TIM_CR1

  always_ff @(posedge clk_i)
    if (~rstn_i)
      udis_o <= 1'b0;
    else if (copy_i)
      udis_o <= udis_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      opm_o <= 1'b0;
    else if (copy_i)
      opm_o <= opm_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      cms_o <= 2'b0;
    else if (copy_i)
      cms_o <= cms_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      apre_o <= 1'b0;
    else if (copy_i)
      apre_o <= apre_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ckd_o <= 2'b0;
    else if (copy_i)
      ckd_o <= ckd_i;

// TIM_CR2
  always_ff @(posedge clk_i)
    if (~rstn_i)
      ti1s_o <= 1'b0;
    else if (copy_i)
      ti1s_o <= ti1s_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      mms_o <= 1'b0;
    else if (copy_i)
      mms_o <= mms_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ccds_o <= 1'b0;
    else if (copy_i)
      ccds_o <= ccds_i;

  // TIM_EGR

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ug_o <= 1'b0;
    else if (copy_i)
      ug_o <= ug_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      tg_o <= 1'b0;
    else if (copy_i)
      tg_o <= tg_i;

  generate
    for (genvar i = 0; i < 2 * CH_PAIRS_NUM; i++) begin
      always_ff @(posedge clk_i)
        if (~rstn_i)
          icxpsc_o[i] <= 'b0;
        else if (copy_i)
          icxpsc_o[i] <= icxpsc_i[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2 * CH_PAIRS_NUM; i++) begin
      always_ff @(posedge clk_i)
        if (~rstn_i)
          icxf_o[i] <= 'b0;
        else if (copy_i)
          icxf_o[i] <= icxf_i[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2 * CH_PAIRS_NUM; i++) begin
      always_ff @(posedge clk_i)
        if (~rstn_i)
          ocxfe_o[i] <= 'b0;
        else if (copy_i)
          ocxfe_o[i] <= ocxfe_i[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2 * CH_PAIRS_NUM; i++) begin
      always_ff @(posedge clk_i)
        if (~rstn_i)
          ocxpe_o[i] <= 'b0;
        else if (copy_i)
          ocxpe_o[i] <= ocxpe_i[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2 * CH_PAIRS_NUM; i++) begin
      always_ff @(posedge clk_i)
        if (~rstn_i)
          ocxce_o[i] <= 'b0;
        else if (copy_i)
          ocxce_o[i] <= ocxce_i[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2 * CH_PAIRS_NUM; i++) begin
      always_ff @(posedge clk_i)
        if (~rstn_i)
          ocxm_o[i] <= 'b0;
        else if (copy_i)
          ocxm_o[i] <= ocxm_i[i];
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2 * CH_PAIRS_NUM; i++) begin
      always_ff @(posedge clk_i)
        if (~rstn_i)
          ccxs_o[i] <= 'b0;
        else if (copy_i)
          ccxs_o[i] <= ccxs_i[i];
    end
  endgenerate

// TIM_CCER
  always_ff @(posedge clk_i)
    if (~rstn_i)
      ccxe_o <= 'b0;
    else if (copy_i)
      ccxe_o <= ccxe_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ccxp_o <= 'b0;
    else if (copy_i)
      ccxp_o <= ccxp_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ccxnp_o <= 'b0;
    else if (copy_i)
      ccxnp_o <= ccxnp_i;

// TIM_DIER

  always_ff @(posedge clk_i)
    if (~rstn_i)
      uie_o <= 'b0;
    else if (copy_i)
      uie_o <= uie_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ccxie_o <= 'b0;
    else if (copy_i)
      ccxie_o <= ccxie_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      tie_o <= 'b0;
    else if (copy_i)
      tie_o <= tie_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ude_o <= 'b0;
    else if (copy_i)
      ude_o <= ude_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ccxde_o <= 'b0;
    else if (copy_i)
      ccxde_o <= ccxde_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      tde_o <= 'b0;
    else if (copy_i)
      tde_o <= tde_i;

  // TIM_ARR
  always_ff @(posedge clk_i)
    if (~rstn_i)
      arr_o <= 'b0;
    else if (copy_i)
      arr_o <= arr_i;

  // TIM_PSC
  always_ff @(posedge clk_i)
    if (~rstn_i)
      psc_o <= 'b0;
    else if (copy_i)
      psc_o <= psc_i;

  // TIM_CNT
  always_ff @(posedge clk_i)
    if (~rstn_i)
      cnt_o <= 'b0;
    else if (copy_i)
      cnt_o <= cnt_i;

  // TIM_SMCR
  always_ff @(posedge clk_i)
    if (~rstn_i)
      sms_o <= 'b0;
    else if (copy_i)
      sms_o <= sms_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ts_o <= 'b0;
    else if (copy_i)
      ts_o <= ts_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      msm_o <= 'b0;
    else if (copy_i)
      msm_o <= msm_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      etf_o <= 'b0;
    else if (copy_i)
      etf_o <= etf_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      etps_o <= 'b0;
    else if (copy_i)
      etps_o <= etps_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      ece_o <= 'b0;
    else if (copy_i)
      ece_o <= ece_i;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      etp_o <= 'b0;
    else if (copy_i)
      etp_o <= etp_i;

endmodule