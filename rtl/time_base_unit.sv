module time_base_unit # (parameter CNT_WIDTH = 32,
                        parameter ARR_WIDTH = 32,
                        parameter PSC_WIDTH = 16) (
  input  logic                   clk_i      ,   // Тактовый сигнал
  input  logic                   rstn_i     ,   // Cинхронный сброс
  input  logic [CNT_WIDTH - 1:0] cnt_i      ,   // Значение счетчика из регистра TIM_CNT
  input  logic                   cen_i      ,   // Сигнал активации счетчика
  input  logic                   clk_event_i,   // Событие для счета
  input  logic [ARR_WIDTH - 1:0] arr_i      ,   // Значение ARR из регистра TIM_ARR
  input  logic [PSC_WIDTH - 1:0] psc_i      ,   // Значение PSC из регистр TIM_PSC
  input  logic                   dir_i      ,   // Направление счета
  input  logic                   sm_reset_i ,   // Сброса счетчика из Slave Mode Controller
  input  logic                   sm_gate_i  ,   // Строббирование сигнала из Slave Mode Controller
  input  logic                   sm_trig_i  ,   // Запуск счетчика из Slave Mode Controller
  input  logic                   apre_i     ,   // Активация предзагрузки регистра TIM_ARR
  input  logic [1:0]             cms_i      ,   // Выбор режима счета вверх/вниз
  input  logic [2:0]             sms_i      ,      
  input  logic                   udis_i     ,   // Запрет на генерацию Update Event (UEV)
  input  logic                   ug_i       ,   // Программное выставление сигнала UEV
  input  logic                   opm_i      ,   // Остановка после генерации UEV (Генерация строба)

  output logic                   uif_o     ,
  output logic                   tif_o     ,
  output logic                   cnt_en_o  ,
  output logic                   uev_o     ,
  output logic [CNT_WIDTH - 1:0] cnt_o
);

  logic [CNT_WIDTH - 1:0] cnt_ff        ;
  logic [ARR_WIDTH - 1:0] arr_shadow_reg;
  logic [PSC_WIDTH - 1:0] psc_shadow_reg;
  logic                   overflow      ;
  logic                   underflow     ;
  logic                   cnt_en_ff     ;
  logic                   rise_edge_ug  ;
  logic                   rise_edge_gate;
  logic                   fall_edge_gate;
  logic                   event_enable  ;
  logic                   total_event   ;

  logic                   sync_reset    ;
  logic                   sync_trig     ;
  logic                   sync_gate     ;
  logic                   sync_event    ;

  assign event_enable = (sms_i == 3'b111);

  edge_detector i_edge_ug
  (
    .clk_i      (clk_i       ),
    .rstn_i     (rstn_i      ),
    .a_i        (ug_i        ),
    .edge_rise_o(rise_edge_ug),
    .edge_fall_o(            )
  );

  edge_detector i_edge_gate
  (
    .clk_i      (clk_i         ),
    .rstn_i     (rstn_i        ),
    .a_i        (sync_gate     ),
    .edge_rise_o(rise_edge_gate),
    .edge_fall_o(fall_edge_gate)
  );

  sync_cell i_sync_reset
  (
    .clk_i(clk_i     ),
    .a_i  (sm_reset_i),
    .a_o  (sync_reset)
  );

  sync_cell i_sync_trig
  (
    .clk_i(clk_i    ),
    .a_i  (sm_trig_i),
    .a_o  (sync_trig)
  );

  sync_cell i_sync_gate
  (
    .clk_i(clk_i    ),
    .a_i  (sm_gate_i),
    .a_o  (sync_gate)
  );

  sync_cell i_sync_clk_event
  (
    .clk_i(clk_i      ),
    .a_i  (clk_event_i),
    .a_o  (sync_event )
  );

  enum logic [2:0] {
    IDLE            = 3'b000,
    STOP            = 3'b001,
    CNT_UP          = 3'b010,
    CNT_DOWN        = 3'b011,
    RESET_THEN_DOWN = 3'b100,
    RESET_THEN_UP   = 3'b101
  } state_ff, next;

  always_ff @(posedge clk_i)
    if (~rstn_i)
      cnt_en_ff <= 1'b0;
    else if (cen_i)
      cnt_en_ff <= 1'b1;
    else if (sync_trig)
      cnt_en_ff <= 1'b1;
    else if (~cen_i)
      cnt_en_ff <= 1'b0;

// Preload ARR

  always_ff @(posedge clk_i)
    if (~rstn_i)
      arr_shadow_reg <= {ARR_WIDTH{1'b0}};
    else if (uev_o && apre_i)
      arr_shadow_reg <= arr_i;

// Preload PSC
  always_ff @(posedge clk_i)
    if (~rstn_i)
      psc_shadow_reg <= {PSC_WIDTH{1'b0}};
    else if (uev_o)
      psc_shadow_reg <= psc_i;

// UEV logic
  assign uev_o = overflow || underflow || rise_edge_ug || sm_reset_i;

  always_ff @(posedge clk_i)
    if (~rstn_i) 
      state_ff <= IDLE;
    else
      state_ff <= next;


  always_comb begin
    next = state_ff;
    case (state_ff)
      IDLE    : if      (cen_i && ~dir_i)                             next = CNT_UP         ;
                else if (cen_i && dir_i)                              next = CNT_DOWN       ;

      CNT_UP  : if      (sync_reset || (overflow && cms_i == 2'b00))  next = RESET_THEN_UP  ;
                else if (~cen_i)                                      next = STOP           ;
                else if (cms_i != 2'b00 && overflow)                  next = RESET_THEN_DOWN;   
                else if (cms_i == 2'b00 && dir_i)                     next = CNT_DOWN       ;       

      CNT_DOWN: if      (sync_reset || (underflow && cms_i == 2'b00)) next = RESET_THEN_DOWN;
                else if (~cen_i)                                      next = STOP           ;
                else if (cms_i != 2'b00 && underflow)                 next = RESET_THEN_UP  ;
                else if (cms_i == 2'b00 && ~dir_i)                    next = CNT_UP         ;
                
      RESET_THEN_UP  :                                                next = CNT_UP         ;
      RESET_THEN_DOWN:                                                next = CNT_DOWN       ;

      STOP    : if      ((sync_trig || cen_i) && dir_i)               next = CNT_DOWN       ;
                else if ((sync_trig || cen_i) && ~dir_i)              next = CNT_UP         ;
    endcase
  end

// General counter logic
  always_ff @(posedge clk_i) begin
    if (cnt_en_ff) begin
      if (event_enable) begin
        case (state_ff)
          IDLE           :                  cnt_ff <= {CNT_WIDTH{1'b0}};
          CNT_UP         : if (sync_event)  cnt_ff <= cnt_ff + 'b1;
          CNT_DOWN       : if (sync_event)  cnt_ff <= cnt_ff - 'b1;
          RESET_THEN_UP  :                  cnt_ff <= {CNT_WIDTH{1'b0}};
          RESET_THEN_DOWN:                  cnt_ff <= arr_i;
          default        :                  cnt_ff <= cnt_ff;
        endcase
      end
      else begin
        case (state_ff)
          IDLE           : cnt_ff <= {CNT_WIDTH{1'b0}};
          CNT_UP         : cnt_ff <= cnt_ff + 'b1     ;
          CNT_DOWN       : cnt_ff <= cnt_ff - 'b1     ;
          RESET_THEN_UP  : cnt_ff <= {CNT_WIDTH{1'b0}};
          RESET_THEN_DOWN: cnt_ff <= arr_i            ;
          default        : cnt_ff <= cnt_ff           ;
        endcase
      end
    end
    else begin
      case (state_ff)
        IDLE    : cnt_ff <= {CNT_WIDTH{1'b0}};
        default : cnt_ff <= cnt_ff           ;
      endcase
    end
  end

  assign overflow  = (cnt_ff   == arr_shadow_reg && state_ff == CNT_UP   && arr_shadow_reg != 'b0);
  assign underflow = (cnt_ff   == 1'b0           && state_ff == CNT_DOWN)               ;

  assign cnt_o     = cnt_ff                                                             ;
  assign uif_o     = (overflow || underflow) & ~udis_i || rise_edge_ug                  ;
  assign tif_o     = (state_ff == STOP && sync_trig) || rise_edge_gate || fall_edge_gate;
  
  assign cnt_en_o = (sync_trig || cen_i || (state_ff == STOP) && fall_edge_gate) && ~sync_gate;

endmodule