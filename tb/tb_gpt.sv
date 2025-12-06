module tb_gpt();

  localparam  CH_PAIRS_NUM = 2;

  logic                          aclk   ;
  logic                          aresetn    ;
  logic [3:0]                    itr_i  ;
  logic                          etr_i  ;
  logic [2 * CH_PAIRS_NUM - 1:0] ch_i   ;
  logic                          trg_o  ;
  logic [2 * CH_PAIRS_NUM - 1:0] ch_o   ;


  CSR_GPT_pkg::CSR_GPT__in_t  gpt_hwif_in;

  axi4lite_intf #(
  .ADDR_WIDTH(32),
  .DATA_WIDTH(32),
  .RESP_WIDTH(1)
) axil () ;

  gpt_top DUT 
  (
    .aclk_i   (aclk   ),
    .aresetn_i(aresetn),
    .itr_i    (itr_i  ),
    .etr_i    (etr_i  ),
    .ch_i     (ch_i   ),
    .trg_o    (trg_o  ),
    .ch_o     (ch_o   ),
    .s_axil   (axil   )
  );

  initial begin
    aclk   <= 1'b0;
    forever begin
      #5;
      aclk <= ~aclk;
    end
  end
  
  task gen_ch1();
    repeat (100) begin
      ch_i[0] <= 1'b1;
      repeat ($urandom_range(1, 5)) @(posedge aclk);
      ch_i[0] <= 1'b0;
      repeat ($urandom_range(1, 5)) @(posedge aclk);
      ch_i[0] <= 1'b1;
      repeat ($urandom_range(1, 5)) begin
        ch_i[0] <= ~ch_i[0];
        repeat($urandom_range(1, 5)) @(posedge aclk);
      end
    end
  endtask

  task gen_ch2();
    repeat (100) begin
      ch_i[1] <= 1'b1;
      repeat ($urandom_range(1, 10)) @(posedge aclk);
      ch_i[1] <= 1'b0;
      repeat ($urandom_range(1, 10)) @(posedge aclk);
      ch_i[1] <= 1'b1;
      repeat ($urandom_range(1, 10)) begin
        ch_i[1] <= ~ch_i[1];
        repeat($urandom_range(1, 10)) @(posedge aclk);
      end
    end
  endtask

task automatic axi_lite_write(
    input  [31:0] addr,
    input  [31:0] data,
    input  [3:0]  strb = 4'b1111,  // По умолчанию все байты
    output [1:0]  response
);
    
    // Phase 1: Write Address Channel
    axil.AWADDR  <= addr;
    axil.AWVALID <= 1'b1;
    
    do begin
      @(posedge aclk);
    end
    while(!axil.AWREADY);
    axil.AWVALID <= 1'b0;
    axil.AWADDR  <= '0;


    @(posedge aclk);
    axil.WDATA   <= data;
    axil.WSTRB   <= strb;
    axil.WVALID  <= 1'b1;
    axil.BREADY  <= 1'b1;

    do begin
      @(posedge aclk);
    end
    while(!axil.WREADY);
    axil.WVALID <= 1'b0;
    axil.WDATA  <= '0;
    axil.WSTRB  <= '0;
    
    do begin
      @(posedge aclk);
    end
    while(!axil.BVALID);
    response = axil.BRESP;
    axil.BREADY <= 1'b0;
    
    $display("[AXI-LITE WRITE] Address: 0x%08h, Data: 0x%08h, Response: 0x%h", addr, data, response);
    
endtask

task automatic axi_lite_read(
    input [31:0] addr,
    output [31:0] data,
    output [1:0] response
);
    
    // Phase 1: Read Address Channel
    axil.ARADDR  <= addr;
    axil.ARVALID <= 1'b1;

    do begin
      @(posedge aclk);
    end    
    while(!axil.ARREADY);
    axil.ARVALID <= 1'b0;
    axil.ARADDR  <= '0;

    @(posedge aclk);

    axil.RREADY  <= 1'b1;
    do begin
      @(posedge aclk);
    end    
    while(!axil.RVALID);
    data = axil.RDATA;
    response = axil.RRESP;
    axil.RREADY <= 1'b0;
    
    $display("[AXI-LITE READ] Address: 0x%08h, Data: 0x%08h, Response: 0x%h", addr, data, response);
    
endtask

