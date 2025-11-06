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
  input  logic [3:0]                itr_i    ,
  input  logic                      etr_i    ,
  input  logic [CH_PAIRS_NUM - 1:0] ch_i     ,
  output logic                      trg_o    ,    
  output logic [CH_PAIRS_NUM - 1:0] ch_o     ,
);

  logic [2 * CH_PAIRS_NUM - 1:0] internal_triggers;
  logic                          trigger          ;
  logic                          ti1f_ed          ;
  logic                          trc              ;
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

  // TIM_EGRx
  logic        ug  ;
  logic        tg  ;
  assign ug = gpt_hwif_out.TIM_EGR.UG.value;
  assign tg = gpt_hwif_out.TIM_EGR.TG.value;
  generate
    if (CH_PAIRS_NUM == 1 || CH_PAIRS_NUM == 2) begin: one_tim_egr
      logic [3:0] ccxg;
 
      assign ccxg[0] = gpt_hwif_out.TIM_EGR1.CC1G.value;
      assign ccxg[1] = gpt_hwif_out.TIM_EGR1.CC2G.value;
      assign ccxg[2] = gpt_hwif_out.TIM_EGR1.CC3G.value;
      assign ccxg[3] = gpt_hwif_out.TIM_EGR1.CC4G.value;
    end
    else if (CH_PAIRS_NUM == 3 || CH_PAIRS_NUM == 4) begin: two_tim_egr
      logic [7:0] ccxg;
 
      assign ccxg[0] = gpt_hwif_out.TIM_EGR1.CC1G.value;
      assign ccxg[1] = gpt_hwif_out.TIM_EGR1.CC2G.value;
      assign ccxg[2] = gpt_hwif_out.TIM_EGR1.CC3G.value;
      assign ccxg[3] = gpt_hwif_out.TIM_EGR1.CC4G.value;
      assign ccxg[4] = gpt_hwif_out.TIM_EGR2.CC1G.value;
      assign ccxg[5] = gpt_hwif_out.TIM_EGR2.CC2G.value;
      assign ccxg[6] = gpt_hwif_out.TIM_EGR2.CC3G.value;
      assign ccxg[7] = gpt_hwif_out.TIM_EGR2.CC4G.value;
    end
    else if (CH_PAIRS_NUM == 5 || CH_PAIRS_NUM == 6) begin

      logic [11:0] ccxg;
 
      assign ccxg[0]  = gpt_hwif_out.TIM_EGR1.CC1G.value;
      assign ccxg[1]  = gpt_hwif_out.TIM_EGR1.CC2G.value;
      assign ccxg[2]  = gpt_hwif_out.TIM_EGR1.CC3G.value;
      assign ccxg[3]  = gpt_hwif_out.TIM_EGR1.CC4G.value;
      assign ccxg[4]  = gpt_hwif_out.TIM_EGR2.CC1G.value;
      assign ccxg[5]  = gpt_hwif_out.TIM_EGR2.CC2G.value;
      assign ccxg[6]  = gpt_hwif_out.TIM_EGR2.CC3G.value;
      assign ccxg[7]  = gpt_hwif_out.TIM_EGR2.CC4G.value;
      assign ccxg[8]  = gpt_hwif_out.TIM_EGR3.CC1G.value;
      assign ccxg[9]  = gpt_hwif_out.TIM_EGR3.CC2G.value;
      assign ccxg[10] = gpt_hwif_out.TIM_EGR3.CC3G.value;
      assign ccxg[11] = gpt_hwif_out.TIM_EGR3.CC4G.value;
    end
    else if (CH_PAIRS_NUM == 7 || CH_PAIRS_NUM == 8) begin
      logic [15:0] ccxg;
 
      assign ccxg[0]  = gpt_hwif_out.TIM_EGR1.CC1G.value;
      assign ccxg[1]  = gpt_hwif_out.TIM_EGR1.CC2G.value;
      assign ccxg[2]  = gpt_hwif_out.TIM_EGR1.CC3G.value;
      assign ccxg[3]  = gpt_hwif_out.TIM_EGR1.CC4G.value;
      assign ccxg[4]  = gpt_hwif_out.TIM_EGR2.CC1G.value;
      assign ccxg[5]  = gpt_hwif_out.TIM_EGR2.CC2G.value;
      assign ccxg[6]  = gpt_hwif_out.TIM_EGR2.CC3G.value;
      assign ccxg[7]  = gpt_hwif_out.TIM_EGR2.CC4G.value;
      assign ccxg[8]  = gpt_hwif_out.TIM_EGR3.CC1G.value;
      assign ccxg[9]  = gpt_hwif_out.TIM_EGR3.CC2G.value;
      assign ccxg[10] = gpt_hwif_out.TIM_EGR3.CC3G.value;
      assign ccxg[11] = gpt_hwif_out.TIM_EGR3.CC4G.value;
      assign ccxg[12] = gpt_hwif_out.TIM_EGR4.CC1G.value;
      assign ccxg[13] = gpt_hwif_out.TIM_EGR4.CC2G.value;
      assign ccxg[14] = gpt_hwif_out.TIM_EGR4.CC3G.value;
      assign ccxg[15] = gpt_hwif_out.TIM_EGR4.CC4G.value;
    end
  endgenerate

  // Read from TIM_CCRx
  generate
    if (CH_PAIRS_NUM == 1) begin: two_ccr_regs
      logic [CNT_WIDTH - 1:0] ccr_reg [1:0];

      assign ccr_reg[0] = gpt_hwif_out.TIM_CCR1.value;
      assign ccr_reg[1] = gpt_hwif_out.TIM_CCR2.value; 
    end     
    else if (CH_PAIRS_NUM == 2) begin: four_ccr_regs
      logic [CNT_WIDTH - 1:0] ccr_reg [3:0];

      assign ccr_reg[0] = gpt_hwif_out.TIM_CCR1.value;
      assign ccr_reg[1] = gpt_hwif_out.TIM_CCR2.value; 
      assign ccr_reg[2] = gpt_hwif_out.TIM_CCR3.value;
      assign ccr_reg[3] = gpt_hwif_out.TIM_CCR4.value;
    end
    else if (CH_PAIRS_NUM == 3) begin: six_ccr_regs
      logic [CNT_WIDTH - 1:0] ccr_reg [5:0];

      assign ccr_reg[0] = gpt_hwif_out.TIM_CCR1.value;
      assign ccr_reg[1] = gpt_hwif_out.TIM_CCR2.value; 
      assign ccr_reg[2] = gpt_hwif_out.TIM_CCR3.value;
      assign ccr_reg[3] = gpt_hwif_out.TIM_CCR4.value;   
      assign ccr_reg[4] = gpt_hwif_out.TIM_CCR5.value;
      assign ccr_reg[5] = gpt_hwif_out.TIM_CCR6.value;   
    end
    else if (CH_PAIRS_NUM == 4) begin: eight_ccr_regs
      logic [CNT_WIDTH - 1:0] ccr_reg [7:0];

      assign ccr_reg[0] = gpt_hwif_out.TIM_CCR1.value;
      assign ccr_reg[1] = gpt_hwif_out.TIM_CCR2.value; 
      assign ccr_reg[2] = gpt_hwif_out.TIM_CCR3.value;
      assign ccr_reg[3] = gpt_hwif_out.TIM_CCR4.value;
      assign ccr_reg[4] = gpt_hwif_out.TIM_CCR5.value;
      assign ccr_reg[5] = gpt_hwif_out.TIM_CCR6.value; 
      assign ccr_reg[6] = gpt_hwif_out.TIM_CCR7.value;
      assign ccr_reg[7] = gpt_hwif_out.TIM_CCR8.value;
    end
    else if (CH_PAIRS_NUM == 5) begin: ten_ccr_regs
      logic [CNT_WIDTH - 1:0] ccr_reg [9:0];

      assign ccr_reg[0] = gpt_hwif_out.TIM_CCR1.value;
      assign ccr_reg[1] = gpt_hwif_out.TIM_CCR2.value; 
      assign ccr_reg[2] = gpt_hwif_out.TIM_CCR3.value;
      assign ccr_reg[3] = gpt_hwif_out.TIM_CCR4.value;
      assign ccr_reg[4] = gpt_hwif_out.TIM_CCR5.value;
      assign ccr_reg[5] = gpt_hwif_out.TIM_CCR6.value; 
      assign ccr_reg[6] = gpt_hwif_out.TIM_CCR7.value;
      assign ccr_reg[7] = gpt_hwif_out.TIM_CCR8.value;
      assign ccr_reg[8] = gpt_hwif_out.TIM_CCR9.value;
      assign ccr_reg[9] = gpt_hwif_out.TIM_CCR10.value;
    end
    else if (CH_PAIRS_NUM == 6) begin: twelve_ccr_regs
      logic [CNT_WIDTH - 1:0] ccr_reg [11:0];

      assign ccr_reg[0]  = gpt_hwif_out.TIM_CCR1.value;
      assign ccr_reg[1]  = gpt_hwif_out.TIM_CCR2.value; 
      assign ccr_reg[2]  = gpt_hwif_out.TIM_CCR3.value;
      assign ccr_reg[3]  = gpt_hwif_out.TIM_CCR4.value;   
      assign ccr_reg[4]  = gpt_hwif_out.TIM_CCR5.value;
      assign ccr_reg[5]  = gpt_hwif_out.TIM_CCR6.value;   
      assign ccr_reg[6]  = gpt_hwif_out.TIM_CCR7.value;
      assign ccr_reg[7]  = gpt_hwif_out.TIM_CCR8.value; 
      assign ccr_reg[8]  = gpt_hwif_out.TIM_CCR9.value;
      assign ccr_reg[9]  = gpt_hwif_out.TIM_CCR10.value;   
      assign ccr_reg[10] = gpt_hwif_out.TIM_CCR11.value;
      assign ccr_reg[11] = gpt_hwif_out.TIM_CCR12.value;  
    end
    else if (CH_PAIRS_NUM = 7) begin: fourteen_ccr_regs
      logic [CNT_WIDTH - 1:0] ccr_reg [13:0];

      assign ccr_reg[0]  = gpt_hwif_out.TIM_CCR1.value;
      assign ccr_reg[1]  = gpt_hwif_out.TIM_CCR2.value; 
      assign ccr_reg[2]  = gpt_hwif_out.TIM_CCR3.value;
      assign ccr_reg[3]  = gpt_hwif_out.TIM_CCR4.value;   
      assign ccr_reg[4]  = gpt_hwif_out.TIM_CCR5.value;
      assign ccr_reg[5]  = gpt_hwif_out.TIM_CCR6.value;   
      assign ccr_reg[6]  = gpt_hwif_out.TIM_CCR7.value;
      assign ccr_reg[7]  = gpt_hwif_out.TIM_CCR8.value; 
      assign ccr_reg[8]  = gpt_hwif_out.TIM_CCR9.value;
      assign ccr_reg[9]  = gpt_hwif_out.TIM_CCR10.value;   
      assign ccr_reg[10] = gpt_hwif_out.TIM_CCR11.value;
      assign ccr_reg[11] = gpt_hwif_out.TIM_CCR12.value;  
      assign ccr_reg[12] = gpt_hwif_out.TIM_CCR13.value;
      assign ccr_reg[13] = gpt_hwif_out.TIM_CCR14.value;
    end
    else if (CH_PAIRS_NUM = 8) begin: sixteen_ccr_regs
      logic [CNT_WIDTH - 1:0] ccr_reg [15:0];

      assign ccr_reg[0]  = gpt_hwif_out.TIM_CCR1.value;
      assign ccr_reg[1]  = gpt_hwif_out.TIM_CCR2.value; 
      assign ccr_reg[2]  = gpt_hwif_out.TIM_CCR3.value;
      assign ccr_reg[3]  = gpt_hwif_out.TIM_CCR4.value;   
      assign ccr_reg[4]  = gpt_hwif_out.TIM_CCR5.value;
      assign ccr_reg[5]  = gpt_hwif_out.TIM_CCR6.value;   
      assign ccr_reg[6]  = gpt_hwif_out.TIM_CCR7.value;
      assign ccr_reg[7]  = gpt_hwif_out.TIM_CCR8.value; 
      assign ccr_reg[8]  = gpt_hwif_out.TIM_CCR9.value;
      assign ccr_reg[9]  = gpt_hwif_out.TIM_CCR10.value;   
      assign ccr_reg[10] = gpt_hwif_out.TIM_CCR11.value;
      assign ccr_reg[11] = gpt_hwif_out.TIM_CCR12.value;  
      assign ccr_reg[12] = gpt_hwif_out.TIM_CCR13.value;
      assign ccr_reg[13] = gpt_hwif_out.TIM_CCR14.value;
      assign ccr_reg[14] = gpt_hwif_out.TIM_CCR15.value;
      assign ccr_reg[15] = gpt_hwif_out.TIM_CCR16.value;
    end
  endgenerate

  // Write into TIM_CCRx
  generate
    if (CH_PAIRS_NUM == 1) begin
      logic [1:0] ccr_to_regblock;
      assign gpt_hwif_in.TIM_CCR1.next = ccr_to_regblock[0];
      assign gpt_hwif_in.TIM_CCR2.next = ccr_to_regblock[1];
    end
    else if (CH_PAIRS_NUM == 2) begin
      logic [3:0] ccr_to_regblock;
      assign gpt_hwif_in.TIM_CCR1.next = ccr_to_regblock[0];
      assign gpt_hwif_in.TIM_CCR2.next = ccr_to_regblock[1];
      assign gpt_hwif_in.TIM_CCR3.next = ccr_to_regblock[2];
      assign gpt_hwif_in.TIM_CCR4.next = ccr_to_regblock[3];
    end
    else if (CH_PAIRS_NUM == 3) begin
      logic [5:0] ccr_to_regblock;
      assign gpt_hwif_in.TIM_CCR1.next = ccr_to_regblock[0];
      assign gpt_hwif_in.TIM_CCR2.next = ccr_to_regblock[1];
      assign gpt_hwif_in.TIM_CCR3.next = ccr_to_regblock[2];
      assign gpt_hwif_in.TIM_CCR4.next = ccr_to_regblock[3];
      assign gpt_hwif_in.TIM_CCR5.next = ccr_to_regblock[4];
      assign gpt_hwif_in.TIM_CCR6.next = ccr_to_regblock[5];
    end
    else if (CH_PAIRS_NUM == 4) begin
      logic [7:0] ccr_to_regblock;
      assign gpt_hwif_in.TIM_CCR1.next = ccr_to_regblock[0];
      assign gpt_hwif_in.TIM_CCR2.next = ccr_to_regblock[1];
      assign gpt_hwif_in.TIM_CCR3.next = ccr_to_regblock[2];
      assign gpt_hwif_in.TIM_CCR4.next = ccr_to_regblock[3];
      assign gpt_hwif_in.TIM_CCR5.next = ccr_to_regblock[4];
      assign gpt_hwif_in.TIM_CCR6.next = ccr_to_regblock[5];
      assign gpt_hwif_in.TIM_CCR7.next = ccr_to_regblock[6];
      assign gpt_hwif_in.TIM_CCR8.next = ccr_to_regblock[7];
    end
    else if (CH_PAIRS_NUM == 5) begin
      logic [9:0] ccr_to_regblock;
      assign gpt_hwif_in.TIM_CCR1.next  = ccr_to_regblock[0];
      assign gpt_hwif_in.TIM_CCR2.next  = ccr_to_regblock[1];
      assign gpt_hwif_in.TIM_CCR3.next  = ccr_to_regblock[2];
      assign gpt_hwif_in.TIM_CCR4.next  = ccr_to_regblock[3];
      assign gpt_hwif_in.TIM_CCR5.next  = ccr_to_regblock[4];
      assign gpt_hwif_in.TIM_CCR6.next  = ccr_to_regblock[5];
      assign gpt_hwif_in.TIM_CCR7.next  = ccr_to_regblock[6];
      assign gpt_hwif_in.TIM_CCR8.next  = ccr_to_regblock[7];
      assign gpt_hwif_in.TIM_CCR9.next  = ccr_to_regblock[8];
      assign gpt_hwif_in.TIM_CCR10.next = ccr_to_regblock[9];
    end
    else if (CH_PAIRS_NUM == 6) begin
      logic [11:0] ccr_to_regblock;
      assign gpt_hwif_in.TIM_CCR1.next  = ccr_to_regblock[0];
      assign gpt_hwif_in.TIM_CCR2.next  = ccr_to_regblock[1];
      assign gpt_hwif_in.TIM_CCR3.next  = ccr_to_regblock[2];
      assign gpt_hwif_in.TIM_CCR4.next  = ccr_to_regblock[3];
      assign gpt_hwif_in.TIM_CCR5.next  = ccr_to_regblock[4];
      assign gpt_hwif_in.TIM_CCR6.next  = ccr_to_regblock[5];
      assign gpt_hwif_in.TIM_CCR7.next  = ccr_to_regblock[6];
      assign gpt_hwif_in.TIM_CCR8.next  = ccr_to_regblock[7];
      assign gpt_hwif_in.TIM_CCR9.next  = ccr_to_regblock[8];
      assign gpt_hwif_in.TIM_CCR10.next = ccr_to_regblock[9];
      assign gpt_hwif_in.TIM_CCR11.next = ccr_to_regblock[10];
      assign gpt_hwif_in.TIM_CCR12.next = ccr_to_regblock[11];
    end
    else if (CH_PAIRS_NUM == 7) begin
      logic [13:0] ccr_to_regblock;
      assign gpt_hwif_in.TIM_CCR1.next  = ccr_to_regblock[0];
      assign gpt_hwif_in.TIM_CCR2.next  = ccr_to_regblock[1];
      assign gpt_hwif_in.TIM_CCR3.next  = ccr_to_regblock[2];
      assign gpt_hwif_in.TIM_CCR4.next  = ccr_to_regblock[3];
      assign gpt_hwif_in.TIM_CCR5.next  = ccr_to_regblock[4];
      assign gpt_hwif_in.TIM_CCR6.next  = ccr_to_regblock[5];
      assign gpt_hwif_in.TIM_CCR7.next  = ccr_to_regblock[6];
      assign gpt_hwif_in.TIM_CCR8.next  = ccr_to_regblock[7];
      assign gpt_hwif_in.TIM_CCR9.next  = ccr_to_regblock[8];
      assign gpt_hwif_in.TIM_CCR10.next = ccr_to_regblock[9];
      assign gpt_hwif_in.TIM_CCR11.next = ccr_to_regblock[10];
      assign gpt_hwif_in.TIM_CCR12.next = ccr_to_regblock[11];
      assign gpt_hwif_in.TIM_CCR13.next = ccr_to_regblock[12];
      assign gpt_hwif_in.TIM_CCR14.next = ccr_to_regblock[13];
    end
    else if (CH_PAIRS_NUM == 8) begin
      logic [15:0] ccr_to_regblock;
      assign gpt_hwif_in.TIM_CCR1.next  = ccr_to_regblock[0];
      assign gpt_hwif_in.TIM_CCR2.next  = ccr_to_regblock[1];
      assign gpt_hwif_in.TIM_CCR3.next  = ccr_to_regblock[2];
      assign gpt_hwif_in.TIM_CCR4.next  = ccr_to_regblock[3];
      assign gpt_hwif_in.TIM_CCR5.next  = ccr_to_regblock[4];
      assign gpt_hwif_in.TIM_CCR6.next  = ccr_to_regblock[5];
      assign gpt_hwif_in.TIM_CCR7.next  = ccr_to_regblock[6];
      assign gpt_hwif_in.TIM_CCR8.next  = ccr_to_regblock[7];
      assign gpt_hwif_in.TIM_CCR9.next  = ccr_to_regblock[8];
      assign gpt_hwif_in.TIM_CCR10.next = ccr_to_regblock[9];
      assign gpt_hwif_in.TIM_CCR11.next = ccr_to_regblock[10];
      assign gpt_hwif_in.TIM_CCR12.next = ccr_to_regblock[11];
      assign gpt_hwif_in.TIM_CCR13.next = ccr_to_regblock[12];
      assign gpt_hwif_in.TIM_CCR14.next = ccr_to_regblock[13];
      assign gpt_hwif_in.TIM_CCR15.next = ccr_to_regblock[14];
      assign gpt_hwif_in.TIM_CCR16.next = ccr_to_regblock[15];
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
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];

          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
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
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];

          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
        end
      end
    end
    else if (CH_PAIRS_NUM == 3) begin: three_ccmr_regs
      logic [1:0] ccxs          [5:0];
      logic       ocxfe_icxpsc0 [5:0];
      logic       ocxce_icxf3   [5:0];
      logic       ocxpe_icxpsc1 [5:0];
      logic [2:0] ocxm_icxf     [5:0];


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
      assign ccxs         [4] = gpt_hwif_out.TIM_CCMR3.CC1S.value         ;
      assign ocxfe_icxpsc0[4] = gpt_hwif_out.TIM_CCMR3.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[4] = gpt_hwif_out.TIM_CCMR3.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [4] = gpt_hwif_out.TIM_CCMR3.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [4] = gpt_hwif_out.TIM_CCMR3.OC1CE_IC1F3.value  ;
      assign ccxs         [5] = gpt_hwif_out.TIM_CCMR3.CC2S.value         ;
      assign ocxfe_icxpsc0[5] = gpt_hwif_out.TIM_CCMR3.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[5] = gpt_hwif_out.TIM_CCMR3.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [5] = gpt_hwif_out.TIM_CCMR3.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [5] = gpt_hwif_out.TIM_CCMR3.OC2CE_IC2F3.value  ;

      // Input Channel
      logic [1:0] icxpsc [5:0];
      logic [3:0] icxf   [5:0];

      //Output Channel
      logic       ocxfe [5:0];
      logic       ocxpe [5:0];
      logic [2:0] ocxm  [5:0];
      logic       ocxce [5:0];

      always_comb begin
        for (int i = 0; i < CH_PAIRS_NUM * 2; i = i + 1) begin
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];

          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
        end
      end
    end
    else if (CH_PAIRS_NUM == 4) begin
