module output_control (
  input  logic       clk_i              ,
  input  logic       aresetn_i          ,
  input  logic       cnt_equal_ccr_i    ,
  input  logic       dir_i              ,
  input  logic       cnt_less_than_ccr_i,
  input  logic       cnt_more_than_ccr_i,
  input  logic [2:0] ocm_i              ,

  output logic       oc_ref_o
);

  logic oc_ref_ff;

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      oc_ref_ff <= 1'b0;
    else
      oc_ref_ff <= oc_ref_o;

  always_comb begin
    case (ocm_i)
      3'b000: oc_ref_o = oc_ref_ff;
      3'b001: oc_ref_o = cnt_equal_ccr_i ? 1'b1 : 1'b0;
      3'b010: oc_ref_o = cnt_equal_ccr_i ? 1'b0 : 1'b1;
      3'b011: oc_ref_o = cnt_equal_ccr_i ? ~oc_ref_ff : oc_ref_ff;
      3'b100: oc_ref_o = 1'b0;
      3'b101: oc_ref_o = 1'b1;
      3'b110: oc_ref_o = dir_i ? (cnt_more_than_ccr_i ? 1'b0 : 1'b1) : (cnt_less_than_ccr_i ? 1'b1 : 1'b0);
      3'b111: oc_ref_o = dir_i ? (cnt_more_than_ccr_i ? 1'b1 : 1'b0) : (cnt_less_than_ccr_i ? 1'b0 : 1'b1);
    endcase
  end
endmodule