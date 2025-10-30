module gpt_top 
#(parameter CH_PAIRS_NUM = 2,
  parameter CNT_WIDTH    = 32,
  parameter PSC_WIDTH    = 32,
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
    logic [1:0] cc1s         ;
    logic       oc1fe_ic1psc0;
    logic       oc1ce_ic1f3  ;
    logic       oc1pe_ic1psc1;
    logic       oc1m_ic1f    ;
    logic [1:0] cc2s         ;
    logic       oc2fe_ic2psc0;
    logic       oc2pe_ic2psc1;
    logic       oc2m_ic2f    ;
    logic       oc2ce_ic2f3  ;

    assign cc1s          = gpt_hwif_out.TIM_CCMR1.CC1S.value         ;
    assign oc1fe_ic1psc0 = gpt_hwif_out.TIM_CCMR1.OC1FE_IC1PSC0.value;
    assign oc1ce_ic1f3   = gpt_hwif_out.TIM_CCMR1.OC1CE_IC1F3.value  ;
    assign oc1pe_ic1psc1 = gpt_hwif_out.TIM_CCMR1.OC1PE_IC1PSC1.value;
    assign oc1m_ic1f     = gpt_hwif_out.TIM_CCMR1.OC1M_IC1F.value    ;
    assign cc2s          = gpt_hwif_out.TIM_CCMR1.CC2S.value         ;
    assign oc2fe_ic2psc0 = gpt_hwif_out.TIM_CCMR1.OC2FE_IC2PSC0.value;
    assign oc2pe_ic2psc1 = gpt_hwif_out.TIM_CCMR1.OC2PE_IC2PSC1.value;

  end
  else if (CH_PAIRS_NUM == 2) begin: two_ccmr_regs

  end
endgenerate

trigger_controller trig_inst 
(
  .clk_i    (aclk_i           ),
  .itr_i    (internal_triggers),
  .ti1_ed_i (ti1f_ed          ),
  .trg_o    (),
  .clk_psc_o(clk_psc          )
);

logic [CNT_WIDTH - 1:0] cnt_value;
logic                   uev      ;

time_base_unit time_base_inst
(
  .clk_i    (clk_cnt  ),
  .aresetn_i(aresetn_i),
  .cen_i    (cen      ),
  .apre_i   (apre     ),
  .udis_i   (udis     ),
  .ug_i     (ug       ),
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
      .ti1_fd_o (),
      .ti1fp1_o (),
      .ti_o     ()
    );
  end
endgenerate
endmodule