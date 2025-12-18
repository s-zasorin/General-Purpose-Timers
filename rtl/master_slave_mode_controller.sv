module master_slave_mode_controller #(parameter CH_PAIRS_NUM = 2,
                                      parameter PSC_WIDTH    = 16) (
  input  logic                 clk_i       ,
  input  logic                 rstn_i      ,
  input  logic [3:0]           itr_i       ,
  input  logic [1:0]           ckd_i       ,
  input  logic                 etp_i       ,
  input  logic [2:0]           sms_i       ,
  input  logic [2:0]           mms_i       ,
  input  logic [1:0]           etps_i      ,
  input  logic [2:0]           ts_i        ,
  input  logic [3:0]           etf_i       ,
  input  logic                 ug_i        ,
  input  logic [PSC_WIDTH-1:0] psc_i       , 
  input  logic                 dir_i       ,
  input  logic                 ti1f_i      ,
  input  logic                 cc1if_i     ,
  input  logic                 uev_i       ,
  input  logic                 cnt_en_i    ,
  input  logic                 ece_i       ,
  input  logic                 ti2fp2_i    ,
  input  logic                 ti1fp1_i    ,
  input  logic                 ti1_ed_i    ,
  input  logic                 etr_i       ,

  output logic                 sm_reset_o  ,
  output logic                 sm_gate_o   ,
  output logic                 dir_o       ,
  output logic                 sm_trig_o   ,
  output logic                 trc_o       ,
  output logic                 trg_o       ,
  output logic                 clk_event_o
);

  logic sm_reset    ;
  logic sm_reset_ff ;

  logic sm_gate     ;
  logic sm_gate_ff  ;

  logic sm_trig     ;
  logic sm_trig_ff  ;

  logic dir         ;
  logic dir_ff      ;
  
  logic clk_event   ;
  logic clk_event_ff;

  logic etrp;
  logic etrpd;
  logic etrpdf;

  assign etrp = etp_i ? ~etr_i : etr_i;

  divider_trigger div_trig_inst
  (
    .clk_i    (clk_i ),
    .etrp_i   (etrp  ),
    .rstn_i   (rstn_i),
    .etps_i   (etps_i),
    .etrp_o   (etrpd )
  );

  digital_filter i_digital_filter
  (
    .clk_i    (clk_i ),
    .rstn_i   (rstn_i),
    .a_i      (etrpd ),
    .f_coef_i (etf_i ),
    .af_o     (etrpdf)
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
      3'b000 : trgi = itr_i[0];
      3'b001 : trgi = itr_i[1];
      3'b010 : trgi = itr_i[2];
      3'b011 : trgi = itr_i[3];
      3'b100 : trgi = ti1_ed_i;
      3'b101 : trgi = ti1fp1_i;
      3'b110 : trgi = ti2fp2_i;
      3'b111 : trgi = etrpdf  ;
      default: trgi = 1'b0    ;
    endcase
  end

  logic new_dir_mode1;
  logic new_dir_mode2;

  encoder_mode i_enc_mode
  (
    .clk_i          (clk_i        ),
    .rstn_i         (rstn_i       ),
    .ti1fp1_i       (ti1fp1_i     ),
    .ti2fp2_i       (ti2fp2_i     ),
    .default_dir_i  (dir_i        ),
    .new_dir_mode1_o(new_dir_mode1),
    .new_dir_mode2_o(new_dir_mode2)
  );
  
  always_comb begin
    sm_gate                = 1'b0 ;
    sm_reset               = 1'b0 ;
    sm_trig                = 1'b0 ;
    clk_event              = 1'b0 ;
    dir                    = dir_i;
    case (sms_i)
      3'b000: begin                   // Режим внутреннего тактирования
        clk_event         = 1'b0         ;
      end
      3'b001: begin // Режим энкодера №1
        dir               = new_dir_mode1;
      end
      3'b010: begin // Режим энкодера №2
        dir               = new_dir_mode2;
      end  
      3'b100: begin                    // Режим сброса
        sm_reset          = trgi         ;
      end
      3'b101: begin                   // Режим стробирования
        sm_gate           = ti1f_i       ;
      end
      3'b110: begin                   // Режим триггера
        sm_trig           = trgi         ;
      end
      3'b111: clk_event   = trgi         ;
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

  stretch_signal #(.PSC_WIDTH(PSC_WIDTH)) i_stretch_reset
  (
    .clk_i (clk_i      ),
    .rstn_i(rstn_i     ),
    .psc_i (psc_i      ),
    .a_i   (sm_reset   ),
    .a_o   (sm_reset_ff)
  );

  stretch_signal #(.PSC_WIDTH(PSC_WIDTH)) i_stretch_gate
  (
    .clk_i (clk_i     ),
    .rstn_i(rstn_i    ),
    .psc_i (psc_i     ),
    .a_i   (sm_gate   ),
    .a_o   (sm_gate_ff)
  );

  stretch_signal #(.PSC_WIDTH(PSC_WIDTH)) i_stretch_trig
  (
    .clk_i (clk_i     ),
    .rstn_i(rstn_i    ),
    .psc_i (psc_i     ),
    .a_i   (sm_trig   ),
    .a_o   (sm_trig_ff)
  );

  stretch_signal #(.PSC_WIDTH(PSC_WIDTH)) i_stretch_dir
  (
    .clk_i (clk_i ),
    .rstn_i(rstn_i),
    .psc_i (psc_i ),
    .a_i   (dir   ),
    .a_o   (dir_ff)
  );

  stretch_signal #(.PSC_WIDTH(PSC_WIDTH)) i_stretch_clk_event
  (
    .clk_i (clk_i       ),
    .rstn_i(rstn_i      ),
    .psc_i (psc_i       ),
    .a_i   (clk_event   ),
    .a_o   (clk_event_ff)
  );

  assign sm_trig_o   = sm_trig_ff  ;
  assign sm_gate_o   = sm_gate_ff  ;
  assign sm_reset_o  = sm_reset_ff ;
  assign dir_o       = dir_ff      ;
  assign clk_event_o = clk_event_ff;
endmodule