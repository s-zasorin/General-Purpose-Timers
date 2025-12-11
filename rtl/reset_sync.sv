module reset_sync (
  input  logic clk_i,
  input  logic aresetn_i,
  output logic rstn_o
);

  logic [1:0] rst_ff;

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      rstn_ff <= 2'b0;
    else begin
      rstn_ff[0] <= 1'b1;
      rstn_ff[1] <= rstn_ff[0];
    end

  assign rstn_o = rstn_ff[1];

endmodule