task up_count_mode();
  // Запись в TIM_CR1
  axi_lite_write(.addr('h0), .data(32'b10000001), .strb(4'b1111));  // CEN = 1, DIR = 0, CMS = 00, APRE = 1 - Простой счет вверх. Предзагрузка для ARR
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b0), .strb(4'b1111));         // SMS = 0 - тактирование от внутреннего Clock
  // Запись в PSC
  axi_lite_write(.addr('h20), .data(32'd1), .strb(4'b1111));        // PSC = 0x1 - Clock для счетчика = CLK_INT / 2
  // Запись в TIM_ARR
  axi_lite_write(.addr('h24), .data(32'd40), .strb(4'b1111));       // ARR = 40 - Значение автоматической перезагрузки
  // Запись в EGR
  axi_lite_write(.addr('h18), .data(32'd1), .strb(4'b1111));        // UG = 1 - Генерация обновления теневых регистров

endtask

task down_count_mode();
  // Запись в PSC
  axi_lite_write(.addr('h20), .data(32'd4), .strb(4'b1111));        // PSC = 0x1 - Clock для счетчика = CLK_INT / 2
  // Запись в TIM_ARR
  axi_lite_write(.addr('h24), .data(32'd20), .strb(4'b1111));       // ARR = 20 - Значение автоматической перезагрузки
  // Запись в TIM_CR1
  axi_lite_write(.addr('h0), .data(32'b10010001), .strb(4'b1111));  // CEN = 1, DIR = 0, CMS = 00 - Простой счет вверх
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b0), .strb(4'b1111));         // SMS = 0 - тактирование от внутреннего Clock
endtask

task stop_counter();
  axi_lite_write(.addr('h0), .data(32'b0), .strb(4'b1111));         // CEN = 0
endtask

task trigger_mode();
  // Запись в CCMR1
  axi_lite_write(.addr('h38), .data(32'b01000001), .strb(4'b1111));    // IC1F = 0100, CC1S = 01 - Режим входа
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b1010110), .strb(4'b1111));      // TS = 101 - источник упраляющего импульса TI1, SMS = 110 - Триггерный режим
  // Запись в CCER
  axi_lite_write(.addr('h14), .data(32'b0), .strb(4'b1111));
  repeat (4) @(posedge aclk);
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b0), .strb(4'b1111));            // Отключение режима триггера
endtask

task reset_mode();
  // Запись в CCMR1
  axi_lite_write(.addr('h38), .data(32'b01010001), .strb(4'b1111));    // IC1F = 0100, CC1S = 01 - Режим входа
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b1010100), .strb(4'b1111));      // TS = 101 - источник упраляющего импульса TI1, SMS = 100 - Режим сброса
  // Запись в CCER
  axi_lite_write(.addr('h14), .data(32'b0), .strb(4'b1111));
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b0), .strb(4'b1111));            // Отключение режима сброса
endtask

task gate_mode();
  // Запись в CCMR1
  axi_lite_write(.addr('h38), .data(32'b00000001), .strb(4'b1111));    // IC1F = 0000, CC1S = 01 - Режим входа
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b1010101), .strb(4'b1111));      // TS = 101 - источник упраляющего импульса TI1, SMS = 100 - Режим сброса
  // Запись в CCER
  axi_lite_write(.addr('h14), .data(32'b0), .strb(4'b1111));
endtask

task output_pwm_mode();
  // Запись в CCR1
  axi_lite_write(.addr('h28), .data(32'b0000011), .strb(4'b1111)); // CCR1 = 3
  // Запись в EGR - Загрузка значений в теневые регистры
  axi_lite_write(.addr('h18), .data(32'd1), .strb(4'b1111));        // UG = 1 - Генерация обновления теневых регистров
  // Запись в CCMR1
  axi_lite_write(.addr('h38), .data(32'b01101000), .strb(4'b1111));    // CC1S = 00 - Режим выхода, OC1M = 110 - Режим ШИМ №1, OC1PE = 1 - Предзагрузка CCR1
  // Запись в CCER - Активация выхода
  axi_lite_write(.addr('h14), .data(32'b01), .strb(4'b1111)); // CC1E - Выход активирован, CC1PE = 1 - положительная полярность
endtask

task one_pulse_mode();

endtask

task up_down_cnt();
endtask

task input_capture_mode();
  // Запись в CCMR1
  axi_lite_write(.addr('h38), .data(32'b01100001), .strb(4'b1111));    // CC1S = 01 - Режим входа, IC1F = 0110, IC1PS = 00 - нет прескалера
  // Запись в CCER - Активация выхода
  axi_lite_write(.addr('h14), .data(32'b01), .strb(4'b1111)); // CC1E - Выход активирован, CC1PE = 1 - положительная полярность
  // Запись в TIM_DIER
  axi_lite_write(.addr('hC), .data(32'b01000000010), .strb(4'b1111));
endtask

// Для входного режима ШИМ необходимо настроить минимум 2 канала. Например TI1 и TI2
task input_pwm_mode();
endtask

  initial gen_ch1();
  initial gen_ch2();

  initial begin
    aresetn = 1'b0;
    @(posedge aclk);
    aresetn = 1'b1;
    itr_i   = 4'b0010;
    etr_i   = 1'b0;
    @(posedge aclk);
    @(posedge aclk);
    up_count_mode();
    repeat (30) @(posedge aclk);

    down_count_mode();
    repeat (15) @(posedge aclk);
  
    stop_counter();
    @(posedge aclk);

    trigger_mode();
    repeat (23) @(posedge aclk);

    reset_mode();
    repeat (15) @(posedge aclk);
  
    gate_mode();
    repeat (30) @(posedge aclk);

    reset_mode();
    output_pwm_mode();
    repeat (400) @(posedge aclk);
    input_capture_mode();
    repeat (100) @(posedge aclk);
    $finish();
  end

endmodule
