module encoder_mode (
  input  logic clk_i          ,
  input  logic rstn_i         ,
  input  logic default_dir_i  ,
  input  logic ti1fp1_i       ,
  input  logic ti2fp2_i       ,

  output logic new_dir_mode1_o,
  output logic new_dir_mode2_o
);

  logic rise_edge_ti1;
  logic fall_edge_ti1;
  logic rise_edge_ti2;
  logic fall_edge_ti2;

  edge_detector i_edge_ti1
  (
    .clk_i      (clk_i        ),
    .rstn_i     (rstn_i       ),
    .a_i        (ti1fp1_i     ),
    .edge_rise_o(rise_edge_ti1),
    .edge_fall_o(fall_edge_ti1)
  );

  edge_detector i_edge_ti2
  (
    .clk_i      (clk_i        ),
    .rstn_i     (rstn_i       ),
    .a_i        (ti2fp2_i     ),
    .edge_rise_o(rise_edge_ti2),
    .edge_fall_o(fall_edge_ti2)
  );
  
  always_comb begin
    if      (rise_edge_ti1 &&  ti2fp2_i)
      new_dir_mode1_o = 1'b1;
    else if (rise_edge_ti1 && ~ti2fp2_i)
      new_dir_mode1_o = 1'b0;
    else
      new_dir_mode1_o = default_dir_i;
  end

  always_comb begin
    if      (rise_edge_ti2 &&  ti1fp1_i)
      new_dir_mode2_o = 1'b1;
    else if (rise_edge_ti2 && ~ti1fp1_i)
      new_dir_mode2_o = 1'b0;
    else
      new_dir_mode2_o = default_dir_i;
  end
endmodule