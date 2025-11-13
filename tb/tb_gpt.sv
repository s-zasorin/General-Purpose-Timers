module tb_gpt();

  localparam  CH_PAIRS_NUM = 2;

  logic                          aclk   ;
  logic                          aresetn;
  logic [3:0]                    itr_i  ;
  logic                          etr_i  ;
  logic [2 * CH_PAIRS_NUM - 1:0] ch_i   ;
  logic                          trg_o  ;
  logic [2 * CH_PAIRS_NUM - 1:0] ch_o   ;

  CSR_GPT_pkg::CSR_GPT__in_t  gpt_hwif_in;

  gpt_top DUT 
  (
    .aclk_i   (aclk   ),
    .aresetn_i(aresetn),
    .itr_i    (itr_i  ),
    .etr_i    (etr_i  ),
    .ch_i     (ch_i   ),
    .trg_o    (trg_o  ),
    .ch_o     (ch_o   )
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

  initial begin
    aresetn = 1'b0;
    @(posedge aclk);
    aresetn = 1'b1;
    itr_i   = 4'b0010;
    etr_i   = 1'b0;
    gen_ch();
    
  end

endmodule