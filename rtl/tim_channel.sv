module tim_channel #(parameter CCR_WIDTH = 32,
                    parameter  CNT_WIDTH = 32) (
  input logic                    clk_i    ,
  input logic                    aresetn_i,
  input logic  [1:0]             ckd_i    ,
  input logic  [3:0]             icf_i    ,
  input logic  [CNT_WIDTH - 1:0] cnt_i    ,       // Counter value from Time-Base Unit
  input logic  [CCR_WIDTH - 1:0] ccr_i    ,       // CCR value from RegBlock
  input logic                    uev_i    ,       // Update Event  from Time-Base Unit
  input logic                    ti_i     ,       // TIM Channel value
  input logic                    trc_i    ,
  input logic  [1:0]             cc1s_i   ,
  input logic  [1:0]             icps_i   ,
  input logic                    cce_i    ,       // enable for capture value into CCRx register
  input logic                    dir_i    ,       // Count direction
  input logic  [2:0]             ocxm_i   ,       // 
  input logic                    ccg_i    ,
  input logic                    ocxpe_i   ,
  input logic                    ti_neigx_fpx_i ,
  input logic                    cc1p_i   ,
  input logic                    cc1np_i  ,

  output logic                   ti1_fd_o ,
  output logic                   oc_ref_o ,      // Reference signal to Master Mode Controller
  output logic                   ccxif_o  ,
  output logic [CCR_WIDTH - 1:0] ccr_o    ,      // output CCRx value for load into RegBlock
  output logic                   ccxof_o  ,
  output logic                   tixfpx_o ,
  output logic                   ti_o
);

  logic       clk_dts         ;
  logic       tif             ;
  logic [1:0] polarity_sel    ;
  logic       input_mode      ;
  logic       output_mode     ;
  logic       shadow_reg_ccr  ; // shadow register for CCRx
  logic       capture_enable  ; // enable capture mode
  logic       compare_enable  ; // enable compare mode
  logic       ic1ps           ;

  assign input_mode  =   cc1s_i[0] | cc1s_i[1];
  assign output_mode = ~(cc1s_i[0] | cc1s_i[1]);

  assign capture_enable = input_mode & (cce_i | ic1ps & ccg_i);
  assign compare_enable = output_mode & (~ocxpe_i | uev_i);

 // Shadow Register logic 
  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      shadow_reg_ccr <= {CCR_WIDTH{1'b0}};
    else if (capture_enable)  // Capture Mode
      shadow_reg_ccr <= cnt_i;
    else if (compare_enable)    // Compare Mode
      shadow_reg_ccr <= ccr_i;
  
  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      ccxif_o <= 1'b0;
    else if (capture_enable) // Capture first value into CCR Register
      ccxif_o <= 1'b1;
  
  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      ccxof_o <= 1'b0;
    else if (capture_enable & ccxif_o) // Capture second value into CCR Register
      ccxof_o <= 1'b1;

  assign ccr_o = shadow_reg_ccr;

  fdts_generator fdts_gen 
  (
    .clk_i    (clk_i    ),
    .aresetn_i(aresetn_i),
    .ckd_i    (ckd_i    ),
    .clk_dts_o(clk_dts  )
  );

  digital_filter i_filt
  (
    .clk_i    (clk_dts  ),
    .aresetn_i(aresetn_i),
    .a_i      (ti_i     ),
    .f_coef_i (icf_i    ),
    .af_o   (tif      )
  );

  logic tif_r;
  logic tif_f;

  edge_detector i_edge
  (
    .clk_i      (clk_i    ),
    .aresetn_i  (aresetn_i),
    .a_i        (tif      ),
    .edge_rise_o(tif_r    ),
    .edge_fall_o(tif_f    )
  );

  assign tixfpx = cc1p_i ? tif_r : tif_f;
  assign polarity_sel = {cc1p_i, cc1np_i};

  logic ic1;

  always_comb begin
    case (cc1s_i)
      2'b00:  ic1 = tixfpx        ;
      2'b01:  ic1 = ti_neigx_fpx_i;
      2'b10:  ic1 = trc_i         ;
      default ic1 = 1'b0          ;
    endcase
  end

  divider_output div_inst
  (
    .clk_i    (ic1      ),
    .aresetn_i(aresetn_i),
    .cce_i    (cce_i    ),
    .icps_i   (icps_i   ),
    .clk_o    (ic1ps    )
  );

  logic cnt_equal_ccr    ;
  logic cnt_less_than_ccr;
  logic cnt_more_than_ccr;

  assign cnt_equal_ccr     = (cnt_i == shadow_reg_ccr);
  assign cnt_less_than_ccr = (cnt_i < shadow_reg_ccr) ;
  assign cnt_more_than_ccr = (cnt_i > shadow_reg_ccr) ;

  output_control i_control_out
  (
    .clk_i              (clk_i            ),
    .aresetn_i          (aresetn_i        ),
    .cnt_equal_ccr_i    (cnt_equal_ccr    ),
    .dir_i              (dir_i            ),
    .cnt_less_than_ccr_i(cnt_less_than_ccr),
    .cnt_more_than_ccr_i(cnt_more_than_ccr),
    .ocm_i              (ocxm_i           ),
    .oc_ref_o           (oc_ref_o         )
  );

  logic oc_ref_p;

  assign oc_ref_p = cc1p_i ? ~oc_ref_o : oc_ref_o;
  assign ti_o     = cce_i  ? oc_ref_p  : 1'b0    ;

endmodule