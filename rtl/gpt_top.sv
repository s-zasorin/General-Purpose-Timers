module gpt_top 
#(parameter CH_PAIRS_NUM = 2,
  parameter CNT_WIDTH    = 32,
  parameter PSC_WIDTH    = 16,
  parameter CSR_WIDTH    = 32,
  parameter WSTRB_WIDTH  = CSR_WIDTH / 8) 
(
  input  logic                      aclk_i   ,
  input  logic                      aresetn_i,

  input  logic                      etr_i,
  input  logic [CH_PAIRS_NUM - 1:0] ch_i ,
  output logic                      trg_o,
  output logic [CH_PAIRS_NUM - 1:0] ch_o ,
);

logic [2 * CH_PAIRS_NUM - 1:0] internal_triggers;
logic                          trigger          ;
logic                          ti1f_ed          ;
logic                          trc              ;
logic                          itr              ;
logic                          etrf             ;
logic                          etrp             ;
logic                          clk_psc          ;  // clock prescaler
logic                          clk_cnt          ;  // clock counter

// regblock interface
CSR_GPT_pkg::CSR_GPT__in_t  gpt_hwif_in;
CSR_GPT_pkg::CSR_GPT__out_t gpt_hwif_out;

// TIM_CR1
logic       cen;
logic       urs;
logic       udis;
logic       opm;
logic       dir;
logic [1:0] cms;
logic       apre;
logic       ckd;

assign cen  = gpt_hwif_out.TIM_CR1.CEN.value ;
assign urs  = gpt_hwif_out.TIM_CR1.URS.value ;
assign opm  = gpt_hwif_out.TIM_CR1.OPM.value ;
assign dir  = gpt_hwif_out.TIM_CR1.DIR.value ;
assign cms  = gpt_hwif_out.TIM_CR1.CMS.value ;
assign apre = gpt_hwif_out.TIM_CR1.APRE.value;
assign ckd  = gpt_hwif_out.TIM_CR1.CKD.value ;

// TIM_CR2
logic       ti1s;
logic [2:0] mms ;
logic       ccds;

assign ti1s = gpt_hwif_out.TIM_CR2.value     ;
assign mms  = gpt_hwif_out.TIM_CR2.MMS.value ;
assign ccds = gpt_hwif_out.TIM_CR2.CCDS.value;

// TIM_EGR
generate
  if (CH_PAIRS_NUM == 1) begin: one_tim_egr
    logic        ug  ;
    logic  [1:0] ccxg;
    logic        tg  ;

    assign ug      = gpt_hwif_out.TIM_EGR.UG.value  ;
    assign ccxg[0] = gpt_hwif_out.TIM_EGR.CC1G.value;
    assign ccxg[1] = gpt_hwif_out.TIM_EGR.CC2G.value;
  end
  else if (CH_PAIRS_NUM == 2) begin: two_tim_egr
    logic       ug  ;
    logic [3:0] ccxg;
    logic       tg  ;

    assign ug      = gpt_hwif_out.TIM_EGR.UG.value  ;
    assign ccxg[0] = gpt_hwif_out.TIM_EGR.CC1G.value;
    assign ccxg[1] = gpt_hwif_out.TIM_EGR.CC2G.value;
    assign ccxg[2] = gpt_hwif_out.TIM_EGR.CC3G.value;
    assign ccxg[3] = gpt_hwif_out.TIM_EGR.CC4G.value;
  end
endgenerate

// TIM_CCRx
generate
  if (CH_PAIRS_NUM == 1) begin: two_ccr_regs
    logic [CNT_WIDTH - 1:0] ccs_reg [1:0];
    
    assign ccs_reg[0] = gpt_hwif_out.TIM_CCR1.value;
    assign ccs_reg[1] = gpt_hwif_out.TIM_CCR2.value; 
  end
  else if (CH_PAIRS_NUM == 2) begin: four_ccr_regs
    logic [CNT_WIDTH - 1:0] ccs_reg [3:0];

    assign ccs_reg[0] = gpt_hwif_out.TIM_CCR1.value;
    assign ccs_reg[1] = gpt_hwif_out.TIM_CCR2.value; 
    assign ccs_reg[2] = gpt_hwif_out.TIM_CCR3.value;
    assign ccs_reg[3] = gpt_hwif_out.TIM_CCR4.value;
  end
