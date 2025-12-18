module tb_cascade_timers();

  localparam  CH_PAIRS_NUM = 2;

  logic                          aclk      ;
  logic                          aresetn   ;

  logic [3:0]                    tim1_itr_i;
  logic                          tim1_etr_i;
  logic [2 * CH_PAIRS_NUM - 1:0] tim1_ch_i ;
  logic                          tim1_trg_o;
  logic [2 * CH_PAIRS_NUM - 1:0] tim1_ch_o ;

  logic [3:0]                    tim2_itr_i;
  logic                          tim2_etr_i;
  logic [2 * CH_PAIRS_NUM - 1:0] tim2_ch_i ;
  logic                          tim2_trg_o;
  logic [2 * CH_PAIRS_NUM - 1:0] tim2_ch_o ;

  axi4lite_intf #(
  .ADDR_WIDTH(32),
  .DATA_WIDTH(32),
  .RESP_WIDTH(1)
  ) axil1 () ;

  axi4lite_intf #(
  .ADDR_WIDTH(32),
  .DATA_WIDTH(32),
  .RESP_WIDTH(1)
  ) axil2 () ;

  gpt_top i_tim1 
  (
    .aclk_i   (aclk      ),
    .aresetn_i(aresetn   ),
    .itr_i    (tim1_itr_i),
    .etr_i    (tim1_etr_i),
    .ch_i     (tim1_ch_i ),
    .trg_o    (tim1_trg_o),
    .ch_o     (tim1_ch_o ),
    .s_axil   (axil1     )
  );

  gpt_top i_tim2 
  (
    .aclk_i   (aclk      ),
    .aresetn_i(aresetn   ),
    .itr_i    (tim2_itr_i),
    .etr_i    (tim2_etr_i),
    .ch_i     (tim2_ch_i ),
    .trg_o    (tim2_trg_o),
    .ch_o     (tim2_ch_o ),
    .s_axil   (axil2     )
  );

  initial begin
    aclk   <= 1'b0;
    forever begin
      #5;
      aclk <= ~aclk;
    end
  end

  task automatic axi_lite_write_tim1(
      input  [31:0] addr,
      input  [31:0] data,
      input  [3:0]  strb = 4'b1111,  // По умолчанию все байты
      output [1:0]  response
  );
      
      // Phase 1: Write Address Channel
      axil1.AWADDR  <= addr;
      axil1.AWVALID <= 1'b1;
      
      do begin
        @(posedge aclk);
      end
      while(!axil1.AWREADY);
      axil1.AWVALID <= 1'b0;
      axil1.AWADDR  <= '0;
  
  
      @(posedge aclk);
      axil1.WDATA   <= data;
      axil1.WSTRB   <= strb;
      axil1.WVALID  <= 1'b1;
      axil1.BREADY  <= 1'b1;
  
      do begin
        @(posedge aclk);
      end
      while(!axil1.WREADY);
      axil1.WVALID <= 1'b0;
      axil1.WDATA  <= '0;
      axil1.WSTRB  <= '0;
      
      do begin
        @(posedge aclk);
      end
      while(!axil1.BVALID);
      response = axil1.BRESP;
      axil1.BREADY <= 1'b0;
      
      $display("[AXI-LITE WRITE] Address: 0x%08h, Data: 0x%08h, Response: 0x%h", addr, data, response);
      
  endtask

