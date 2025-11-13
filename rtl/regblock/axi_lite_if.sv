interface axi4lite_intf #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter RESP_WIDTH = 1
);
localparam STRB_WIDTH = (DATA_WIDTH + 7) / 8;

// read address channel
logic [ ADDR_WIDTH-1:0 ]  ARADDR;
logic [            3:0 ]  ar_qos;
logic                     ARVALID;
logic                     ARREADY;

// read data channel
logic [ DATA_WIDTH-1:0 ]  RDATA;
logic [ RESP_WIDTH-1:0 ]  r_resp;
logic                     RVALID;
logic                     RREADY;

// write address channel
logic [ ADDR_WIDTH-1:0 ]  AWADDR;
logic [            3:0 ]  aw_qos;
logic                     AWVALID;
logic                     AWREADY;

// write data channel
logic [ DATA_WIDTH-1:0 ]  WDATA;
logic [ STRB_WIDTH-1:0 ]  WSTRB;
logic                     WVALID;
logic                     WREADY;

// write response channel
logic [ RESP_WIDTH-1:0 ]  b_resp;
logic                     BVALID;
logic                     b_ready;

modport slave (
  input ar_addr, ar_valid, ar_qos,   output ar_ready,
  input r_ready,                     output r_data, r_resp, r_valid,
  input aw_addr, aw_valid, aw_qos,   output aw_ready,
  input w_data, w_strb, w_valid,     output w_ready,
  input b_ready,                     output b_resp, b_valid
);

endinterface