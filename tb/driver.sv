class axi4_lite_driver extends uvm_driver #(axi4_lite_transaction);
`uvm_component_utils(axi4_lite_driver)
virtual axi_if vif;

function new(string name, uvm_component parent);
super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db #(virtual axi_if)::get(this, "", "vif", vif))begin
    `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface axi_if")
end
endfunction

task reset();
  vif.resetn <= 0;
  vif.awvalid <= 0;
  vif.arvalid <= 0;
  vif.wvalid <= 0;
  vif.bready <= 0;
  vif.rready <= 0;
  vif.awaddr <= 0;
  vif.araddr <= 0;
    vif.wdata <= 0;
    repeat(5) @(posedge vif.clk);
    vif.resetn <= 1;

    `uvm_info(get_type_name(), $sformatf("----------------[DRIVER]: Reset Done------------------"), UVM_MEDIUM);
  endtask

task write_data(input axi4_lite_transaction tr);
  `uvm_info(get_type_name(), $sformatf("[DRV]: Write Transaction: OP: %0b, awaddr: %0h, wdata: %0h", tr.op, tr.awaddr, tr.wdata), UVM_MEDIUM);
  vif.op <= 1'b1;
  vif.resetn <= 1'b1;
  vif.awvalid <= 1'b1;
  vif.arvalid <= 1'b0;
  vif.araddr <= 0;
  vif.awaddr <= tr.awaddr;
  @(negedge vif.awready);
  vif.awvalid <= 1'b0;
  vif.wvalid <= 1'b1;
  vif.wdata <= tr.wdata;
  @(negedge vif.wready);
  vif.wvalid <= 1'b0;
  vif.wdata <= 0;
  vif.bready <= 1'b1;
  vif.rready <= 1'b0;
  @(negedge vif.bvalid);
    vif.bready <= 1'b0;
  endtask

  task read_data(input axi4_lite_transaction tr);
  `uvm_info(get_type_name(), $sformatf("[DRV]: Read Transaction: OP: %0b, araddr: %0h", tr.op, tr.araddr), UVM_MEDIUM);
  vif.op <= 1'b0;
  vif.resetn <= 1'b1;
  vif.arvalid <= 1'b1;
  vif.awvalid <= 1'b0;
  vif.awaddr <= 0;
  vif.araddr <= tr.araddr;
  @(negedge vif.arready);
  vif.arvalid <= 1'b0;
  vif.rready <= 1'b1;
  vif.araddr <= 0;
  @(negedge vif.rvalid);
  vif.rready <= 1'b0;
  endtask

virtual task run_phase(uvm_phase phase);
axi4_lite_transaction tr;
reset();
forever begin
    seq_item_port.get_next_item(tr);
    @(posedge vif.clk);
    if(tr.op == 1) begin
        write_data(tr);
    end
    else begin
        read_data(tr);
    end
    @(posedge vif.clk);
    seq_item_port.item_done();
end
endtask
endclass