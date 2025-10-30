module edge_detector (
  input  logic a_i,

  output logic edge_rise_o,
  output logic edge_fall_o
);

  logic a_ff;

  always_ff @(posedge clk_i or negedge aresetn_i)
    if (~aresetn_i)
      a_ff <= 'b0;
    else
      a_ff <= a_i;

assign edge_rise_o = ~a_ff & a_i;
assign edge_fall_o = ~a_i & a_ff;

endmodule