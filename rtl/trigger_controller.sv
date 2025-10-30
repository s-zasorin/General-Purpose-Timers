module trigger_controller #(parameter CH_PAIRS_NUM = 2) (
  input  logic                          clk_i    ,
  input  logic                          aresetn_i,
  input  logic [CH_PAIRS_NUM * 2 - 1:0] itr_i    ,
  input  logic [1:0]                    ckd_i    ,
  input  logic                          etp_i    ,
  input  logic                          etps_i   ,
  input  logic [2:0]                    ts_i     ,
  input  logic [3:0]                    etf_i    ,
  input  logic                          ece_i    ,
  input  logic                          ti2fp2_i ,
  input  logic                          ti1fp1_i ,
  input  logic                          ti1_ed_i ,
  input  logic                          etr_i    ,

  output logic trg_o                             ,
  output logic clk_psc_o
);
  logic clk_dts;
  fdts_generator fd_gen
  (
    .clk_i    (clk_i    ),
    .aresetn_i(aresetn_i),
    .ckd_i    (ckd_i    ),
    .clk_dts_o(clk_dts  )
  );

  logic etrp;
  logic etrpd;
  logic etrpdf;

  assign etrp = etp_i ? ~etr_i : etr_i;

  divider_trigger div_trig_inst
  (
    .clk_i    (etrp     ),
    .aresetn_i(aresetn_i),
    .etps_i   (etps_i   ),
    .clk_o    (etrpd    )
  );

  digital_filter i_digital_filter
  (
    .clk_i    (clk_dts  ),
    .aresetn_i(aresetn_i),
    .a_i      (etrpd    ),
    .f_coef_i (etf_i    ),
    .af_o     (etrpdf   )
  );




endmodule