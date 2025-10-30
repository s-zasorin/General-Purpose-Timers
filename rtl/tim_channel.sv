module tim_channel (
  input logic                    clk_i    ,
  input logic                    aresetn_i,
  input logic  [1:0]             ckd_i    ,
  input logic  [3:0]             icf_i    ,
  input logic  [CNT_WIDTH - 1:0] cnt_i    ,
  input logic                    ti_i     ,
  input logic                    trc_i    ,
  input logic  [1:0]             cc1s_i   ,
  input logic  [1:0]             icps_i   ,
  input logic                    cce_i    ,
  input logic                    ti2fp1_i ,
  input logic                    cc1p_i   ,
  input logic                    cc1np_i  ,

  output logic                   ti1_fd_o ,
  output logic                   ti1fp1_o ,
  output logic                   ti_o
);

  logic       clk_dts     ;
  logic       tif         ;
  logic [1:0] polarity_sel;

  assign ti1fp1 = cc1p_i ? tif_r : tif_f;

  fdts_generator fdts_gen 
  (
    .clk_i    (clk_i    ),
    .aresetn_i(aresetn_i),
    .ckd_i    (ckd_i    ),
    .cld_dts_o(clk_dts  )
  );

  digital_filter filt
  (
    .clk_i    (clk_dts  ),
    .aresetn_i(aresetn_i),
    .icf_i    (icf_i    ),
    .clkf_o   (tif      )
  );

  logic tif_r;
  logic tif_f;

  edge_detector edge
  (
    .a_i        (tif  ),
    .edge_rise_o(tif_r),
    .edge_fall_o(tif_f)
  );

assign polarity_sel = {cc1p_i, cc1np_i};

logic ic1;

always_comb begin
  case (cc1s)
    2'b00:  ic1 = ti1fp1  ;
    2'b01:  ic1 = ti2fp1_i;
    2'b10:  ic1 = trc_i   ;
    default ic1 = 1'b0    ;
  endcase
end

logic ic1ps;
divider div_inst
(
  .clk_i    (ic1      ),
  .aresetn_i(aresetn_i),
  .cce_i    (cce_i    ),
  .icps_i   (icps_i   ),
  .clk_o    (ic1ps    )
);

endmodule