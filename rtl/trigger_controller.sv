module trigger_controller #(parameter CH_PAIRS_NUM = 2) (
  input  logic                          clk_i     ,
  input  logic                          aresetn_i ,
  input  logic [3:0]                    itr_i     ,
  input  logic [1:0]                    ckd_i     ,
  input  logic                          etp_i     ,
  input  logic [2:0]                    sms_i     ,
  input  logic                          etps_i    ,
  input  logic [2:0]                    ts_i      ,
  input  logic [3:0]                    etf_i     ,
  input  logic                          ece_i     ,
  input  logic                          ti2fp2_i  ,
  input  logic                          ti1fp1_i  ,
  input  logic                          ti1_ed_i  ,
  input  logic                          etr_i     ,

  output logic                          trg_o     ,
  output logic                          en_rst_cnt_o ,
  output logic                          en_gate_cnt_o,
  output logic                          en_trig_cnt_o,
  output logic                          clk_psc_o
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

  logic trgi;
  always_comb begin
    case (ts_i)
      3'b000:  trgi = itr_i[0];
      3'b001:  trgi = itr_i[1];
      3'b010:  trgi = itr_i[2];
      3'b011:  trgi = itr_i[3];
      3'b100:  trgi = ti1_ed_i;
      3'b101:  trgi = ti1fp1_i;
      3'b110:  trgi = ti2fp2_i;
      3'b111:  trgi = etrpdf  ;
      default: trgi = 3'b000  ;
    endcase
  end

  logic enc_clk_1d2;
  logic enc_clk_2d1;
  encoder_mode i_enc_mode
  (
    .clk_i    (clk_i      ),
    .aresetn_i(aresetn_i  ),
    .ti1f_i   (ti1fp1_i   ),
    .ti2f_i   (ti2fp2_i   ),
    .clk_1d2_o(enc_clk_1d2),
    .clk_2d1_o(enc_clk_2d1)
  );

  always_comb begin
    rst_cnt_o  = 1'b0;
    gate_cnt_o = 1'b0;
    trig_cnt_o = 1'b0;
    clk_psc_o  = 1'b0;
    case (sms_i)
      3'b000: clk_psc_o = clk_i      ;
      3'b001: clk_psc_o = enc_clk_1d2;
      3'b010: clk_psc_o = enc_clk_2d1;
      3'b100: begin
        clk_psc_o = trgi;
        rst_cnt_o = 1'b1;
      end
      3'b101: begin
        clk_psc_o  = trgi;
        gate_cnt_o = 1'b1;
      end
      3'b110: begin
        clk_psc_o  = trgi;
        trig_cnt_o = 1'b1;
      end
      3'b111: clk_psc_o = trgi;
    endcase
  end

endmodule