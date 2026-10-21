class axi_monitor extends uvm_monitor;
`uvm_component_utils(axi_monitor)
virtual axi_if vif;
axi_config cfg;

uvm_analysis_port #(axi_transaction) wr_ap;
uvm_analysis_port #(axi_transaction) rd_ap;

bit valid_drop_seen;

function new(string name, uvm_component parent);
super.new(name, parent);
wr_ap = new("wr_ap", this);
rd_ap = new("rd_ap", this);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg))
    `uvm_fatal("MON", "axi_config not set")
vif = cfg.vif;
endfunction

task watch_valid_drop();
    bit prev_valid = 0;
    bit prev_ready = 0;
    forever begin
        @(vif.mon_cb);
        if (prev_valid && !prev_ready && !vif.mon_cb.wvalid)
            valid_drop_seen = 1;
            `uvm_info("MON", "WVALID drop observed", UVM_LOW)
        prev_valid = vif.mon_cb.wvalid;
        prev_ready = vif.mon_cb.wready;
    end
endtask

task monitor_write_channel();

forever begin
    axi_transaction wr_tr;
    axi4_violation_e data_v, pin_v;
    int beat_count;
    wr_tr = axi_transaction::type_id::create("wr_tr");
    do begin
        @(posedge vif.clk);
    end
    while (!(vif.mon_cb.awvalid && vif.mon_cb.awready));

    wr_tr.dir   = AXI4_WRITE;
    wr_tr.addr = vif.mon_cb.awaddr;
    wr_tr.len = vif.mon_cb.awlen;
    wr_tr.size  = vif.mon_cb.awsize;
    wr_tr.burst = axi4_burst_e'(vif.mon_cb.awburst);
    wr_tr.wdata = new[vif.mon_cb.awlen + 1];
    wr_tr.wstrb = new[vif.mon_cb.awlen + 1];
    beat_count = 0;

    data_v = wr_tr.classify();
    pin_v = VIOL_NONE;

    for (int i = 0; i <= wr_tr.len; i++) begin
        do begin
            @(posedge vif.clk);
        end
        while(!(vif.mon_cb.wvalid && vif.mon_cb.wready));

        wr_tr.wdata[beat_count] = vif.mon_cb.wdata;
        wr_tr.wstrb[beat_count] = vif.mon_cb.wstrb;

        if (i != wr_tr.len && vif.mon_cb.wlast) begin
            `uvm_error("MON", "WLAST asserted before final beat")
            if (wr_tr.inject_violation == VIOL_NONE)
                pin_v = VIOL_WLAST_EARLY;
        end
        if (i == wr_tr.len && !vif.mon_cb.wlast) begin
            `uvm_error("MON", "WLAST not asserted on final beat")
            if (wr_tr.inject_violation == VIOL_NONE)
                pin_v = VIOL_WLAST_EARLY;
        end
    end
    if (valid_drop_seen) begin
        if (pin_v == VIOL_NONE) pin_v = VIOL_VALID_DROP;
        valid_drop_seen = 0;
    end
    if (data_v != VIOL_NONE && pin_v != VIOL_NONE) `uvm_warning("MON", $sformatf("two violations on one burst: %s (fields) + %s (pins)",data_v.name(), pin_v.name()))
    wr_tr.inject_violation = (data_v != VIOL_NONE) ? data_v : pin_v;

    do begin
        @(posedge vif.clk);
    end
    while(!(vif.mon_cb.bvalid && vif.mon_cb.bready));
    wr_tr.resp = vif.mon_cb.bresp;

    `uvm_info(get_type_name(), $sformatf("[MON]: Write Tx -> AWADDR: %0h, WDATA: %0p, BRESP: %0b, VIOLATION: %0s, PIN_VIOLATION: %0s", 
                wr_tr.addr, wr_tr.wdata, wr_tr.resp, wr_tr.inject_violation, pin_v), UVM_MEDIUM);
    wr_ap.write(wr_tr);
end
endtask

task monitor_read_channel();
axi_transaction rd_tr;
int beat_count;

forever begin
    rd_tr = axi_transaction::type_id::create("rd_tr");
    do begin
        @(posedge vif.clk);
    end while(!(vif.mon_cb.arvalid && vif.mon_cb.arready));

    rd_tr.dir   = AXI4_READ;
    rd_tr.addr = vif.mon_cb.araddr;
    rd_tr.len = vif.mon_cb.arlen;
    rd_tr.size = vif.mon_cb.arsize;
    rd_tr.burst = axi4_burst_e'(vif.mon_cb.arburst);

    rd_tr.rdata = new[vif.mon_cb.arlen + 1];
    rd_tr.inject_violation = rd_tr.classify();
    beat_count = 0;

    for (int i = 0; i <= rd_tr.len; i++) begin
    do begin
        @(posedge vif.clk);
    end while(!(vif.mon_cb.rvalid && vif.mon_cb.rready));

    rd_tr.rdata[beat_count] = vif.mon_cb.rdata;
    rd_tr.resp = vif.mon_cb.rresp;

    if (i == rd_tr.len && !vif.mon_cb.rlast)
        `uvm_error("MON", "RLAST not asserted on final beat")
    if (i != rd_tr.len && vif.mon_cb.rlast)
        `uvm_error("MON", "RLAST asserted early")
    beat_count++;
    end

    `uvm_info(get_type_name(), $sformatf("[MON]: Read Tx -> ARADDR: %0h, RDATA: %0p, RRESP: %0b, VIOLATION: %0s", 
                rd_tr.addr, rd_tr.rdata, rd_tr.resp, rd_tr.inject_violation), UVM_MEDIUM);
    rd_ap.write(rd_tr);
