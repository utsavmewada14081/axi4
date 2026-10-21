`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_pkg.sv"
import axi_pkg::*;
`include "axi_if.sv"

module axi_tb_top_no_dut;
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 64;

    logic clk = 0;
    logic rst_n;
    always #5 clk = ~clk;

    axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
        vif (.clk(clk), .rst_n(rst_n));


    initial begin
        rst_n = 0;
        #40 rst_n = 1;
    end

    initial begin
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif", vif);
        run_test("axi_base_test");
    end

    initial begin
        $dumpfile("../sim/waveform_no_dut.vcd");
        $dumpvars(0, axi_tb_top_no_dut);
    end
endmodule