endgenerate

// TIM_CCMRx
generate
  if (CH_PAIRS_NUM == 1) begin: one_ccmr_reg
    logic [1:0] ccxs          [1:0];
    logic       ocxfe_icxpsc0 [1:0];
    logic       ocxce_icxf3   [1:0];
    logic       ocxpe_icxpsc1 [1:0];
    logic [2:0] ocxm_icxf     [1:0];


    assign ccxs         [0] = gpt_hwif_out.TIM_CCMR1.CC1S.value         ;
    assign ocxfe_icxpsc0[0] = gpt_hwif_out.TIM_CCMR1.OC1FE_IC1PSC0.value;
    assign ocxpe_icxpsc1[0] = gpt_hwif_out.TIM_CCMR1.OC1PE_IC1PSC1.value;
    assign ocxm_icxf    [0] = gpt_hwif_out.TIM_CCMR1.OC1M_IC1F.value    ;
    assign ocxce_icxf3  [0] = gpt_hwif_out.TIM_CCMR1.OC1CE_IC1F3.value  ;
    assign ccxs         [1] = gpt_hwif_out.TIM_CCMR1.CC2S.value         ;
    assign ocxfe_icxpsc0[1] = gpt_hwif_out.TIM_CCMR1.OC2FE_IC2PSC0.value;
    assign ocxpe_icxpsc1[1] = gpt_hwif_out.TIM_CCMR1.OC2PE_IC2PSC1.value;
    assign ocxm_icxf    [1] = gpt_hwif_out.TIM_CCMR1.OC2M_IC2F.value    ;
    assign ocxce_icxf3  [1] = gpt_hwif_out.TIM_CCMR1.OC2CE_IC2F3.value  ;

    // Input Channel
    logic [1:0] icxpsc [1:0];
    logic [3:0] icxf   [1:0];

    //Output Channel
    logic       ocxfe [1:0];
    logic       ocxpe [1:0];
    logic [2:0] ocxm  [1:0];
    logic       ocxce [1:0];

    always_comb begin
      for (int i = 0; i < CH_PAIRS_NUM * 2; i = i + 1) begin
        if (ccxs[i] == 2'b00) begin
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];
        end
        else begin
          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
        end
      end
    end
  end
  else if (CH_PAIRS_NUM == 2) begin: two_ccmr_regs
    logic [1:0] ccxs          [3:0];
    logic       ocxfe_icxpsc0 [3:0];
    logic       ocxce_icxf3   [3:0];
    logic       ocxpe_icxpsc1 [3:0];
    logic [2:0] ocxm_icxf     [3:0];


    assign ccxs         [0] = gpt_hwif_out.TIM_CCMR1.CC1S.value         ;
    assign ocxfe_icxpsc0[0] = gpt_hwif_out.TIM_CCMR1.OC1FE_IC1PSC0.value;
    assign ocxpe_icxpsc1[0] = gpt_hwif_out.TIM_CCMR1.OC1PE_IC1PSC1.value;
    assign ocxm_icxf    [0] = gpt_hwif_out.TIM_CCMR1.OC1M_IC1F.value    ;
    assign ocxce_icxf3  [0] = gpt_hwif_out.TIM_CCMR1.OC1CE_IC1F3.value  ;
    assign ccxs         [1] = gpt_hwif_out.TIM_CCMR1.CC2S.value         ;
    assign ocxfe_icxpsc0[1] = gpt_hwif_out.TIM_CCMR1.OC2FE_IC2PSC0.value;
    assign ocxpe_icxpsc1[1] = gpt_hwif_out.TIM_CCMR1.OC2PE_IC2PSC1.value;
    assign ocxm_icxf    [1] = gpt_hwif_out.TIM_CCMR1.OC2M_IC2F.value    ;
    assign ocxce_icxf3  [1] = gpt_hwif_out.TIM_CCMR1.OC2CE_IC2F3.value  ;
    assign ccxs         [2] = gpt_hwif_out.TIM_CCMR2.CC1S.value         ;
    assign ocxfe_icxpsc0[2] = gpt_hwif_out.TIM_CCMR2.OC1FE_IC1PSC0.value;
    assign ocxpe_icxpsc1[2] = gpt_hwif_out.TIM_CCMR2.OC1PE_IC1PSC1.value;
    assign ocxm_icxf    [2] = gpt_hwif_out.TIM_CCMR2.OC1M_IC1F.value    ;
    assign ocxce_icxf3  [2] = gpt_hwif_out.TIM_CCMR2.OC1CE_IC1F3.value  ;
    assign ccxs         [3] = gpt_hwif_out.TIM_CCMR2.CC2S.value         ;
    assign ocxfe_icxpsc0[3] = gpt_hwif_out.TIM_CCMR2.OC2FE_IC2PSC0.value;
    assign ocxpe_icxpsc1[3] = gpt_hwif_out.TIM_CCMR2.OC2PE_IC2PSC1.value;
    assign ocxm_icxf    [3] = gpt_hwif_out.TIM_CCMR2.OC2M_IC2F.value    ;
    assign ocxce_icxf3  [3] = gpt_hwif_out.TIM_CCMR2.OC2CE_IC2F3.value  ;

    // Input Channel
    logic [1:0] icxpsc [3:0];
    logic [3:0] icxf   [3:0];

    //Output Channel
    logic       ocxfe [3:0];
    logic       ocxpe [3:0];
    logic [2:0] ocxm  [3:0];
    logic       ocxce [3:0];

    always_comb begin
      for (int i = 0; i < CH_PAIRS_NUM * 2; i = i + 1) begin
        if (ccxs[i] == 2'b00) begin
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];
        end
        else begin
          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
        end
      end
    end
  end
