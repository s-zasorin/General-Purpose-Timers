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

  axi4lite_intf.slave axil ();

  gpt_top DUT 
  (
    .aclk_i(aclk   ),
    .rst_i (aresetn),
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
    ch_i <= 1'b1;
    repeat (2) #2;
    ch_i <= 1'b0;
    repeat (3) #1;
    ch_i <= 1'b1;
    repeat (10) begin
      ch_i <= ~ch_i;
      repeat($urandom_range(3, 10)) #1;
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
    axil.WDATA   <= data;
    axil.WSTRB   <= strb;
    axil.WVALID  <= 1'b1;
    axil.BREADY  <= 1'b1;
    
    // Wait for address accepted
    wait(axil.awready);
    @(axil);
    axil.AWVALID <= 1'b0;
    axil.AWADDR  <= '0;
    
    // Wait for data accepted
    wait(axil.wready);
    @(axil);
    axil.WVALID <= 1'b0;
    axil.WDATA  <= '0;
    axil.WSTRB  <= '0;
    
    // Wait for write response
    wait(axil.bvalid);
    response = axil.BRESP;
    @(axil);
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
    axil.RREADY  <= 1'b1;
    
    // Wait for address accepted
    wait(axil.ARREADY);
    @(axil);
    axil.ARVALID <= 1'b0;
    axil.ARADDR  <= '0;
    
    // Wait for read data
    wait(axil.rvalid);
    data = axil.RDATA;
    response = axil.RRESP;
    @(axil);
    axil.RREADY <= 1'b0;
    
    $display("[AXI-LITE READ] Address: 0x%08h, Data: 0x%08h, Response: 0x%h", addr, data, response);
    
endtask

  initial begin
    rst = 1'b1;
    @(posedge aclk);
    rst     = 1'b0;
    itr_i   = 4'b0010;
    etr_i   = 1'b0;
    axi_lite_write(.addr('h0), .data({32{1'b1}}), .strb(4'b0001));
    gen_ch();
    
  end

endmodule