logic [1:0] ccxs          [5:0];
      logic       ocxfe_icxpsc0 [7:0];
      logic       ocxce_icxf3   [7:0];
      logic       ocxpe_icxpsc1 [7:0];
      logic [2:0] ocxm_icxf     [7:0];


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
      assign ccxs         [4] = gpt_hwif_out.TIM_CCMR3.CC1S.value         ;
      assign ocxfe_icxpsc0[4] = gpt_hwif_out.TIM_CCMR3.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[4] = gpt_hwif_out.TIM_CCMR3.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [4] = gpt_hwif_out.TIM_CCMR3.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [4] = gpt_hwif_out.TIM_CCMR3.OC1CE_IC1F3.value  ;
      assign ccxs         [5] = gpt_hwif_out.TIM_CCMR3.CC2S.value         ;
      assign ocxfe_icxpsc0[5] = gpt_hwif_out.TIM_CCMR3.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[5] = gpt_hwif_out.TIM_CCMR3.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [5] = gpt_hwif_out.TIM_CCMR3.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [5] = gpt_hwif_out.TIM_CCMR3.OC2CE_IC2F3.value  ;  
      assign ccxs         [6] = gpt_hwif_out.TIM_CCMR4.CC1S.value         ;
      assign ocxfe_icxpsc0[6] = gpt_hwif_out.TIM_CCMR4.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[6] = gpt_hwif_out.TIM_CCMR4.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [6] = gpt_hwif_out.TIM_CCMR4.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [6] = gpt_hwif_out.TIM_CCMR4.OC1CE_IC1F3.value  ;
      assign ccxs         [7] = gpt_hwif_out.TIM_CCMR4.CC2S.value         ;
      assign ocxfe_icxpsc0[7] = gpt_hwif_out.TIM_CCMR4.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[7] = gpt_hwif_out.TIM_CCMR4.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [7] = gpt_hwif_out.TIM_CCMR4.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [7] = gpt_hwif_out.TIM_CCMR4.OC2CE_IC2F3.value  ;  

      // Input Channel
      logic [1:0] icxpsc [7:0];
      logic [3:0] icxf   [7:0];

      //Output Channel
      logic       ocxfe [7:0];
      logic       ocxpe [7:0];
      logic [2:0] ocxm  [7:0];
      logic       ocxce [7:0];

      always_comb begin
        for (int i = 0; i < CH_PAIRS_NUM * 2; i = i + 1) begin
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];

          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
        end
      end
    end
    else if (CH_PAIRS_NUM == 5) begin
      logic       ocxfe_icxpsc0 [9:0];
      logic       ocxce_icxf3   [9:0];
      logic       ocxpe_icxpsc1 [9:0];
      logic [2:0] ocxm_icxf     [9:0];


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
      assign ccxs         [4] = gpt_hwif_out.TIM_CCMR3.CC1S.value         ;
      assign ocxfe_icxpsc0[4] = gpt_hwif_out.TIM_CCMR3.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[4] = gpt_hwif_out.TIM_CCMR3.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [4] = gpt_hwif_out.TIM_CCMR3.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [4] = gpt_hwif_out.TIM_CCMR3.OC1CE_IC1F3.value  ;
      assign ccxs         [5] = gpt_hwif_out.TIM_CCMR3.CC2S.value         ;
      assign ocxfe_icxpsc0[5] = gpt_hwif_out.TIM_CCMR3.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[5] = gpt_hwif_out.TIM_CCMR3.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [5] = gpt_hwif_out.TIM_CCMR3.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [5] = gpt_hwif_out.TIM_CCMR3.OC2CE_IC2F3.value  ;  
      assign ccxs         [6] = gpt_hwif_out.TIM_CCMR4.CC1S.value         ;
      assign ocxfe_icxpsc0[6] = gpt_hwif_out.TIM_CCMR4.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[6] = gpt_hwif_out.TIM_CCMR4.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [6] = gpt_hwif_out.TIM_CCMR4.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [6] = gpt_hwif_out.TIM_CCMR4.OC1CE_IC1F3.value  ;
      assign ccxs         [7] = gpt_hwif_out.TIM_CCMR4.CC2S.value         ;
      assign ocxfe_icxpsc0[7] = gpt_hwif_out.TIM_CCMR4.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[7] = gpt_hwif_out.TIM_CCMR4.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [7] = gpt_hwif_out.TIM_CCMR4.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [7] = gpt_hwif_out.TIM_CCMR4.OC2CE_IC2F3.value  ;
      assign ccxs         [8] = gpt_hwif_out.TIM_CCMR5.CC1S.value         ;
      assign ocxfe_icxpsc0[8] = gpt_hwif_out.TIM_CCMR5.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[8] = gpt_hwif_out.TIM_CCMR5.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [8] = gpt_hwif_out.TIM_CCMR5.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [8] = gpt_hwif_out.TIM_CCMR5.OC1CE_IC1F3.value  ;
      assign ccxs         [9] = gpt_hwif_out.TIM_CCMR5.CC2S.value         ;
      assign ocxfe_icxpsc0[9] = gpt_hwif_out.TIM_CCMR5.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[9] = gpt_hwif_out.TIM_CCMR5.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [9] = gpt_hwif_out.TIM_CCMR5.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [9] = gpt_hwif_out.TIM_CCMR5.OC2CE_IC2F3.value  ;  

      // Input Channel
      logic [1:0] icxpsc [9:0];
      logic [3:0] icxf   [9:0];

      //Output Channel
      logic       ocxfe [9:0];
      logic       ocxpe [9:0];
      logic [2:0] ocxm  [9:0];
      logic       ocxce [9:0];

      always_comb begin
        for (int i = 0; i < CH_PAIRS_NUM * 2; i = i + 1) begin
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];

          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
        end
      end
    end
    else if (CH_PAIRS_NUM == 6) begin
      logic       ocxfe_icxpsc0 [11:0];
      logic       ocxce_icxf3   [11:0];
      logic       ocxpe_icxpsc1 [11:0];
      logic [2:0] ocxm_icxf     [11:0];


      assign ccxs         [0]  = gpt_hwif_out.TIM_CCMR1.CC1S.value         ;
      assign ocxfe_icxpsc0[0]  = gpt_hwif_out.TIM_CCMR1.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[0]  = gpt_hwif_out.TIM_CCMR1.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [0]  = gpt_hwif_out.TIM_CCMR1.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [0]  = gpt_hwif_out.TIM_CCMR1.OC1CE_IC1F3.value  ;
      assign ccxs         [1]  = gpt_hwif_out.TIM_CCMR1.CC2S.value         ;
      assign ocxfe_icxpsc0[1]  = gpt_hwif_out.TIM_CCMR1.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[1]  = gpt_hwif_out.TIM_CCMR1.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [1]  = gpt_hwif_out.TIM_CCMR1.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [1]  = gpt_hwif_out.TIM_CCMR1.OC2CE_IC2F3.value  ;
      assign ccxs         [2]  = gpt_hwif_out.TIM_CCMR2.CC1S.value         ;
      assign ocxfe_icxpsc0[2]  = gpt_hwif_out.TIM_CCMR2.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[2]  = gpt_hwif_out.TIM_CCMR2.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [2]  = gpt_hwif_out.TIM_CCMR2.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [2]  = gpt_hwif_out.TIM_CCMR2.OC1CE_IC1F3.value  ;
      assign ccxs         [3]  = gpt_hwif_out.TIM_CCMR2.CC2S.value         ;
      assign ocxfe_icxpsc0[3]  = gpt_hwif_out.TIM_CCMR2.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[3]  = gpt_hwif_out.TIM_CCMR2.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [3]  = gpt_hwif_out.TIM_CCMR2.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [3]  = gpt_hwif_out.TIM_CCMR2.OC2CE_IC2F3.value  ;
      assign ccxs         [4]  = gpt_hwif_out.TIM_CCMR3.CC1S.value         ;
      assign ocxfe_icxpsc0[4]  = gpt_hwif_out.TIM_CCMR3.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[4]  = gpt_hwif_out.TIM_CCMR3.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [4]  = gpt_hwif_out.TIM_CCMR3.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [4]  = gpt_hwif_out.TIM_CCMR3.OC1CE_IC1F3.value  ;
      assign ccxs         [5]  = gpt_hwif_out.TIM_CCMR3.CC2S.value         ;
      assign ocxfe_icxpsc0[5]  = gpt_hwif_out.TIM_CCMR3.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[5]  = gpt_hwif_out.TIM_CCMR3.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [5]  = gpt_hwif_out.TIM_CCMR3.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [5]  = gpt_hwif_out.TIM_CCMR3.OC2CE_IC2F3.value  ;  
      assign ccxs         [6]  = gpt_hwif_out.TIM_CCMR4.CC1S.value         ;
      assign ocxfe_icxpsc0[6]  = gpt_hwif_out.TIM_CCMR4.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[6]  = gpt_hwif_out.TIM_CCMR4.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [6]  = gpt_hwif_out.TIM_CCMR4.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [6]  = gpt_hwif_out.TIM_CCMR4.OC1CE_IC1F3.value  ;
      assign ccxs         [7]  = gpt_hwif_out.TIM_CCMR4.CC2S.value         ;
      assign ocxfe_icxpsc0[7]  = gpt_hwif_out.TIM_CCMR4.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[7]  = gpt_hwif_out.TIM_CCMR4.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [7]  = gpt_hwif_out.TIM_CCMR4.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [7]  = gpt_hwif_out.TIM_CCMR4.OC2CE_IC2F3.value  ;
      assign ccxs         [8]  = gpt_hwif_out.TIM_CCMR5.CC1S.value         ;
      assign ocxfe_icxpsc0[8]  = gpt_hwif_out.TIM_CCMR5.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[8]  = gpt_hwif_out.TIM_CCMR5.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [8]  = gpt_hwif_out.TIM_CCMR5.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [8]  = gpt_hwif_out.TIM_CCMR5.OC1CE_IC1F3.value  ;
      assign ccxs         [9]  = gpt_hwif_out.TIM_CCMR5.CC2S.value         ;
      assign ocxfe_icxpsc0[9]  = gpt_hwif_out.TIM_CCMR5.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[9]  = gpt_hwif_out.TIM_CCMR5.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [9]  = gpt_hwif_out.TIM_CCMR5.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [9]  = gpt_hwif_out.TIM_CCMR5.OC2CE_IC2F3.value  ;
      assign ccxs         [10] = gpt_hwif_out.TIM_CCMR6.CC1S.value         ;
      assign ocxfe_icxpsc0[10] = gpt_hwif_out.TIM_CCMR6.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[10] = gpt_hwif_out.TIM_CCMR6.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [10] = gpt_hwif_out.TIM_CCMR6.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [10] = gpt_hwif_out.TIM_CCMR6.OC1CE_IC1F3.value  ;
      assign ccxs         [11] = gpt_hwif_out.TIM_CCMR6.CC2S.value         ;
      assign ocxfe_icxpsc0[11] = gpt_hwif_out.TIM_CCMR6.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[11] = gpt_hwif_out.TIM_CCMR6.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [11] = gpt_hwif_out.TIM_CCMR6.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [11] = gpt_hwif_out.TIM_CCMR6.OC2CE_IC2F3.value  ; 

      // Input Channel
      logic [1:0] icxpsc [11:0];
      logic [3:0] icxf   [11:0];

      //Output Channel
      logic       ocxfe [11:0];
      logic       ocxpe [11:0];
      logic [2:0] ocxm  [11:0];
      logic       ocxce [11:0];

      always_comb begin
        for (int i = 0; i < CH_PAIRS_NUM * 2; i = i + 1) begin
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];

          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
        end
      end
    end
    else if (CH_PAIRS_NUM == 7) begin
      logic       ocxfe_icxpsc0 [13:0];
      logic       ocxce_icxf3   [13:0];
      logic       ocxpe_icxpsc1 [13:0];
      logic [2:0] ocxm_icxf     [13:0];


      assign ccxs         [0]  = gpt_hwif_out.TIM_CCMR1.CC1S.value         ;
      assign ocxfe_icxpsc0[0]  = gpt_hwif_out.TIM_CCMR1.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[0]  = gpt_hwif_out.TIM_CCMR1.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [0]  = gpt_hwif_out.TIM_CCMR1.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [0]  = gpt_hwif_out.TIM_CCMR1.OC1CE_IC1F3.value  ;
      assign ccxs         [1]  = gpt_hwif_out.TIM_CCMR1.CC2S.value         ;
      assign ocxfe_icxpsc0[1]  = gpt_hwif_out.TIM_CCMR1.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[1]  = gpt_hwif_out.TIM_CCMR1.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [1]  = gpt_hwif_out.TIM_CCMR1.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [1]  = gpt_hwif_out.TIM_CCMR1.OC2CE_IC2F3.value  ;
      assign ccxs         [2]  = gpt_hwif_out.TIM_CCMR2.CC1S.value         ;
      assign ocxfe_icxpsc0[2]  = gpt_hwif_out.TIM_CCMR2.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[2]  = gpt_hwif_out.TIM_CCMR2.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [2]  = gpt_hwif_out.TIM_CCMR2.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [2]  = gpt_hwif_out.TIM_CCMR2.OC1CE_IC1F3.value  ;
      assign ccxs         [3]  = gpt_hwif_out.TIM_CCMR2.CC2S.value         ;
      assign ocxfe_icxpsc0[3]  = gpt_hwif_out.TIM_CCMR2.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[3]  = gpt_hwif_out.TIM_CCMR2.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [3]  = gpt_hwif_out.TIM_CCMR2.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [3]  = gpt_hwif_out.TIM_CCMR2.OC2CE_IC2F3.value  ;
      assign ccxs         [4]  = gpt_hwif_out.TIM_CCMR3.CC1S.value         ;
      assign ocxfe_icxpsc0[4]  = gpt_hwif_out.TIM_CCMR3.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[4]  = gpt_hwif_out.TIM_CCMR3.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [4]  = gpt_hwif_out.TIM_CCMR3.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [4]  = gpt_hwif_out.TIM_CCMR3.OC1CE_IC1F3.value  ;
      assign ccxs         [5]  = gpt_hwif_out.TIM_CCMR3.CC2S.value         ;
      assign ocxfe_icxpsc0[5]  = gpt_hwif_out.TIM_CCMR3.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[5]  = gpt_hwif_out.TIM_CCMR3.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [5]  = gpt_hwif_out.TIM_CCMR3.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [5]  = gpt_hwif_out.TIM_CCMR3.OC2CE_IC2F3.value  ;  
      assign ccxs         [6]  = gpt_hwif_out.TIM_CCMR4.CC1S.value         ;
      assign ocxfe_icxpsc0[6]  = gpt_hwif_out.TIM_CCMR4.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[6]  = gpt_hwif_out.TIM_CCMR4.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [6]  = gpt_hwif_out.TIM_CCMR4.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [6]  = gpt_hwif_out.TIM_CCMR4.OC1CE_IC1F3.value  ;
      assign ccxs         [7]  = gpt_hwif_out.TIM_CCMR4.CC2S.value         ;
      assign ocxfe_icxpsc0[7]  = gpt_hwif_out.TIM_CCMR4.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[7]  = gpt_hwif_out.TIM_CCMR4.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [7]  = gpt_hwif_out.TIM_CCMR4.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [7]  = gpt_hwif_out.TIM_CCMR4.OC2CE_IC2F3.value  ;
      assign ccxs         [8]  = gpt_hwif_out.TIM_CCMR5.CC1S.value         ;
      assign ocxfe_icxpsc0[8]  = gpt_hwif_out.TIM_CCMR5.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[8]  = gpt_hwif_out.TIM_CCMR5.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [8]  = gpt_hwif_out.TIM_CCMR5.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [8]  = gpt_hwif_out.TIM_CCMR5.OC1CE_IC1F3.value  ;
      assign ccxs         [9]  = gpt_hwif_out.TIM_CCMR5.CC2S.value         ;
      assign ocxfe_icxpsc0[9]  = gpt_hwif_out.TIM_CCMR5.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[9]  = gpt_hwif_out.TIM_CCMR5.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [9]  = gpt_hwif_out.TIM_CCMR5.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [9]  = gpt_hwif_out.TIM_CCMR5.OC2CE_IC2F3.value  ;
      assign ccxs         [10] = gpt_hwif_out.TIM_CCMR6.CC1S.value         ;
      assign ocxfe_icxpsc0[10] = gpt_hwif_out.TIM_CCMR6.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[10] = gpt_hwif_out.TIM_CCMR6.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [10] = gpt_hwif_out.TIM_CCMR6.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [10] = gpt_hwif_out.TIM_CCMR6.OC1CE_IC1F3.value  ;
      assign ccxs         [11] = gpt_hwif_out.TIM_CCMR6.CC2S.value         ;
      assign ocxfe_icxpsc0[11] = gpt_hwif_out.TIM_CCMR6.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[11] = gpt_hwif_out.TIM_CCMR6.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [11] = gpt_hwif_out.TIM_CCMR6.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [11] = gpt_hwif_out.TIM_CCMR6.OC2CE_IC2F3.value  ; 
      assign ccxs         [12] = gpt_hwif_out.TIM_CCMR6.CC1S.value         ;
      assign ocxfe_icxpsc0[12] = gpt_hwif_out.TIM_CCMR7.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[12] = gpt_hwif_out.TIM_CCMR7.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [12] = gpt_hwif_out.TIM_CCMR7.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [12] = gpt_hwif_out.TIM_CCMR7.OC1CE_IC1F3.value  ;
      assign ccxs         [13] = gpt_hwif_out.TIM_CCMR7.CC2S.value         ;
      assign ocxfe_icxpsc0[13] = gpt_hwif_out.TIM_CCMR7.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[13] = gpt_hwif_out.TIM_CCMR7.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [13] = gpt_hwif_out.TIM_CCMR7.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [13] = gpt_hwif_out.TIM_CCMR7.OC2CE_IC2F3.value  ;

      // Input Channel
      logic [1:0] icxpsc [13:0];
      logic [3:0] icxf   [13:0];

      //Output Channel
      logic       ocxfe [13:0];
      logic       ocxpe [13:0];
      logic [2:0] ocxm  [13:0];
      logic       ocxce [13:0];

      always_comb begin
        for (int i = 0; i < CH_PAIRS_NUM * 2; i = i + 1) begin
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];

          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
        end
      end
    end
    else if (CH_PAIRS_NUM == 8) begin
      logic       ocxfe_icxpsc0 [15:0];
      logic       ocxce_icxf3   [15:0];
      logic       ocxpe_icxpsc1 [15:0];
      logic [2:0] ocxm_icxf     [15:0];


      assign ccxs         [0]  = gpt_hwif_out.TIM_CCMR1.CC1S.value         ;
      assign ocxfe_icxpsc0[0]  = gpt_hwif_out.TIM_CCMR1.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[0]  = gpt_hwif_out.TIM_CCMR1.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [0]  = gpt_hwif_out.TIM_CCMR1.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [0]  = gpt_hwif_out.TIM_CCMR1.OC1CE_IC1F3.value  ;
      assign ccxs         [1]  = gpt_hwif_out.TIM_CCMR1.CC2S.value         ;
      assign ocxfe_icxpsc0[1]  = gpt_hwif_out.TIM_CCMR1.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[1]  = gpt_hwif_out.TIM_CCMR1.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [1]  = gpt_hwif_out.TIM_CCMR1.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [1]  = gpt_hwif_out.TIM_CCMR1.OC2CE_IC2F3.value  ;
      assign ccxs         [2]  = gpt_hwif_out.TIM_CCMR2.CC1S.value         ;
      assign ocxfe_icxpsc0[2]  = gpt_hwif_out.TIM_CCMR2.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[2]  = gpt_hwif_out.TIM_CCMR2.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [2]  = gpt_hwif_out.TIM_CCMR2.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [2]  = gpt_hwif_out.TIM_CCMR2.OC1CE_IC1F3.value  ;
      assign ccxs         [3]  = gpt_hwif_out.TIM_CCMR2.CC2S.value         ;
      assign ocxfe_icxpsc0[3]  = gpt_hwif_out.TIM_CCMR2.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[3]  = gpt_hwif_out.TIM_CCMR2.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [3]  = gpt_hwif_out.TIM_CCMR2.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [3]  = gpt_hwif_out.TIM_CCMR2.OC2CE_IC2F3.value  ;
      assign ccxs         [4]  = gpt_hwif_out.TIM_CCMR3.CC1S.value         ;
      assign ocxfe_icxpsc0[4]  = gpt_hwif_out.TIM_CCMR3.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[4]  = gpt_hwif_out.TIM_CCMR3.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [4]  = gpt_hwif_out.TIM_CCMR3.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [4]  = gpt_hwif_out.TIM_CCMR3.OC1CE_IC1F3.value  ;
      assign ccxs         [5]  = gpt_hwif_out.TIM_CCMR3.CC2S.value         ;
      assign ocxfe_icxpsc0[5]  = gpt_hwif_out.TIM_CCMR3.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[5]  = gpt_hwif_out.TIM_CCMR3.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [5]  = gpt_hwif_out.TIM_CCMR3.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [5]  = gpt_hwif_out.TIM_CCMR3.OC2CE_IC2F3.value  ;  
      assign ccxs         [6]  = gpt_hwif_out.TIM_CCMR4.CC1S.value         ;
      assign ocxfe_icxpsc0[6]  = gpt_hwif_out.TIM_CCMR4.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[6]  = gpt_hwif_out.TIM_CCMR4.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [6]  = gpt_hwif_out.TIM_CCMR4.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [6]  = gpt_hwif_out.TIM_CCMR4.OC1CE_IC1F3.value  ;
      assign ccxs         [7]  = gpt_hwif_out.TIM_CCMR4.CC2S.value         ;
      assign ocxfe_icxpsc0[7]  = gpt_hwif_out.TIM_CCMR4.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[7]  = gpt_hwif_out.TIM_CCMR4.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [7]  = gpt_hwif_out.TIM_CCMR4.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [7]  = gpt_hwif_out.TIM_CCMR4.OC2CE_IC2F3.value  ;
      assign ccxs         [8]  = gpt_hwif_out.TIM_CCMR5.CC1S.value         ;
      assign ocxfe_icxpsc0[8]  = gpt_hwif_out.TIM_CCMR5.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[8]  = gpt_hwif_out.TIM_CCMR5.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [8]  = gpt_hwif_out.TIM_CCMR5.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [8]  = gpt_hwif_out.TIM_CCMR5.OC1CE_IC1F3.value  ;
      assign ccxs         [9]  = gpt_hwif_out.TIM_CCMR5.CC2S.value         ;
      assign ocxfe_icxpsc0[9]  = gpt_hwif_out.TIM_CCMR5.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[9]  = gpt_hwif_out.TIM_CCMR5.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [9]  = gpt_hwif_out.TIM_CCMR5.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [9]  = gpt_hwif_out.TIM_CCMR5.OC2CE_IC2F3.value  ;
      assign ccxs         [10] = gpt_hwif_out.TIM_CCMR6.CC1S.value         ;
      assign ocxfe_icxpsc0[10] = gpt_hwif_out.TIM_CCMR6.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[10] = gpt_hwif_out.TIM_CCMR6.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [10] = gpt_hwif_out.TIM_CCMR6.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [10] = gpt_hwif_out.TIM_CCMR6.OC1CE_IC1F3.value  ;
      assign ccxs         [11] = gpt_hwif_out.TIM_CCMR6.CC2S.value         ;
      assign ocxfe_icxpsc0[11] = gpt_hwif_out.TIM_CCMR6.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[11] = gpt_hwif_out.TIM_CCMR6.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [11] = gpt_hwif_out.TIM_CCMR6.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [11] = gpt_hwif_out.TIM_CCMR6.OC2CE_IC2F3.value  ; 
      assign ccxs         [12] = gpt_hwif_out.TIM_CCMR7.CC1S.value         ;
      assign ocxfe_icxpsc0[12] = gpt_hwif_out.TIM_CCMR7.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[12] = gpt_hwif_out.TIM_CCMR7.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [12] = gpt_hwif_out.TIM_CCMR7.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [12] = gpt_hwif_out.TIM_CCMR7.OC1CE_IC1F3.value  ;
      assign ccxs         [13] = gpt_hwif_out.TIM_CCMR7.CC2S.value         ;
      assign ocxfe_icxpsc0[13] = gpt_hwif_out.TIM_CCMR7.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[13] = gpt_hwif_out.TIM_CCMR7.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [13] = gpt_hwif_out.TIM_CCMR7.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [13] = gpt_hwif_out.TIM_CCMR7.OC2CE_IC2F3.value  ; 
      assign ccxs         [14] = gpt_hwif_out.TIM_CCMR8.CC1S.value         ;
      assign ocxfe_icxpsc0[14] = gpt_hwif_out.TIM_CCMR8.OC1FE_IC1PSC0.value;
      assign ocxpe_icxpsc1[14] = gpt_hwif_out.TIM_CCMR8.OC1PE_IC1PSC1.value;
      assign ocxm_icxf    [14] = gpt_hwif_out.TIM_CCMR8.OC1M_IC1F.value    ;
      assign ocxce_icxf3  [14] = gpt_hwif_out.TIM_CCMR8.OC1CE_IC1F3.value  ;
      assign ccxs         [15] = gpt_hwif_out.TIM_CCMR8.CC2S.value         ;
      assign ocxfe_icxpsc0[15] = gpt_hwif_out.TIM_CCMR8.OC2FE_IC2PSC0.value;
      assign ocxpe_icxpsc1[15] = gpt_hwif_out.TIM_CCMR8.OC2PE_IC2PSC1.value;
      assign ocxm_icxf    [15] = gpt_hwif_out.TIM_CCMR8.OC2M_IC2F.value    ;
      assign ocxce_icxf3  [15] = gpt_hwif_out.TIM_CCMR8.OC2CE_IC2F3.value  ;

      // Input Channel
      logic [1:0] icxpsc [15:0];
      logic [3:0] icxf   [15:0];

      //Output Channel
      logic       ocxfe [15:0];
      logic       ocxpe [15:0];
      logic [2:0] ocxm  [15:0];
      logic       ocxce [15:0];

      always_comb begin
        for (int i = 0; i < CH_PAIRS_NUM * 2; i = i + 1) begin
          ocxfe[i] = ocxfe_icxpsc0[i];
          ocxpe[i] = ocxpe_icxpsc1[i];
          ocxm [i] = ocxm_icxf    [i];
          ocxce[i] = ocxce_icxf3  [i];

          icxpsc[i] = {ocxpe_icxpsc1, ocxfe_icxpsc0};
          icxf  [i] = {ocxce_icxf3  , ocxm_icxf    };
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
    else if (CH_PAIRS_NUM == 5 || CH_PAIRS_NUM == 6) begin
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
    else if (CH_PAIRS_NUM == 7 || CH_PAIRS_NUM == 8) begin
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

  assign uie      = gpt_hwif_out.TIM_DIER.UIE.value;
  assign tie      = gpt_hwif_out.TIM_DIER.TIE.value;
  assign ude      = gpt_hwif_out.TIM_DIER.UDE.value;
  assign tde      = gpt_hwif_out.TIM_DIER.TDE.value;

  generate
    if (CH_PAIRS_NUM == 1 || CH_PAIRS_NUM == 2) begin
      logic       uie  ;
      logic [3:0] ccxie;
      logic       tie  ;
      logic       ude  ;
      logic [3:0] ccxde;
      logic       tde  ;

      assign ccxie[0] = gpt_hwif_out.TIM_DIER.CC1E.value ;
      assign ccxie[1] = gpt_hwif_out.TIM_DIER.CC2E.value ;
      assign ccxie[2] = gpt_hwif_out.TIM_DIER.CC3E.value ;
      assign ccxie[3] = gpt_hwif_out.TIM_DIER.CC4E.value ;

      assign ccxde[0] = gpt_hwif_out.TIM_DIER.CC1DE.value;
      assign ccxde[1] = gpt_hwif_out.TIM_DIER.CC2DE.value;
      assign ccxde[2] = gpt_hwif_out.TIM_DIER.CC3DE.value;
      assign ccxde[3] = gpt_hwif_out.TIM_DIER.CC4DE.value;
    end
    else if (CH_PAIRS_NUM == 3 || CH_PAIRS_NUM == 4) begin
      logic       uie  ;
      logic [7:0] ccxie;
      logic       tie  ;
      logic       ude  ;
      logic [7:0] ccxde;
      logic       tde  ;

      assign ccxie[0] = gpt_hwif_out.TIM_DIER1.CC1E.value ;
      assign ccxie[1] = gpt_hwif_out.TIM_DIER1.CC2E.value ;
      assign ccxie[2] = gpt_hwif_out.TIM_DIER1.CC3E.value ;
      assign ccxie[3] = gpt_hwif_out.TIM_DIER1.CC4E.value ;
      assign ccxie[4] = gpt_hwif_out.TIM_DIER2.CC1E.value ;
      assign ccxie[5] = gpt_hwif_out.TIM_DIER2.CC2E.value ;
      assign ccxie[6] = gpt_hwif_out.TIM_DIER2.CC3E.value ;
      assign ccxie[7] = gpt_hwif_out.TIM_DIER2.CC4E.value ;

      assign ccxde[0] = gpt_hwif_out.TIM_DIER1.CC1DE.value;
      assign ccxde[1] = gpt_hwif_out.TIM_DIER1.CC2DE.value;
      assign ccxde[2] = gpt_hwif_out.TIM_DIER1.CC3DE.value;
      assign ccxde[3] = gpt_hwif_out.TIM_DIER1.CC4DE.value;
      assign ccxde[4] = gpt_hwif_out.TIM_DIER2.CC1DE.value;
      assign ccxde[5] = gpt_hwif_out.TIM_DIER2.CC2DE.value;
      assign ccxde[6] = gpt_hwif_out.TIM_DIER2.CC3DE.value;
      assign ccxde[7] = gpt_hwif_out.TIM_DIER2.CC4DE.value;

    end
    else if (CH_PAIRS_NUM == 5 || CH_PAIRS_NUM == 6) begin
      logic       uie   ;
      logic [11:0] ccxie;
      logic       tie   ;
      logic       ude   ;
      logic [11:0] ccxde;
      logic       tde   ;

      assign ccxie[0]  = gpt_hwif_out.TIM_DIER1.CC1E.value ;
      assign ccxie[1]  = gpt_hwif_out.TIM_DIER1.CC2E.value ;
      assign ccxie[2]  = gpt_hwif_out.TIM_DIER1.CC3E.value ;
      assign ccxie[3]  = gpt_hwif_out.TIM_DIER1.CC4E.value ;
      assign ccxie[4]  = gpt_hwif_out.TIM_DIER2.CC1E.value ;
      assign ccxie[5]  = gpt_hwif_out.TIM_DIER2.CC2E.value ;
      assign ccxie[6]  = gpt_hwif_out.TIM_DIER2.CC3E.value ;
      assign ccxie[7]  = gpt_hwif_out.TIM_DIER2.CC4E.value ;
      assign ccxie[8]  = gpt_hwif_out.TIM_DIER3.CC1E.value ;
      assign ccxie[9]  = gpt_hwif_out.TIM_DIER3.CC2E.value ;
      assign ccxie[10] = gpt_hwif_out.TIM_DIER3.CC3E.value ;
      assign ccxie[11] = gpt_hwif_out.TIM_DIER3.CC4E.value ;

      assign ccxde[0]  = gpt_hwif_out.TIM_DIER1.CC1DE.value;
      assign ccxde[1]  = gpt_hwif_out.TIM_DIER1.CC2DE.value;
      assign ccxde[2]  = gpt_hwif_out.TIM_DIER1.CC3DE.value;
      assign ccxde[3]  = gpt_hwif_out.TIM_DIER1.CC4DE.value;
      assign ccxde[4]  = gpt_hwif_out.TIM_DIER2.CC1DE.value;
      assign ccxde[5]  = gpt_hwif_out.TIM_DIER2.CC2DE.value;
      assign ccxde[6]  = gpt_hwif_out.TIM_DIER2.CC3DE.value;
      assign ccxde[7]  = gpt_hwif_out.TIM_DIER2.CC4DE.value;
      assign ccxde[8]  = gpt_hwif_out.TIM_DIER3.CC1DE.value;
      assign ccxde[9]  = gpt_hwif_out.TIM_DIER3.CC2DE.value;
      assign ccxde[10] = gpt_hwif_out.TIM_DIER3.CC3DE.value;
      assign ccxde[11] = gpt_hwif_out.TIM_DIER3.CC4DE.value;
    end
    else if (CH_PAIRS_NUM == 7 || CH_PAIRS_NUM == 8) begin
      logic       uie   ;
      logic [14:0] ccxie;
      logic       tie   ;
      logic       ude   ;
      logic [14:0] ccxde;
      logic       tde   ;

      assign ccxie[0]  = gpt_hwif_out.TIM_DIER1.CC1E.value ;
      assign ccxie[1]  = gpt_hwif_out.TIM_DIER1.CC2E.value ;
      assign ccxie[2]  = gpt_hwif_out.TIM_DIER1.CC3E.value ;
      assign ccxie[3]  = gpt_hwif_out.TIM_DIER1.CC4E.value ;
      assign ccxie[4]  = gpt_hwif_out.TIM_DIER2.CC1E.value ;
      assign ccxie[5]  = gpt_hwif_out.TIM_DIER2.CC2E.value ;
      assign ccxie[6]  = gpt_hwif_out.TIM_DIER2.CC3E.value ;
      assign ccxie[7]  = gpt_hwif_out.TIM_DIER2.CC4E.value ;
      assign ccxie[8]  = gpt_hwif_out.TIM_DIER3.CC1E.value ;
      assign ccxie[9]  = gpt_hwif_out.TIM_DIER3.CC2E.value ;
      assign ccxie[10] = gpt_hwif_out.TIM_DIER3.CC3E.value ;
      assign ccxie[11] = gpt_hwif_out.TIM_DIER3.CC4E.value ;
      assign ccxie[12] = gpt_hwif_out.TIM_DIER4.CC1E.value ;
      assign ccxie[13] = gpt_hwif_out.TIM_DIER4.CC2E.value ;
      assign ccxie[14] = gpt_hwif_out.TIM_DIER4.CC3E.value ;
      assign ccxie[15] = gpt_hwif_out.TIM_DIER4.CC4E.value ;

      assign ccxde[0]  = gpt_hwif_out.TIM_DIER1.CC1DE.value;
      assign ccxde[1]  = gpt_hwif_out.TIM_DIER1.CC2DE.value;
      assign ccxde[2]  = gpt_hwif_out.TIM_DIER1.CC3DE.value;
      assign ccxde[3]  = gpt_hwif_out.TIM_DIER1.CC4DE.value;
      assign ccxde[4]  = gpt_hwif_out.TIM_DIER2.CC1DE.value;
      assign ccxde[5]  = gpt_hwif_out.TIM_DIER2.CC2DE.value;
      assign ccxde[6]  = gpt_hwif_out.TIM_DIER2.CC3DE.value;
      assign ccxde[7]  = gpt_hwif_out.TIM_DIER2.CC4DE.value;
      assign ccxde[8]  = gpt_hwif_out.TIM_DIER3.CC1DE.value;
      assign ccxde[9]  = gpt_hwif_out.TIM_DIER3.CC2DE.value;
      assign ccxde[10] = gpt_hwif_out.TIM_DIER3.CC3DE.value;
      assign ccxde[11] = gpt_hwif_out.TIM_DIER3.CC4DE.value;
      assign ccxde[12] = gpt_hwif_out.TIM_DIER4.CC1DE.value;
      assign ccxde[13] = gpt_hwif_out.TIM_DIER4.CC2DE.value;
      assign ccxde[14] = gpt_hwif_out.TIM_DIER4.CC3DE.value;
      assign ccxde[15] = gpt_hwif_out.TIM_DIER4.CC4DE.value;
    end
  endgenerate

  // TIM_SR
  logic       uif  ;
  logic       tif  ;

  assign gpt_hwif_in.TIM_SR.UIF.next = uif;
  assign gpt_hwif_in.TIM_SR.TIF.next = tif;

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

  logic       ti2fp2        ;
  logic       ti1fp1        ;
  logic       oc_ref_mms    ;


  logic sm_reset ;
  logic sm_enable;
  logic sm_trig  ;

  trigger_controller trig_inst 
  (
    .clk_i      (aclk_i           ),
    .aresetn_i  (aresetn_i        ),
    .itr_i      (itr_i            ),
    .ckd_i      (ckd              ),
    .etp_i      (etp              ),
    .sms_i      (sms              ),
    .etps_i     (etps             ),
    .ts_i       (ts               ),
    .etf_i      (etf              ),
    .ece_i      (ece              ),
    .ti2fp2_i   (ti2fp2           ),
    .ti1fp1_i   (ti1fp1           ),
    .ti1_ed_i   (ti1f_ed          ),
    .etr_i      (etr_i            ),
    .sm_reset_o (sm_reset         ),
    .sm_enable_o(sm_enable        ),
    .sm_trig_o  (sm_trig          ),
    .trg_o      (trg_o            ),
    .clk_psc_o  (clk_psc          )
  );

  prescaler #(.PSC_WIDTH(PSC_WIDTH))
  (
    .clk_i    (clk_psc  ),
    .aresetn_i(aresetn_i),
    .uev_i    (uev      ),
    .psc_i    (psc      ),
    .clk_o    (clk_cnt  )
  );

  logic [CNT_WIDTH - 1:0]        cnt_value;
  logic [CH_PAIRS_NUM * 2 - 1:0] uev      ;

  time_base_unit time_base_inst
  (
    .clk_i    (clk_cnt       ),
    .aresetn_i(aresetn_i     ),
    .cen_i    (cen           ),
    .apre_i   (apre          ),
    .dir_i    (dir           ),
    .arr_i    (arr           ),
    .psc_i    (psc           ),
    .udis_i   (udis          ),
    .ug_i     (ug            ),
    .uif_o    (uif           ),
    .uev_o    (uev           ),
    .cnt_o    (cnt_value     )
  );

  tim_channel channel_inst
  (
    .clk_i          (aclk_i    ),
    .aresetn_i      (aresetn_i ),
    .ckd_i          (ckd       ),
    .icf_i          (icxf[0]   ),
    .cnt_i          (cnt_value ),
    .ccr_i          (ccr_reg[0]),
    .uev_i          (uev[0]    ),
    .ti_i           (ch_i[0]   ),
    .trc_i          (),
    .cc1s_i         (ccxs[0]   ),
    .icps_i         (icxpsc[0] ),
    .cce_i          (),
    .dir_i          (dir       ),
    .ocxm_i         (ocxm      ),
    .ccg_i          (),
    .ocxpe_i        (),
    .ti_neigx_fpx_i (),
    .cc1p_i         (),
    .cc1np_i        (),

    .ti1_fd_o       (ti1f_ed),
    .oc_ref_o       (oc_ref_mms        ),
    .ccxif_o        (),
    .ccr_o          (ccr_to_regblock[0]),
    .ccxof_o        (ccxof[0]          ),
    .ti1fp1_o       (),
    .ti_o           (ch_o[0])
  );
  tim_channel channel_inst
  (
    .clk_i          (aclk_i    ),
    .aresetn_i      (aresetn_i ),
    .ckd_i          (ckd       ),
    .icf_i          (icxf[1]   ),
    .cnt_i          (cnt_value ),
    .ccr_i          (ccr_reg[1]),
    .uev_i          (uev    [1]),
    .ti_i           (ch_i   [1]),
    .trc_i          (),
    .cc1s_i         (ccxs   [1]),
    .icps_i         (icxpsc [1]),
    .cce_i          (ccxe   [1]),
    .dir_i          (dir       ),
    .ocxm_i         (ocxm   [1]),
    .ccg_i          (),
    .ocxpe_i        (),
    .cc1p_i         (ccxp[1]   ),
    .cc1np_i        (ccxnp[1]  ),

    .ti1_fd_o       (ti1f_ed),
    .oc_ref_o       (),
    .ccxif_o        (),
    .ccr_o          (ccr_to_regblock[1]),
    .ccxof_o        (),
    .ti1fp1_o       (),
    .ti_o           (ch_o[1])
  );

  generate
    if (CH_PAIRS_NUM > 1) begin
      for (genvar i = CH_PAIRS_NUM; i < CH_PAIRS_NUM * 2; i++) begin : g_tim_ch
        tim_channel channel_inst
        (
          .clk_i          (aclk_i    ),
          .aresetn_i      (aresetn_i ),
          .ckd_i          (ckd       ),
          .icf_i          (icxf[i]   ),
          .cnt_i          (cnt_value ),
          .ccr_i          (ccr_reg[i]),
          .uev_i          (),
          .ti_i           (ch_i[i]   ),
          .trc_i          (),
          .cc1s_i         (ccxs[i]   ),
          .icps_i         (),
          .cce_i          (ccxe[i]   ),
          .dir_i          (dir       ),
          .ocxm_i         (ocxm[i]   ),
          .ccg_i          (ccxg[i]   ),
          .ocxpe_i        (),
          .ti_neigx_fpx_i (),
          .cc1p_i         (),
          .cc1np_i        (),

          .ti1_fd_o       (ti1f_ed),
          .oc_ref_o       (),
          .ccxif_o        (ccxif[i]),
          .ccr_o          (ccr_to_regblock[i]),
          .ccxof_o        (ccxof[i]          ),
          .ti1fp1_o       (),
          .ti_o           (ch_o[i])
        );
      end
    end
  endgenerate
endmodule