endgenerate

// TIM_CCER 
logic [3:0] ccxe ;
logic [3:0] ccxp ;
logic [3:0] ccxnp;

assign ccxe [0] = gpt_hwif_out.TIM_CCER.CC1E.value ;
assign ccxp [0] = gpt_hwif_out.TIM_CCER.CC1P.value ;
assign ccxnp[0] = gpt_hwif_out.TIM_CCER.CC1NP.value;
assign ccxe [1] = gpt_hwif_out.TIM_CCER.CC2E.value ;
assign ccxp [1] = gpt_hwif_out.TIM_CCER.CC2P.value ;
assign ccxnp[1] = gpt_hwif_out.TIM_CCER.CC2NP.value;
assign ccxe [2] = gpt_hwif_out.TIM_CCER.CC3E.value ;
assign ccxp [2] = gpt_hwif_out.TIM_CCER.CC3P.value ;
assign ccxnp[2] = gpt_hwif_out.TIM_CCER.CC3NP.value;
assign ccxe [3] = gpt_hwif_out.TIM_CCER.CC4E.value ;
assign ccxp [3] = gpt_hwif_out.TIM_CCER.CC4P.value ;
assign ccxnp[3] = gpt_hwif_out.TIM_CCER.CC4NP.value;

// TIM_DIER
logic       uie  ;
logic [3:0] ccxie;
logic       tie  ;
logic       ude  ;
logic [3:0] ccxde;
logic       tde  ;

