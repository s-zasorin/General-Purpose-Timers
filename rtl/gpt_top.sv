module gpt_top 
#(parameter CH_PAIRS_NUM = 2 ,
  parameter CNT_WIDTH    = 32,
  parameter PSC_WIDTH    = 16,
  parameter CSR_WIDTH    = 32,
  parameter CCR_WIDTH    = 32,
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
  logic       cen;  // Counter enable
  logic       urs;
  logic       udis;
  logic       opm;
  logic       dir;
  logic [1:0] cms;
  logic       apre;
  logic [1:0] ckd;

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

  // TIM_CCERx 
  generate
    if (CH_PAIRS_NUM == 1 || CH_PAIRS_NUM == 2) begin
      logic [3:0] ccxe ;
      logic [3:0] ccxp ;
      logic [3:0] ccxnp;

      assign ccxe [0] = gpt_hwif_out.TIM_CCER1.CC1E.value ;
      assign ccxp [0] = gpt_hwif_out.TIM_CCER1.CC1P.value ;
      assign ccxnp[0] = gpt_hwif_out.TIM_CCER1.CC1NP.value;
      assign ccxe [1] = gpt_hwif_out.TIM_CCER1.CC2E.value ;
      assign ccxp [1] = gpt_hwif_out.TIM_CCER1.CC2P.value ;
      assign ccxnp[1] = gpt_hwif_out.TIM_CCER1.CC2NP.value;
      assign ccxe [2] = gpt_hwif_out.TIM_CCER1.CC3E.value ;
      assign ccxp [2] = gpt_hwif_out.TIM_CCER1.CC3P.value ;
      assign ccxnp[2] = gpt_hwif_out.TIM_CCER1.CC3NP.value;
      assign ccxe [3] = gpt_hwif_out.TIM_CCER1.CC4E.value ;
      assign ccxp [3] = gpt_hwif_out.TIM_CCER1.CC4P.value ;
      assign ccxnp[3] = gpt_hwif_out.TIM_CCER1.CC4NP.value;
    end
    else if (CH_PAIRS_NUM == 3 || CH_PAIRS_NUM == 4) begin
      logic [7:0] ccxe ;
      logic [7:0] ccxp ;
      logic [7:0] ccxnp;

      assign ccxe [0] = gpt_hwif_out.TIM_CCER1.CC1E.value ;
      assign ccxp [0] = gpt_hwif_out.TIM_CCER1.CC1P.value ;
      assign ccxnp[0] = gpt_hwif_out.TIM_CCER1.CC1NP.value;
      assign ccxe [1] = gpt_hwif_out.TIM_CCER1.CC2E.value ;
      assign ccxp [1] = gpt_hwif_out.TIM_CCER1.CC2P.value ;
      assign ccxnp[1] = gpt_hwif_out.TIM_CCER1.CC2NP.value;
      assign ccxe [2] = gpt_hwif_out.TIM_CCER1.CC3E.value ;
      assign ccxp [2] = gpt_hwif_out.TIM_CCER1.CC3P.value ;
      assign ccxnp[2] = gpt_hwif_out.TIM_CCER1.CC3NP.value;
      assign ccxe [3] = gpt_hwif_out.TIM_CCER1.CC4E.value ;
      assign ccxp [3] = gpt_hwif_out.TIM_CCER1.CC4P.value ;
      assign ccxnp[3] = gpt_hwif_out.TIM_CCER1.CC4NP.value;
      assign ccxe [4] = gpt_hwif_out.TIM_CCER2.CC1E.value ;
      assign ccxp [4] = gpt_hwif_out.TIM_CCER2.CC1P.value ;
      assign ccxnp[4] = gpt_hwif_out.TIM_CCER2.CC1NP.value;
      assign ccxe [5] = gpt_hwif_out.TIM_CCER2.CC2E.value ;
      assign ccxp [5] = gpt_hwif_out.TIM_CCER2.CC2P.value ;
      assign ccxnp[5] = gpt_hwif_out.TIM_CCER2.CC2NP.value;
      assign ccxe [6] = gpt_hwif_out.TIM_CCER2.CC3E.value ;
      assign ccxp [6] = gpt_hwif_out.TIM_CCER2.CC3P.value ;
      assign ccxnp[6] = gpt_hwif_out.TIM_CCER2.CC3NP.value;
      assign ccxe [7] = gpt_hwif_out.TIM_CCER2.CC4E.value ;
      assign ccxp [7] = gpt_hwif_out.TIM_CCER2.CC4P.value ;
      assign ccxnp[7] = gpt_hwif_out.TIM_CCER2.CC4NP.value;
    end
    else if (CH_PAIRS_NUM == 3 || CH_PAIRS_NUM == 4) begin
      logic [11:0] ccxe ;
      logic [11:0] ccxp ;
      logic [11:0] ccxnp;

      assign ccxe [0]  = gpt_hwif_out.TIM_CCER1.CC1E.value ;
      assign ccxp [0]  = gpt_hwif_out.TIM_CCER1.CC1P.value ;
      assign ccxnp[0]  = gpt_hwif_out.TIM_CCER1.CC1NP.value;
      assign ccxe [1]  = gpt_hwif_out.TIM_CCER1.CC2E.value ;
      assign ccxp [1]  = gpt_hwif_out.TIM_CCER1.CC2P.value ;
      assign ccxnp[1]  = gpt_hwif_out.TIM_CCER1.CC2NP.value;
      assign ccxe [2]  = gpt_hwif_out.TIM_CCER1.CC3E.value ;
      assign ccxp [2]  = gpt_hwif_out.TIM_CCER1.CC3P.value ;
      assign ccxnp[2]  = gpt_hwif_out.TIM_CCER1.CC3NP.value;
      assign ccxe [3]  = gpt_hwif_out.TIM_CCER1.CC4E.value ;
      assign ccxp [3]  = gpt_hwif_out.TIM_CCER1.CC4P.value ;
      assign ccxnp[3]  = gpt_hwif_out.TIM_CCER1.CC4NP.value;
      assign ccxe [4]  = gpt_hwif_out.TIM_CCER2.CC1E.value ;
      assign ccxp [4]  = gpt_hwif_out.TIM_CCER2.CC1P.value ;
      assign ccxnp[4]  = gpt_hwif_out.TIM_CCER2.CC1NP.value;
      assign ccxe [5]  = gpt_hwif_out.TIM_CCER2.CC2E.value ;
      assign ccxp [5]  = gpt_hwif_out.TIM_CCER2.CC2P.value ;
      assign ccxnp[5]  = gpt_hwif_out.TIM_CCER2.CC2NP.value;
      assign ccxe [6]  = gpt_hwif_out.TIM_CCER2.CC3E.value ;
      assign ccxp [6]  = gpt_hwif_out.TIM_CCER2.CC3P.value ;
      assign ccxnp[6]  = gpt_hwif_out.TIM_CCER2.CC3NP.value;
      assign ccxe [7]  = gpt_hwif_out.TIM_CCER2.CC4E.value ;
      assign ccxp [7]  = gpt_hwif_out.TIM_CCER2.CC4P.value ;
      assign ccxnp[7]  = gpt_hwif_out.TIM_CCER2.CC4NP.value;
      assign ccxe [8]  = gpt_hwif_out.TIM_CCER3.CC1E.value ;
      assign ccxp [8]  = gpt_hwif_out.TIM_CCER3.CC1P.value ;
      assign ccxnp[8]  = gpt_hwif_out.TIM_CCER3.CC1NP.value;
      assign ccxe [9]  = gpt_hwif_out.TIM_CCER3.CC2E.value ;
      assign ccxp [9]  = gpt_hwif_out.TIM_CCER3.CC2P.value ;
      assign ccxnp[9]  = gpt_hwif_out.TIM_CCER3.CC2NP.value;
      assign ccxe [10] = gpt_hwif_out.TIM_CCER3.CC3E.value ;
      assign ccxp [10] = gpt_hwif_out.TIM_CCER3.CC3P.value ;
      assign ccxnp[10] = gpt_hwif_out.TIM_CCER3.CC3NP.value;
      assign ccxe [11] = gpt_hwif_out.TIM_CCER3.CC4E.value ;
      assign ccxp [11] = gpt_hwif_out.TIM_CCER3.CC4P.value ;
      assign ccxnp[11] = gpt_hwif_out.TIM_CCER3.CC4NP.value;
    end
    else if (CH_PAIRS_NUM == 3 || CH_PAIRS_NUM == 4) begin
      logic [15:0] ccxe ;
      logic [15:0] ccxp ;
      logic [15:0] ccxnp;

      assign ccxe [0]  = gpt_hwif_out.TIM_CCER1.CC1E.value ;
      assign ccxp [0]  = gpt_hwif_out.TIM_CCER1.CC1P.value ;
      assign ccxnp[0]  = gpt_hwif_out.TIM_CCER1.CC1NP.value;
      assign ccxe [1]  = gpt_hwif_out.TIM_CCER1.CC2E.value ;
      assign ccxp [1]  = gpt_hwif_out.TIM_CCER1.CC2P.value ;
      assign ccxnp[1]  = gpt_hwif_out.TIM_CCER1.CC2NP.value;
      assign ccxe [2]  = gpt_hwif_out.TIM_CCER1.CC3E.value ;
      assign ccxp [2]  = gpt_hwif_out.TIM_CCER1.CC3P.value ;
      assign ccxnp[2]  = gpt_hwif_out.TIM_CCER1.CC3NP.value;
      assign ccxe [3]  = gpt_hwif_out.TIM_CCER1.CC4E.value ;
      assign ccxp [3]  = gpt_hwif_out.TIM_CCER1.CC4P.value ;
      assign ccxnp[3]  = gpt_hwif_out.TIM_CCER1.CC4NP.value;
      assign ccxe [4]  = gpt_hwif_out.TIM_CCER2.CC1E.value ;
      assign ccxp [4]  = gpt_hwif_out.TIM_CCER2.CC1P.value ;
      assign ccxnp[4]  = gpt_hwif_out.TIM_CCER2.CC1NP.value;
      assign ccxe [5]  = gpt_hwif_out.TIM_CCER2.CC2E.value ;
      assign ccxp [5]  = gpt_hwif_out.TIM_CCER2.CC2P.value ;
      assign ccxnp[5]  = gpt_hwif_out.TIM_CCER2.CC2NP.value;
      assign ccxe [6]  = gpt_hwif_out.TIM_CCER2.CC3E.value ;
      assign ccxp [6]  = gpt_hwif_out.TIM_CCER2.CC3P.value ;
      assign ccxnp[6]  = gpt_hwif_out.TIM_CCER2.CC3NP.value;
      assign ccxe [7]  = gpt_hwif_out.TIM_CCER2.CC4E.value ;
      assign ccxp [7]  = gpt_hwif_out.TIM_CCER2.CC4P.value ;
      assign ccxnp[7]  = gpt_hwif_out.TIM_CCER2.CC4NP.value;
      assign ccxe [8]  = gpt_hwif_out.TIM_CCER3.CC1E.value ;
      assign ccxp [8]  = gpt_hwif_out.TIM_CCER3.CC1P.value ;
      assign ccxnp[8]  = gpt_hwif_out.TIM_CCER3.CC1NP.value;
      assign ccxe [9]  = gpt_hwif_out.TIM_CCER3.CC2E.value ;
      assign ccxp [9]  = gpt_hwif_out.TIM_CCER3.CC2P.value ;
      assign ccxnp[9]  = gpt_hwif_out.TIM_CCER3.CC2NP.value;
      assign ccxe [10] = gpt_hwif_out.TIM_CCER3.CC3E.value ;
      assign ccxp [10] = gpt_hwif_out.TIM_CCER3.CC3P.value ;
      assign ccxnp[10] = gpt_hwif_out.TIM_CCER3.CC3NP.value;
      assign ccxe [11] = gpt_hwif_out.TIM_CCER3.CC4E.value ;
      assign ccxp [11] = gpt_hwif_out.TIM_CCER3.CC4P.value ;
      assign ccxnp[11] = gpt_hwif_out.TIM_CCER3.CC4NP.value;
      assign ccxe [12] = gpt_hwif_out.TIM_CCER4.CC1E.value ;
      assign ccxp [12] = gpt_hwif_out.TIM_CCER4.CC1P.value ;
      assign ccxnp[12] = gpt_hwif_out.TIM_CCER4.CC1NP.value;
      assign ccxe [13] = gpt_hwif_out.TIM_CCER4.CC2E.value ;
      assign ccxp [13] = gpt_hwif_out.TIM_CCER4.CC2P.value ;
      assign ccxnp[13] = gpt_hwif_out.TIM_CCER4.CC2NP.value;
      assign ccxe [14] = gpt_hwif_out.TIM_CCER4.CC3E.value ;
      assign ccxp [14] = gpt_hwif_out.TIM_CCER4.CC3P.value ;
      assign ccxnp[14] = gpt_hwif_out.TIM_CCER4.CC3NP.value;
      assign ccxe [15] = gpt_hwif_out.TIM_CCER4.CC4E.value ;
      assign ccxp [15] = gpt_hwif_out.TIM_CCER4.CC4P.value ;
      assign ccxnp[15] = gpt_hwif_out.TIM_CCER4.CC4NP.value;
    end
  endgenerate

  // TIM_DIER
  generate
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
  endgenerate
  // TIM_SR
  logic       uif  ;
  logic       tif  ;
  generate
    if (CH_PAIRS_NUM == 1 || CH_PAIRS_NUM == 2) begin
      logic [3:0] ccxif;
      logic [3:0] ccxof;

      assign gpt_hwif_in.TIM_SR1.CC1IF.next = ccxif[0];
      assign gpt_hwif_in.TIM_SR1.CC2IF.next = ccxif[1];
      assign gpt_hwif_in.TIM_SR1.CC3IF.next = ccxif[2];
      assign gpt_hwif_in.TIM_SR1.CC4IF.next = ccxif[3];

      assign gpt_hwif_in.TIM_SR1.CC1OF.next = ccxof[0];
      assign gpt_hwif_in.TIM_SR1.CC2OF.next = ccxof[1];
      assign gpt_hwif_in.TIM_SR1.CC3OF.next = ccxof[2];
      assign gpt_hwif_in.TIM_SR1.CC4OF.next = ccxof[3];
    end
    else if (CH_PAIRS_NUM == 3 || CH_PAIRS_NUM == 4) begin
      logic [7:0] ccxif;
      logic [7:0] ccxof;

      assign gpt_hwif_in.TIM_SR1.CC1IF.next = ccxif[0];
      assign gpt_hwif_in.TIM_SR1.CC2IF.next = ccxif[1];
      assign gpt_hwif_in.TIM_SR1.CC3IF.next = ccxif[2];
      assign gpt_hwif_in.TIM_SR1.CC4IF.next = ccxif[3];
      assign gpt_hwif_in.TIM_SR2.CC1IF.next = ccxif[4];
      assign gpt_hwif_in.TIM_SR2.CC2IF.next = ccxif[5];
      assign gpt_hwif_in.TIM_SR2.CC3IF.next = ccxif[6];
      assign gpt_hwif_in.TIM_SR2.CC4IF.next = ccxif[7];

      assign gpt_hwif_in.TIM_SR1.CC1OF.next = ccxof[0];
      assign gpt_hwif_in.TIM_SR1.CC2OF.next = ccxof[1];
      assign gpt_hwif_in.TIM_SR1.CC3OF.next = ccxof[2];
      assign gpt_hwif_in.TIM_SR1.CC4OF.next = ccxof[3];
      assign gpt_hwif_in.TIM_SR2.CC1OF.next = ccxof[4];
      assign gpt_hwif_in.TIM_SR2.CC2OF.next = ccxof[5];
      assign gpt_hwif_in.TIM_SR2.CC3OF.next = ccxof[6];
      assign gpt_hwif_in.TIM_SR2.CC4OF.next = ccxof[7];
    end
    else if (CH_PAIRS_NUM == 5 || CH_PAIRS_NUM == 6) begin
      logic [11:0] ccxif;
      logic [11:0] ccxof;

      assign gpt_hwif_in.TIM_SR1.CC1IF.next = ccxif[0];
      assign gpt_hwif_in.TIM_SR1.CC2IF.next = ccxif[1];
      assign gpt_hwif_in.TIM_SR1.CC3IF.next = ccxif[2];
      assign gpt_hwif_in.TIM_SR1.CC4IF.next = ccxif[3];
      assign gpt_hwif_in.TIM_SR2.CC1IF.next = ccxif[4];
      assign gpt_hwif_in.TIM_SR2.CC2IF.next = ccxif[5];
      assign gpt_hwif_in.TIM_SR2.CC3IF.next = ccxif[6];
      assign gpt_hwif_in.TIM_SR2.CC4IF.next = ccxif[7];
      assign gpt_hwif_in.TIM_SR3.CC1IF.next = ccxif[8];
      assign gpt_hwif_in.TIM_SR3.CC2IF.next = ccxif[9];
      assign gpt_hwif_in.TIM_SR3.CC3IF.next = ccxif[10];
      assign gpt_hwif_in.TIM_SR3.CC4IF.next = ccxif[11];

      assign gpt_hwif_in.TIM_SR1.CC1OF.next = ccxof[0];
      assign gpt_hwif_in.TIM_SR1.CC2OF.next = ccxof[1];
      assign gpt_hwif_in.TIM_SR1.CC3OF.next = ccxof[2];
      assign gpt_hwif_in.TIM_SR1.CC4OF.next = ccxof[3];
      assign gpt_hwif_in.TIM_SR2.CC1OF.next = ccxof[4];
      assign gpt_hwif_in.TIM_SR2.CC2OF.next = ccxof[5];
      assign gpt_hwif_in.TIM_SR2.CC3OF.next = ccxof[6];
      assign gpt_hwif_in.TIM_SR2.CC4OF.next = ccxof[7];
      assign gpt_hwif_in.TIM_SR3.CC1OF.next = ccxof[8];
      assign gpt_hwif_in.TIM_SR3.CC2OF.next = ccxof[9];
      assign gpt_hwif_in.TIM_SR3.CC3OF.next = ccxof[10];
      assign gpt_hwif_in.TIM_SR3.CC4OF.next = ccxof[11];
    end
    else if (CH_PAIRS_NUM == 7 || CH_PAIRS_NUM == 8) begin
      logic [15:0] ccxif;
      logic [15:0] ccxof;

      assign gpt_hwif_in.TIM_SR1.CC1IF.next = ccxif[0];
      assign gpt_hwif_in.TIM_SR1.CC2IF.next = ccxif[1];
      assign gpt_hwif_in.TIM_SR1.CC3IF.next = ccxif[2];
      assign gpt_hwif_in.TIM_SR1.CC4IF.next = ccxif[3];
      assign gpt_hwif_in.TIM_SR2.CC1IF.next = ccxif[4];
      assign gpt_hwif_in.TIM_SR2.CC2IF.next = ccxif[5];
      assign gpt_hwif_in.TIM_SR2.CC3IF.next = ccxif[6];
      assign gpt_hwif_in.TIM_SR2.CC4IF.next = ccxif[7];
      assign gpt_hwif_in.TIM_SR3.CC1IF.next = ccxif[8];
      assign gpt_hwif_in.TIM_SR3.CC2IF.next = ccxif[9];
      assign gpt_hwif_in.TIM_SR3.CC3IF.next = ccxif[10];
      assign gpt_hwif_in.TIM_SR3.CC4IF.next = ccxif[11];
      assign gpt_hwif_in.TIM_SR4.CC1IF.next = ccxif[12];
      assign gpt_hwif_in.TIM_SR4.CC2IF.next = ccxif[13];
      assign gpt_hwif_in.TIM_SR4.CC3IF.next = ccxif[14];
      assign gpt_hwif_in.TIM_SR4.CC4IF.next = ccxif[15];

      assign gpt_hwif_in.TIM_SR1.CC1OF.next = ccxof[0];
      assign gpt_hwif_in.TIM_SR1.CC2OF.next = ccxof[1];
      assign gpt_hwif_in.TIM_SR1.CC3OF.next = ccxof[2];
      assign gpt_hwif_in.TIM_SR1.CC4OF.next = ccxof[3];
      assign gpt_hwif_in.TIM_SR2.CC1OF.next = ccxof[4];
      assign gpt_hwif_in.TIM_SR2.CC2OF.next = ccxof[5];
      assign gpt_hwif_in.TIM_SR2.CC3OF.next = ccxof[6];
      assign gpt_hwif_in.TIM_SR2.CC4OF.next = ccxof[7];
      assign gpt_hwif_in.TIM_SR3.CC1OF.next = ccxof[8];
      assign gpt_hwif_in.TIM_SR3.CC2OF.next = ccxof[9];
      assign gpt_hwif_in.TIM_SR3.CC3OF.next = ccxof[10];
      assign gpt_hwif_in.TIM_SR3.CC4OF.next = ccxof[11];
      assign gpt_hwif_in.TIM_SR4.CC1OF.next = ccxof[12];
      assign gpt_hwif_in.TIM_SR4.CC2OF.next = ccxof[13];
      assign gpt_hwif_in.TIM_SR4.CC3OF.next = ccxof[14];
      assign gpt_hwif_in.TIM_SR4.CC4OF.next = ccxof[15];
    end
  endgenerate



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

  logic ti2fp2;
  logic ti1fp1;
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
    .ti2fp2_i (           ),
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

  tim_channel channel_inst
  (
    .clk_i          (aclk_i   ),
    .aresetn_i      (aresetn_i),
    .ckd_i          (),
    .icf_i          (),
    .cnt_i          (cnt_value),
    .ccr_i          (),
    .uev_i          (),
    .ti_i           (),
    .trc_i          (),
    .ccxif_i        (),
    .ccxof_i        (),
    .cc1s_i         (),
    .icps_i         (),
    .cce_i          (),
    .dir_i          (),
    .ocxm_i         (),
    .ccg_i          (),
    .ocxpe_i        (),
    .ti_neigx_fpx_i (),
    .cc1p_i         (),
    .cc1np_i        (),

    .ti1_fd_o       (ti1f_ed),
    .oc_ref_o       (),
    .ccxif_o        (),
    .ccr_o          (),
    .ccxof_o        (),
    .ti1fp1_o       (),
    .ti_o           (ch_o[0])
  );
  tim_channel channel_inst
  (
    .clk_i          (aclk_i   ),
    .aresetn_i      (aresetn_i),
    .ckd_i          (),
    .icf_i          (),
    .cnt_i          (cnt_value),
    .ccr_i          (),
    .uev_i          (),
    .ti_i           (),
    .trc_i          (),
    .ccxif_i        (),
    .ccxof_i        (),
    .cc1s_i         (),
    .icps_i         (),
    .cce_i          (),
    .dir_i          (),
    .ocxm_i         (),
    .ccg_i          (),
    .ocxpe_i        (),
    .ti_neigx_fpx_i (),
    .cc1p_i         (),
    .cc1np_i        (),

    .ti1_fd_o       (ti1f_ed),
    .oc_ref_o       (),
    .ccxif_o        (),
    .ccr_o          (),
    .ccxof_o        (),
    .ti1fp1_o       (),
    .ti_o           (ch_o[1])
  );

  generate
    if (CH_PAIRS_NUM > 1) begin
      for (genvar i = 0; i < CH_PAIRS_NUM * 2; i++) begin : g_tim_ch
        tim_channel channel_inst
        (
          .clk_i          (aclk_i   ),
          .aresetn_i      (aresetn_i),
          .ckd_i          (),
          .icf_i          (),
          .cnt_i          (cnt_value),
          .ccr_i          (),
          .uev_i          (),
          .ti_i           (),
          .trc_i          (),
          .ccxif_i        (),
          .ccxof_i        (),
          .cc1s_i         (),
          .icps_i         (),
          .cce_i          (),
          .dir_i          (),
          .ocxm_i         (),
          .ccg_i          (),
          .ocxpe_i        (),
          .ti_neigx_fpx_i (),
          .cc1p_i         (),
          .cc1np_i        (),

          .ti1_fd_o       (ti1f_ed),
          .oc_ref_o       (),
          .ccxif_o        (),
          .ccr_o          (),
          .ccxof_o        (),
          .ti1fp1_o       (),
          .ti_o           (ch_o[i])
        );
      end
    end
  endgenerate
endmodule