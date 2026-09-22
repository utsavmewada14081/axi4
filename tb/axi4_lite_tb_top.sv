
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi4_lite_pkg.sv"
import axi4_lite_pkg::*;
`include "../rtl/axi4_lite_dut.sv"

module axi4_lite_top;

axi_if vif();

axilite_s dut(
    .s_axi_aclk(vif.clk),
    .s_axi_aresetn(vif.resetn),
    .s_axi_awvalid(vif.awvalid),
    .s_axi_awready(vif.awready),
    .s_axi_arvalid(vif.arvalid),
    .s_axi_arready(vif.arready),
    .s_axi_wvalid(vif.wvalid),
    .s_axi_wready(vif.wready),
    .s_axi_bready(vif.bready),
    .s_axi_bvalid(vif.bvalid),
    .s_axi_rvalid(vif.rvalid),
    .s_axi_rready(vif.rready),
    .s_axi_awaddr(vif.awaddr),
    .s_axi_araddr(vif.araddr),
    .s_axi_wdata(vif.wdata),
    .s_axi_rdata(vif.rdata),
    .s_axi_bresp(vif.wresp),
    .s_axi_rresp(vif.rresp)
);

initial begin
    vif.clk = 0;
    forever #5 vif.clk = ~vif.clk;
end

initial begin
    uvm_config_db #(virtual axi_if)::set(null, "*", "vif", vif);
    run_test("axi4_lite_test");
end

initial begin
    $dumpfile("axi4_lite_top.vcd");
    $dumpvars(0, axi4_lite_top);
end
endmodule