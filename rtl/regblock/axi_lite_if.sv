interface axi4lite_intf #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter RESP_WIDTH = 1
);
localparam STRB_WIDTH = (DATA_WIDTH + 7) / 8;

// read address channel
logic [ ADDR_WIDTH-1:0 ]  ARADDR;
logic                     ARVALID;
logic                     ARREADY;

// read data channel
logic [ DATA_WIDTH-1:0 ]  RDATA;
logic [ RESP_WIDTH-1:0 ]  RRESP;
logic                     RVALID;
logic                     RREADY;

// write address channel
logic [ ADDR_WIDTH-1:0 ]  AWADDR;
logic                     AWVALID;
logic                     AWREADY;

// write data channel
logic [ DATA_WIDTH-1:0 ]  WDATA;
logic [ STRB_WIDTH-1:0 ]  WSTRB;
logic                     WVALID;
logic                     WREADY;

// write response channel
logic [ RESP_WIDTH-1:0 ]  BRESP;
logic                     BVALID;
logic                     BREADY;

modport slave (
  input ARADDR, ARVALID,       output ARREADY,
  input RREADY,                output RDATA, RRESP, RVALID,
  input AWADDR, AWVALID,       output AWREADY,
  input WDATA, WSTRB, WVALID,  output WREADY,
  input BREADY,                output BRESP, BVALID
);

endinterface