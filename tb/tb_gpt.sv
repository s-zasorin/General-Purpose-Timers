module tb_gpt();

  localparam  CH_PAIRS_NUM = 2;

  logic                          aclk   ;
  logic                          rst    ;
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
    .aclk_i(aclk   ),
    .rst_i (rst    ),
    .itr_i (itr_i  ),
    .etr_i (etr_i  ),
    .ch_i  (ch_i   ),
    .trg_o (trg_o  ),
    .ch_o  (ch_o   ),
    .s_axil(axil   )
  );

  initial begin
    aclk   <= 1'b0;
    forever begin
      #5;
      aclk <= ~aclk;
    end
  end
  
  task gen_ch();
    repeat (100) begin
      ch_i[0] <= 1'b1;
      repeat ($urandom_range(1, 10)) @(posedge aclk);
      ch_i[0] <= 1'b0;
      repeat ($urandom_range(1, 10)) @(posedge aclk);
      ch_i[0] <= 1'b1;
      repeat ($urandom_range(1, 10)) begin
        ch_i[0] <= ~ch_i[0];
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
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b0), .strb(4'b1111));         // SMS = 0 - тактирование от внутреннего Clock
  // Запись в PSC
  axi_lite_write(.addr('h20), .data(32'd1), .strb(4'b1111));        // PSC = 0x1 - Clock для счетчика = CLK_INT / 2
  // Запись в TIM_ARR
  axi_lite_write(.addr('h24), .data(32'd40), .strb(4'b1111));       // ARR = 40 - Значение автоматической перезагрузки
  // Запись в EGR
  axi_lite_write(.addr('h18), .data(32'd1), .strb(4'b1111));        // UG = 1 - Генерация обновления теневых регистров
  // Запись в TIM_CR1
  axi_lite_write(.addr('h0), .data(32'b10000001), .strb(4'b1111));  // CEN = 1, DIR = 0, CMS = 00, APRE = 1 - Простой счет вверх. Предзагрузка для ARR
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
  axi_lite_write(.addr('h8), .data(32'b1010110), .strb(4'b1111));      // TS = 101 - источник упраляющего импульса TI1
  // Запись в CCER
  axi_lite_write(.addr('h14), .data(32'b0), .strb(4'b1111));
  // Запись в SMCR
  axi_lite_write(.addr('h8), .data(32'b0), .strb(4'b1111));            // Отключение режима триггера
endtask

task output_pwm_mode();
endtask

task input_pwm_mode();
endtask

  initial gen_ch();

  initial begin
    rst = 1'b1;
    @(posedge aclk);
    @(posedge aclk);
    rst     = 1'b0;
    itr_i   = 4'b0010;
    etr_i   = 1'b0;

    up_count_mode();
    @(posedge aclk);
    down_count_mode();
    repeat (10) @(posedge aclk);
    stop_counter();
    @(posedge aclk);
    trigger_mode();
    repeat (100) @(posedge aclk);
    $finish();
  end

endmodule
