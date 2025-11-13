module trigger_controller #(parameter CH_PAIRS_NUM = 2) (
  input  logic                          clk_i         ,
  input  logic                          aresetn_i     ,
  input  logic [3:0]                    itr_i         ,
  input  logic [1:0]                    ckd_i         ,
  input  logic                          etp_i         ,
  input  logic [2:0]                    sms_i         ,
  input  logic [2:0]                    mms_i         ,
  input  logic [1:0]                    etps_i        ,
  input  logic [2:0]                    ts_i          ,
  input  logic [3:0]                    etf_i         ,
  input  logic                          ug_i          ,
  input  logic                          cc1if_i       ,
  input  logic                          uev_i         ,
  input  logic                          cnt_en_i      ,
  input  logic                          ece_i         ,
  input  logic                          ti2fp2_i      ,
  input  logic                          ti1fp1_i      ,
  input  logic                          ti1_ed_i      ,
  input  logic                          etr_i         ,

  output logic                          sm_reset_o    ,
  output logic                          sm_gate_o     ,
  output logic                          sm_trig_o     ,
  output logic                          trc_o         ,
  output logic                          trg_o         ,
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

  logic trgi   ;
  
  always_comb begin
    case (ts_i)
      3'b000 : trc_o = itr_i[0];
      3'b001 : trc_o = itr_i[1];
      3'b010 : trc_o = itr_i[2];
      3'b011 : trc_o = itr_i[3];
      default: trc_o = 1'b0    ;
    endcase
  end

  always_comb begin
    case (ts_i)
      3'b0xx:  trgi = trc_o   ;
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
    sm_gate_o    = 1'b0;
    sm_reset_o     = 1'b0;
    sm_trig_o      = 1'b0;
    clk_psc_o      = 1'b0;
    case (sms_i)
      3'b000: begin                   // Режим внутреннего тактирования
        clk_psc_o = clk_i      ;
      end
      3'b001: clk_psc_o = enc_clk_1d2; // Режим энкодера №1
      3'b010: clk_psc_o = enc_clk_2d1; // Режим энкодера №2
      3'b100: begin                    // Режим сброса
        clk_psc_o  = clk_i;
        sm_reset_o = trgi ;
      end
      3'b101: begin                   // Режим стробирования
        clk_psc_o   = clk_i;
        sm_gate_o = trgi ;
      end
      3'b110: begin                   // Режим триггера
        clk_psc_o  = clk_i;
        sm_trig_o  = 1'b1 ;
      end
      3'b111: clk_psc_o = trgi;
    endcase
  end

  always_comb begin
    case (mms_i)
      2'b00:   trg_o = ug_i    ;
      2'b01:   trg_o = cnt_en_i;
      2'b10:   trg_o = uev_i   ;
      2'b11:   trg_o = cc1if_i ;
      default: trg_o = 1'b0    ;
    endcase
  end

endmodule