end
endtask


virtual task run_phase(uvm_phase phase);
@(posedge vif.rst_n);
@(vif.mon_cb);
fork
    //Monitor Write Transactions
    /*forever begin
        axi_transaction wr_tr = axi_transaction::type_id::create("wr_tr", this);
        // 1. Wait for synchronous AW handshake
      do begin @(posedge vif.clk); end while (!(vif.awvalid && vif.awready));
      wr_tr.op = 1'b1;
      wr_tr.awaddr = vif.awaddr;
      
      // 2. Wait for synchronous W handshake
      do begin @(posedge vif.clk); end while (!(vif.wvalid && vif.wready));
      wr_tr.wdata = vif.wdata;
      
      // 3. Wait for synchronous B (Response) handshake
      do begin @(posedge vif.clk); end while (!(vif.bvalid && vif.bready));
      wr_tr.bresp = vif.bresp; // Note: AXI standard uses BRESP, not bresp
      
      `uvm_info(get_type_name(), $sformatf("[MON]: Write Tx -> AWADDR: %0h, WDATA: %0h, BRESP: %0b", 
                wr_tr.awaddr, wr_tr.wdata, wr_tr.bresp), UVM_MEDIUM);
        mon_analysis_port.write(wr_tr);
    end
    forever begin
        axi_transaction rd_tr = axi_transaction::type_id::create("rd_tr", this);
        // 1. Wait for synchronous AR handshake
      do begin @(posedge vif.clk); end while (!(vif.arvalid && vif.arready));
      rd_tr.op = 1'b0;
      rd_tr.araddr = vif.araddr;
      
      // 2. Wait for synchronous R (Data/Response) handshake
      do begin @(posedge vif.clk); end while (!(vif.rvalid && vif.rready));
      rd_tr.rdata = vif.rdata;
      rd_tr.rresp = vif.rresp;
      
      `uvm_info(get_type_name(), $sformatf("[MON]: Read Tx -> ARADDR: %0h, RDATA: %0h, RRESP: %0b", 
                rd_tr.araddr, rd_tr.rdata, rd_tr.rresp), UVM_MEDIUM);
        mon_analysis_port.write(rd_tr);
    end*/

    monitor_read_channel();
    monitor_write_channel();
    watch_valid_drop();
join


endtask
endclass