assign uie      = gpt_hwif_out.TIM_DIER.UIE.value  ;
assign ccxie[0] = gpt_hwif_out.TIM_DIER.CC1E.value ;
assign ccxie[1] = gpt_hwif_out.TIM_DIER.CC2E.value ;
assign ccxie[2] = gpt_hwif_out.TIM_DIER.CC3E.value ;
assign ccxie[3] = gpt_hwif_out.TIM_DIER.CC4E.value ;
assign tie      = gpt_hwif_out.TIM_DIER.TIE.value  ;
assign ude      = gpt_hwif_out.TIM_DIER.UDE.value  ;
assign ccxde[0] = gpt_hwif_out.TIM_DIER.CC1DE.value;
assign ccxde[1] = gpt_hwif_out.TIM_DIER.CC2DE.value;
assign ccxde[2] = gpt_hwif_out.TIM_DIER.CC3DE.value;
assign ccxde[3] = gpt_hwif_out.TIM_DIER.CC4DE.value;
assign tde      = gpt_hwif_out.TIM_DIER.TDE.value  ;

// TIM_SR
logic       uif  ;
logic [3:0] ccxif;
logic       tif  ;
logic [3:0] ccxof;


// TIM_ARR
logic [CNT_WIDTH - 1:0] arr;
assign arr = gpt_hwif_out.TIM_ARR.value;

// TIM_PSC
logic [PSC_WIDTH - 1:0] psc;
assign psc = gpt_hwif_out.TIM_PSC.value;

// TIM_SMCR
logic [2:0] sms ;
logic [2:0] ts  ; 
logic       msm ;
logic [2:0] etf ;
logic [1:0] etps;
logic       ece ;
logic       etp ;

assign sms  = gpt_hwif_out.TIM_SMCR.SMS.value ;
assign ts   = gpt_hwif_out.TIM_SMCR.TS.value  ;
assign msm  = gpt_hwif_out.TIM_SMCR.MSM.value ;
assign etf  = gpt_hwif_out.TIM_SMCR.ETF.value ;
assign etps = gpt_hwif_out.TIM_SMCR.ETPS.value;
assign ece  = gpt_hwif_out.TIM_SMCR.ECE.value ;
assign etp  = gpt_hwif_out.TIM_SMCR.ETP.value ;

trigger_controller trig_inst 
(
  .clk_i    (aclk_i           ),
  .aresetn_i(aresetn_i        ),
  .itr_i    (internal_triggers),
  .ckd_i    (ckd              ),
  .etp_i    (etp              ),
  .sms_i    (sms              ),
  .etps_i   (etps             ),
  .ts_i     (ts               ),
  .etf_i    (etf              ),
  .ece_i    (ece              ),
  .ti2fp2_i (),
  .ti1fp1_i (),
  .ti1_ed_i (ti1f_ed          ),
  .etr_i    (etr_i            ),
  .trg_o    (trg_o            ),
  .clk_psc_o(clk_psc          )
);

prescaler #(.PSC_WIDTH(PSC_WIDTH))
(
  .clk_i    (clk_psc  ),
  .aresetn_i(aresetn_i),
  .uev_i    (uev      ),
  .psc_i    (psc      ),
  .clk_o    (clk_cnt  )
);

logic [CNT_WIDTH - 1:0] cnt_value;
logic                   uev      ;

time_base_unit time_base_inst
(
  .clk_i    (clk_cnt  ),
  .aresetn_i(aresetn_i),
  .cen_i    (cen      ),
  .apre_i   (apre     ),
  .dir_i    (dir      ),
  .arr_i    (arr      ),
  .psc_i    (psc      ),
  .udis_i   (udis     ),
  .ug_i     (ug       ),
  .uif_o    (uif      ),
  .uev_o    (uev      ),
  .cnt_o    (cnt_value)
);

generate
  for (genvar i = 0; i < CH_PAIRS_NUM * 2; i++) begin : g_tim_ch
    tim_channel channel_inst
    (
      .clk_i    (aclk_i   ),
      .aresetn_i(aresetn_i),
      .ckd_i    (),
      .icf_i    (),
      .ti_i     (),
      .cnt_i    (cnt_value),
      .ti2fp1_i (),
      .cc1s_i   (),
      .trc_i    (),
      .icps_i   (),
      .cc1p_i   (),
      .cc1np_i  (),
      .ti1_fd_o (ti1f_ed),
      .ti1fp1_o (),
      .ti_o     (ch_o[i])
    );
  end
endgenerate
endmodule