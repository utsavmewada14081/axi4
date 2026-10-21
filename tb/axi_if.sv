interface axi_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64
) (
    input logic clk,
    input logic rst_n
);

    localparam int STRB_WIDTH = DATA_WIDTH/8;

    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0]             awlen;
    logic [2:0]             awsize;
    logic [1:0]             awburst;
    logic                   awvalid;
    logic                   awready;

    logic [DATA_WIDTH-1:0]  wdata;
    logic [STRB_WIDTH-1:0]  wstrb;
    logic                   wlast;
    logic                   wvalid;
    logic                   wready;

    logic [1:0]             bresp;
    logic                   bvalid;
    logic                   bready;

    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0]             arlen;
    logic [2:0]             arsize;
    logic [1:0]             arburst;
    logic                   arvalid;
    logic                   arready;

    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]             rresp;
    logic                   rlast;
    logic                   rvalid;
    logic                   rready;

    clocking drv_cb @(posedge clk);
        output awaddr, awlen, awsize, awburst, awvalid;
        input  awready;

        output wdata, wstrb, wlast, wvalid;
        input  wready;

        output bready;
        input  bresp, bvalid;

        output araddr, arlen, arsize, arburst, arvalid;
        input  arready;

        output rready;
        input  rdata, rresp, rlast, rvalid;
    endclocking

    clocking mon_cb @(posedge clk);
        input awaddr, awlen, awsize, awburst, awvalid, awready;
        input wdata, wstrb, wlast, wvalid, wready;
        input bresp, bvalid, bready;
        input araddr, arlen, arsize, arburst, arvalid, arready;
        input rdata, rresp, rlast, rvalid, rready;
    endclocking

    modport DRIVER  (clocking drv_cb, input clk, rst_n);
    modport MONITOR (clocking mon_cb, input clk, rst_n);

    // Slave-role clocking block: symmetric to drv_cb with directions
    // reversed -- samples request channels (AW/W/AR + BREADY/RREADY),
    // drives the response/ready side (*READY, B*, R*). Used by
    // axi4_slave_driver when standing in for a real DUT.
    clocking slv_cb @(posedge clk);
        input  awaddr, awlen, awsize, awburst, awvalid;
        output awready;

        input  wdata, wstrb, wlast, wvalid;
        output wready;

        input  bready;
        output bresp, bvalid;

        input  araddr, arlen, arsize, arburst, arvalid;
        output arready;

        input  rready;
        output rdata, rresp, rlast, rvalid;
    endclocking

    modport SLAVE (clocking slv_cb, input clk, rst_n);

    modport CHECKER (input clk, rst_n,
        awaddr, awlen, awsize, awburst, awvalid, awready,
        wdata, wstrb, wlast, wvalid, wready,
        bresp, bvalid, bready,
        araddr, arlen, arsize, arburst, arvalid, arready,
        rdata, rresp, rlast, rvalid, rready);

endinterface