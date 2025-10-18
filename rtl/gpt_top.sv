module gpt_top 
#(parameter CH_PAIRS_NUM = 2,
  parameter CNT_WIDTH    = 32,
  parameter PSC_WIDTH    = 32,
  parameter CSR_WIDTH    = 32,
  parameter WSTRB_WIDTH  = CSR_WIDTH / 8) 
(
  input  logic                      aclk_i,
  input  logic                      aresetn_i,

  input  logic                      etr_i,
  input  logic [CH_PAIRS_NUM - 1:0] ch_i ,
  output logic                      trg_o,
  output logic [CH_PAIRS_NUM - 1:0] ch_o ,
);

logic [2 * CH_PAIRS_NUM - 1:0] internal_triggers;
logic                          trigger          ;
logic                          ti1f_ed          ;
logic                          trc              ;
logic                          itr              ;
logic                          etrf             ;
logic                          etrp             ;

trigger_controller trig_inst 
(
  .clk_i   (aclk_i           ),
  .itr_i   (internal_triggers),
  .ti1_ed_i(ti1f_ed          )
);

time_base_unit time_base_inst
(

);

generate
  for (genvar i = 0; i < CH_PAIRS_NUM; i++) begin : g_tim_ch
    tim_channel channel_inst
    (

    );
  end
endgenerate
endmodule