class axi_driver extends uvm_driver #(axi_transaction);
`uvm_component_utils(axi_driver)
virtual axi_if vif;
axi_config cfg;

//seq_item_port is inherited from uvm_driver and is used to get the transaction from the sequencer
uvm_seq_item_pull_port #(axi_transaction) rd_seq_item_port;

function new(string name, uvm_component parent);
super.new(name, parent);
rd_seq_item_port = new("rd_seq_item_port", this);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db #(virtual axi_if)::get(this, "", "vif", vif))begin
    `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface axi_if")
    vif = cfg.vif;
end
endfunction

task drive_idle_defaults();
    vif.drv_cb.awvalid <= 1'b0;
    vif.drv_cb.wvalid  <= 1'b0;
    vif.drv_cb.wlast   <= 1'b0;
    vif.drv_cb.bready  <= 1'b0;
    vif.drv_cb.arvalid <= 1'b0;
    vif.drv_cb.rready  <= 1'b0;
endtask

task wait_reset_done();
    @(posedge vif.rst_n);
    @(vif.drv_cb);
    `uvm_info(get_type_name(), $sformatf("[DRV]: Reset Done"), UVM_MEDIUM)
endtask
/*task write_data(input axi_transaction tr);
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
  endtask*/

task drive_write_burst(axi_transaction tr);
fork
  begin
    @(vif.drv_cb);
    vif.drv_cb.awvalid <= 1'b1;
    vif.drv_cb.awaddr <= tr.addr;
    vif.drv_cb.awlen <= tr.len;
    vif.drv_cb.awsize <= tr.size;
    vif.drv_cb.awburst <= tr.burst;

    do begin @(vif.drv_cb); end while(!vif.drv_cb.awready);
    vif.drv_cb.awvalid <= 1'b0;
  end

  begin
    for (int i = 0; i <= tr.len; i++) begin
      vif.drv_cb.wdata <= tr.wdata[i];
      vif.drv_cb.wstrb <= tr.wstrb[i];
      vif.drv_cb.wlast <= (tr.inject_violation == VIOL_WLAST_EARLY)
                                    ? (i == tr.len - 1) : (i == tr.len);
      vif.drv_cb.wvalid <= 1'b1;
      @(vif.drv_cb);   

      if (tr.inject_violation == VIOL_VALID_DROP && i == 0 && !vif.drv_cb.wready) begin
          vif.drv_cb.wvalid <= 1'b0;      // withdrawn before accepted: violation
          @(vif.drv_cb);
          vif.drv_cb.wvalid <= 1'b1;
          @(vif.drv_cb);
      end

      while (!(vif.drv_cb.wready)) @(vif.drv_cb);
    end
    vif.drv_cb.wvalid <= 1'b0;
    vif.drv_cb.wlast <= 1'b0;
  end

  begin
    @(vif.drv_cb);
    vif.drv_cb.bready <= 1'b1;
    do begin
      @(vif.drv_cb);
    end
    while(!(vif.drv_cb.bvalid));
    vif.drv_cb.bready <= 1'b0;
  end
join
endtask

task drive_read_burst(axi_transaction tr);
fork
  begin
    @(vif.drv_cb);
    vif.drv_cb.arvalid <= 1'b1;
    vif.drv_cb.araddr <= tr.addr;
    vif.drv_cb.arlen <= tr.len;
    vif.drv_cb.arsize <= tr.size;
    vif.drv_cb.arburst <= tr.burst;

    do begin
      @(vif.drv_cb);
    end
    while(!(vif.drv_cb.arready));
    vif.drv_cb.arvalid <= 1'b0;
  end

  begin
    tr.rdata = new[tr.len + 1];
    vif.drv_cb.rready <= 1'b1;
    foreach(tr.rdata[i]) begin
      do begin
        @(vif.drv_cb);
      end
      while(!(vif.drv_cb.rvalid && vif.drv_cb.rready));
      tr.rdata[i] = vif.drv_cb.rdata;
      if (vif.drv_cb.rlast) break;
    end
    vif.drv_cb.rready <= 1'b0;
  end
join
endtask

/*
  task read_data(input axi_transaction tr);
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
  */

virtual task run_phase(uvm_phase phase);
axi_transaction tr;
//reset();
drive_idle_defaults();
wait_reset_done();
fork
  write_issue_process();
  read_issue_process();
join

endtask

task write_issue_process();
forever begin
  axi_transaction tr;
  seq_item_port.get_next_item(tr);
  drive_write_burst(tr);
  seq_item_port.item_done();
end
endtask

task read_issue_process();
forever begin
  axi_transaction tr;
  rd_seq_item_port.get_next_item(tr);
  drive_read_burst(tr);
  $display("Read Data first transaction");
  rd_seq_item_port.item_done();
end
endtask
endclass