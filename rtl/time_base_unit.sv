module time_base_unit # (parameter CNT_WIDTH = 32,
                         parameter ARR_WIDTH = 32,
                         parameter PSC_WIDTH = 16) (
  input  logic                   clk_i      ,   // Тактовый сигнал
  input  logic                   aresetn_i  ,   // Асинхронный сброс
  input  logic [CNT_WIDTH - 1:0] cnt_i      ,   // Значение счетчика из регистра TIM_CNT
  input  logic                   cen_i      ,   // Сигнал активации счетчика
  input  logic [ARR_WIDTH - 1:0] arr_i      ,   // Значение ARR из регистра TIM_ARR
  input  logic [PSC_WIDTH - 1:0] psc_i      ,   // Значение PSC из регистр TIM_PSC
  input  logic                   dir_i      ,   // Направление счета
  input  logic                   sm_reset_i ,   // Сброса счетчика из Slave Mode Controller
  input  logic                   sm_gate_i  ,   // Строббирование сигнала из Slave Mode Controller
  input  logic                   sm_trig_i  ,   // Запуск счетчика из Slave Mode Controller
  input  logic                   apre_i     ,   // Активация предзагрузки регистра TIM_ARR
  input  logic [1:0]             cms_i      ,   // Выбор режима счета вверх/вниз
  input  logic                   udis_i     ,   // Запрет на генерацию Update Event (UEV)
  input  logic                   ug_i       ,   // Программное выставление сигнала UEV
  input  logic                   opm_i      ,   // Остановка после генерации UEV (Генерация строба)

  output logic                   uif_o     ,
  output logic                   tif_o     ,
  output logic                   cnt_en_o  ,
  output logic                   uev_o     ,
  output logic [CNT_WIDTH - 1:0] cnt_o
);

  logic [CNT_WIDTH - 1:0] cnt_ff            ;
  logic [CNT_WIDTH - 1:0] cnt_next          ;
  logic [ARR_WIDTH - 1:0] arr_shadow_reg    ;
  logic [ARR_WIDTH - 1:0] arr_compare_reg   ;
  logic [PSC_WIDTH - 1:0] psc_shadow_reg    ;
  logic                   enable_preload_arr;
  logic                   overflow          ;
  logic                   underflow         ;
  logic                   cnt_en_ff         ;

  enum logic [2:0] {
    IDLE     = 3'b000,
    STOP     = 3'b001,
    CNT_UP   = 3'b010,
    CNT_DOWN = 3'b011,
    RESET    = 3'b100
  } state;

  state state_ff;
  state next;

  always_ff @(posedge clk_i)
    enable_preload_arr <= apre_i;

  always_ff @(posedge clk_i)
    if (state_ff == CNT_UP || CNT_DOWN)
      cnt_en_ff <= cen_i;

// Preload ARR

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      arr_shadow_reg <= {ARR_WIDTH{1'b0}};
    else if ((~dir_i  && (cnt_ff == (arr_shadow_reg - 'b1)) && ~udis_i) || (dir_i && (cnt_ff == ({CNT_WIDTH{1'b0}} + 'b1)) && ~udis_i))
      arr_shadow_reg <= arr_i;

// Preload PSC
  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      psc_shadow_reg <= {PSC_WIDTH{1'b0}};
    else if ((~dir_i  && (cnt_ff == (arr_shadow_reg - 'b1)) && ~udis_i) || (dir_i && (cnt_ff == ({CNT_WIDTH{1'b0}} + 'b1)) && ~udis_i))
      psc_shadow_reg <= psc_i;

// UEV logic
  always_ff @(posedge clk_i)
    if (ug_i)
      uev_o <= 1'b1;
    else if (~dir_i  && (cnt_ff == arr_shadow_reg  ) && ~udis_i)
      uev_o <= 1'b1;
    else if (dir_i && (cnt_ff == {CNT_WIDTH{1'b0}}) && ~udis_i)
      uev_o <= 1'b1;
    else
      uev_o <= 1'b0;

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      state_ff <= IDLE;
    else
      state_ff <= next;

  always_comb begin
    next = state_ff;
    case (state_ff)
      IDLE    : if      (cen_i && ~dir_i)                next = CNT_UP  ;
                else if (cen_i && dir_I)                 next = CNT_DOWN;

      CNT_UP  : if      (sm_reset_i || overflow)         next = RESET   ;
                else if (~cen_i)                         next = STOP    ;
                else if (cms != 2'b00 && overflow)       next = CNT_DOWN;                  

      CNT_DOWN: if      (sm_reset_i || underflow)        next = RESET   ;
                else if (~cen_i)                         next = STOP    ;
                else if (cms != 2'b00 && underflow)      next = CNT_UP  ;

      RESET   : if      (dir_i)                          next = CNT_DOWN;
                else if (~dir_i)                         next = CNT_UP  ;

      STOP    : if      ((sm_trig_i || cen_i) && dir_i)  next = CNT_DOWN;
                else if ((sm_trig_i || cen_i) && ~dir_i) next = CNT_UP  ;
    endcase
  end

// General counter logic
  always_ff @(posedge clk_i) begin
    if (cnt_ff_en) begin
      case (state_ff)
        IDLE    : cnt_ff <= {CNT_WIDTH{1'b0}};
        CNT_UP  : cnt_ff <= cnt_ff + 'b1;
        CNT_DOWN: cnt_ff <= cnt_ff - 'b1;
        RESET   : cnt_ff <= dir_i ? arr_i : {CNT_WIDTH{1'b0}};
        default : cnt_ff <= cnt_ff;
      endcase
    end
    else begin
      case (state_ff)
        IDLE    : cnt_ff <= {CNT_WIDTH{1'b0}};
        CNT_UP  : cnt_ff <= {CNT_WIDTH{1'b0}};
        CNT_DOWN: cnt_ff <= cnt_i;
        default : cnt_ff <= cnt_ff;
      endcase
    end
  end

  assign overflow  = cnt_ff == arr_shadow_reg;
  assign underflow = cnt_ff == 1'b0          ;

  assign uif_o     = (overflow || underflow) & udis_i;
  assign tif_o     = (state_ff == STOP && sm_trig_i) ;
    
endmodule