task automatic axi_lite_write_tim2(
      input  [31:0] addr,
      input  [31:0] data,
      input  [3:0]  strb = 4'b1111,  // По умолчанию все байты
      output [1:0]  response
  );
      
      // Phase 1: Write Address Channel
      axil2.AWADDR  <= addr;
      axil2.AWVALID <= 1'b1;
      
      do begin
        @(posedge aclk);
      end
      while(!axil2.AWREADY);
      axil2.AWVALID <= 1'b0;
      axil2.AWADDR  <= '0;
  
  
      @(posedge aclk);
      axil2.WDATA   <= data;
      axil2.WSTRB   <= strb;
      axil2.WVALID  <= 1'b1;
      axil2.BREADY  <= 1'b1;
  
      do begin
        @(posedge aclk);
      end
      while(!axil2.WREADY);
      axil2.WVALID <= 1'b0;
      axil2.WDATA  <= '0;
      axil2.WSTRB  <= '0;
      
      do begin
        @(posedge aclk);
      end
      while(!axil2.BVALID);
      response = axil2.BRESP;
      axil2.BREADY <= 1'b0;
      
      $display("[AXI-LITE WRITE] Address: 0x%08h, Data: 0x%08h, Response: 0x%h", addr, data, response);
      
  endtask

  task automatic axi_lite_read(
      input [31:0] addr,
      output [31:0] data,
      output [1:0] response
  );

      // Phase 1: Read Address Channel
      axil1.ARADDR  <= addr;
      axil1.ARVALID <= 1'b1;

      do begin
        @(posedge aclk);
      end    
      while(!axil1.ARREADY);
      axil1.ARVALID <= 1'b0;
      axil1.ARADDR  <= '0;

      @(posedge aclk);

      axil1.RREADY  <= 1'b1;
      do begin
        @(posedge aclk);
      end    
      while(!axil1.RVALID);
      data = axil1.RDATA;
      response = axil1.RRESP;
      axil1.RREADY <= 1'b0;

      $display("[AXI-LITE READ] Address: 0x%08h, Data: 0x%08h, Response: 0x%h", addr, data, response);

  endtask

  task tim1_gen_ch1();
    repeat (100) begin
      tim1_ch_i[0] <= 1'b1;
      repeat ($urandom_range(1, 5)) @(posedge aclk);
      tim1_ch_i[0] <= 1'b0;
      repeat ($urandom_range(1, 5)) @(posedge aclk);
      tim1_ch_i[0] <= 1'b1;
      repeat ($urandom_range(1, 5)) begin
        tim1_ch_i[0] <= ~tim1_ch_i[0];
        repeat($urandom_range(1, 5)) @(posedge aclk);
      end
    end
  endtask

  task tim1_gen_ch2();
    repeat (100) begin
      tim1_ch_i[1] <= 1'b1;
      repeat ($urandom_range(1, 10)) @(posedge aclk);
      tim1_ch_i[1] <= 1'b0;
      repeat ($urandom_range(1, 10)) @(posedge aclk);
      tim1_ch_i[1] <= 1'b1;
      repeat ($urandom_range(1, 10)) begin
        tim1_ch_i[1] <= ~tim1_ch_i[1];
        repeat($urandom_range(1, 10)) @(posedge aclk);
      end
    end
  endtask

  task tim2_gen_ch1();
    repeat (100) begin
      tim2_ch_i[0] <= 1'b1;
      repeat ($urandom_range(1, 5)) @(posedge aclk);
      tim2_ch_i[0] <= 1'b0;
      repeat ($urandom_range(1, 5)) @(posedge aclk);
      tim2_ch_i[0] <= 1'b1;
      repeat ($urandom_range(1, 5)) begin
        tim2_ch_i[0] <= ~tim2_ch_i[0];
        repeat($urandom_range(1, 5)) @(posedge aclk);
      end
    end
  endtask

  task tim2_gen_ch2();
    repeat (100) begin
      tim2_ch_i[1] <= 1'b1;
      repeat ($urandom_range(1, 10)) @(posedge aclk);
      tim2_ch_i[1] <= 1'b0;
      repeat ($urandom_range(1, 10)) @(posedge aclk);
      tim2_ch_i[1] <= 1'b1;
      repeat ($urandom_range(1, 10)) begin
        tim2_ch_i[1] <= ~tim2_ch_i[1];
        repeat($urandom_range(1, 10)) @(posedge aclk);
      end
    end
  endtask

  assign tim2_itr_i[0] = tim1_trg_o;

  task slave_mode_tim2();
    // Запись в SMCR
    axi_lite_write_tim2(.addr('h8), .data(32'b0000111), .strb(4'b1111));   // SMS = 111 — Режим внешнего тактирования №1
    // Запись в TIM_CR1
    axi_lite_write_tim2(.addr('h0), .data(32'b10000001), .strb(4'b1111));  // CEN = 0, DIR = 0, CMS = 00, APRE = 1 - Простой счет вверх. Предзагрузка для ARR
    // Запись в TIM_CR2
    axi_lite_write_tim2(.addr('h4), .data(32'd1), .strb(4'b1111));         // COPY = 1 - Обновление ACTIVE множество регистров
    // Запись в TIM_CR2
    axi_lite_write_tim2(.addr('h4), .data(32'd0), .strb(4'b1111));         // COPY = 0 - Обновление ACTIVE множество регистров
  endtask

  task prescaler_for_another_tim1_master();
    // Запись в SMCR
    axi_lite_write_tim1(.addr('h8), .data(32'b0), .strb(4'b1111));         // SMS = 0 - тактирование от внутреннего Clock
    // Запись в TIM_CR1
    axi_lite_write_tim1(.addr('h0), .data(32'b10000001), .strb(4'b1111));  // CEN = 0, DIR = 0, CMS = 00, APRE = 1 - Простой счет вверх. Предзагрузка для ARR
    // Запись в PSC
    axi_lite_write_tim1(.addr('h20), .data(32'd1), .strb(4'b1111));        // PSC = 0x1 - Clock для счетчика = CLK_INT / 2
    // Запись в TIM_ARR
    axi_lite_write_tim1(.addr('h24), .data(32'd40), .strb(4'b1111));       // ARR = 40 - Значение автоматической перезагрузки
    // Запись в EGR
    axi_lite_write_tim1(.addr('h18), .data(32'd1), .strb(4'b1111));        // UG = 1 - Генерация обновления теневых регистров
    // Запись в TIM_CR2
    axi_lite_write_tim1(.addr('h4), .data(32'd00100001), .strb(4'b1111));  // COPY = 1 - Обновление ACTIVE множество регистров
    // Запись в TIM_CR2
    axi_lite_write_tim1(.addr('h4), .data(32'd00100000), .strb(4'b1111));  // COPY = 0 - Обновление ACTIVE множество регистров
  endtask

  task enable_for_another_tim1_master();

  endtask
  initial begin
    aresetn = 1'b0 ;
    @(posedge aclk);
    aresetn = 1'b1 ;
    @(posedge aclk);
    @(posedge aclk);
    slave_mode_tim2();
    @(posedge aclk);
    prescaler_for_another_tim1_master();
    repeat (10000) @(posedge aclk);
    $finish();
  end
endmodule