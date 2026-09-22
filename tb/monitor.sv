class axi4_lite_monitor extends uvm_monitor;
`uvm_component_utils(axi4_lite_monitor)
virtual axi_if vif;
uvm_analysis_port #(axi4_lite_transaction) mon_analysis_port;

covergroup axi4_lite_cg;
option.per_instance = 1;
option.name = "axi4_lite_cg";
resetn: coverpoint vif.resetn {
    bins resetn_0 = {0};
    bins resetn_1 = {1};
}
awvalid: coverpoint vif.awvalid {
    bins awvalid_0 = {0};
    bins awvalid_1 = {1};
}
awready: coverpoint vif.awready {
    bins awready_0 = {0};
    bins awready_1 = {1};
}
arvalid: coverpoint vif.arvalid {
    bins arvalid_0 = {0};
    bins arvalid_1 = {1};
}
arready: coverpoint vif.arready {
    bins arready_0 = {0};
    bins arready_1 = {1};
}
wvalid: coverpoint vif.wvalid {
    bins wvalid_0 = {0};
    bins wvalid_1 = {1};
}
wready: coverpoint vif.wready {
    bins wready_0 = {0};
    bins wready_1 = {1};
}
bvalid: coverpoint vif.bvalid {
    bins bvalid_0 = {0};
    bins bvalid_1 = {1};
}
bready: coverpoint vif.bready {
    bins bready_0 = {0};
    bins bready_1 = {1};
}
rvalid: coverpoint vif.rvalid {
    bins rvalid_0 = {0};
    bins rvalid_1 = {1};
}
rready: coverpoint vif.rready {
    bins rready_0 = {0};
    bins rready_1 = {1};
}
awaddr: coverpoint vif.awaddr {
    
    // 1. Extreme Boundaries
    bins addr_zero = {0};
    bins addr_max  = {127};

    bins addr_low  = {[1:43]};
    bins addr_mid  = {[44:85]};
    bins addr_high = {[86:127]};
  }
araddr: coverpoint vif.araddr {
    
    // 1. Extreme Boundaries
    bins addr_zero = {0};
    bins addr_max  = {127};

    bins addr_low  = {[1:43]};
    bins addr_mid  = {[44:85]};
    bins addr_high = {[86:127]};
  }
wdata: coverpoint vif.wdata {
    
    // 1. Extreme Corner Cases (Stuck-at fault detection)
    bins all_zeros = {32'h0000_0000};
    bins all_ones  = {32'hFFFF_FFFF};
    
    // 2. Cross-coupling & Toggle Stress Patterns
    bins alt_a = {32'hAAAA_AAAA}; // 1010...
    bins alt_5 = {32'h5555_5555}; // 0101...
    
    // 3. Byte/Half-word Boundaries (Common logic truncation points)
    bins low_byte_max  = {32'h0000_00FF};
    bins high_byte_max = {32'hFF00_0000};
    bins half_word_max = {32'h0000_FFFF};
    
    // 4. Broad Ranges (Ensures datapath sees a spread of magnitudes)
    // Using 4 bins for the middle ranges keeps memory overhead low
    bins small_vals = {[32'h0000_0100 : 32'h0000_FFFE]};
    bins mid_vals[4]= {[32'h0001_0000 : 32'hFFFE_FFFF]}; 
    bins large_vals = {[32'hFFFF_0000 : 32'hFFFF_FFFE]};
    
    // 5. Critical Transitions (Datapath switching/timing stress)
    bins toggle_0_to_1 = (32'h0000_0000 => 32'hFFFF_FFFF);
    bins toggle_1_to_0 = (32'hFFFF_FFFF => 32'h0000_0000);
    bins toggle_a_to_5 = (32'hAAAA_AAAA => 32'h5555_5555);
    
    // 6. Catch-all for anything outside defined bins (Optional but good practice)
    bins others = default;
  }
rdata: coverpoint vif.rdata {
    
    // 1. Extreme Corner Cases (Stuck-at fault detection)
    bins all_zeros = {32'h0000_0000};
    bins all_ones  = {32'hFFFF_FFFF};
    
    // 2. Cross-coupling & Toggle Stress Patterns
    bins alt_a = {32'hAAAA_AAAA}; // 1010...
    bins alt_5 = {32'h5555_5555}; // 0101...
    
    // 3. Byte/Half-word Boundaries (Common logic truncation points)
    bins low_byte_max  = {32'h0000_00FF};
    bins high_byte_max = {32'hFF00_0000};
    bins half_word_max = {32'h0000_FFFF};
    
    // 4. Broad Ranges (Ensures datapath sees a spread of magnitudes)
    // Using 4 bins for the middle ranges keeps memory overhead low
    bins small_vals = {[32'h0000_0100 : 32'h0000_FFFE]};
    bins mid_vals[4]= {[32'h0001_0000 : 32'hFFFE_FFFF]}; 
    bins large_vals = {[32'hFFFF_0000 : 32'hFFFF_FFFE]};
    
    // 5. Critical Transitions (Datapath switching/timing stress)
    bins toggle_0_to_1 = (32'h0000_0000 => 32'hFFFF_FFFF);
    bins toggle_1_to_0 = (32'hFFFF_FFFF => 32'h0000_0000);
    bins toggle_a_to_5 = (32'hAAAA_AAAA => 32'h5555_5555);
    
    // 6. Catch-all for anything outside defined bins (Optional but good practice)
    bins others = default;
  }
wresp: coverpoint vif.wresp {
    bins wresp_0 = {0};
    bins wresp_3 = {3};
}
rresp: coverpoint vif.rresp {
    bins rresp_0 = {0};
    bins rresp_3 = {3};
}

endgroup


function new(string name, uvm_component parent);
super.new(name, parent);
axi4_lite_cg = new();
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
mon_analysis_port = new("mon_analysis_port", this);
if(!uvm_config_db #(virtual axi_if)::get(this, "", "vif", vif)) begin
    `uvm_error(get_type_name(), "Didn't get handle to virtual interface axi_if")
end

endfunction

virtual task run_phase(uvm_phase phase);

fork
    //Monitor Write Transactions
    forever begin
        axi4_lite_transaction wr_tr = axi4_lite_transaction::type_id::create("wr_tr", this);
        // 1. Wait for synchronous AW handshake
      do begin @(posedge vif.clk); end while (!(vif.awvalid && vif.awready));
      wr_tr.op = 1'b1;
      wr_tr.awaddr = vif.awaddr;
      
      // 2. Wait for synchronous W handshake
      do begin @(posedge vif.clk); end while (!(vif.wvalid && vif.wready));
      wr_tr.wdata = vif.wdata;
      
      // 3. Wait for synchronous B (Response) handshake
      do begin @(posedge vif.clk); end while (!(vif.bvalid && vif.bready));
      wr_tr.wresp = vif.wresp; // Note: AXI standard uses BRESP, not WRESP
      
      `uvm_info(get_type_name(), $sformatf("[MON]: Write Tx -> AWADDR: %0h, WDATA: %0h, BRESP: %0b", 
                wr_tr.awaddr, wr_tr.wdata, wr_tr.wresp), UVM_MEDIUM);
        mon_analysis_port.write(wr_tr);
    end
    forever begin
        axi4_lite_transaction rd_tr = axi4_lite_transaction::type_id::create("rd_tr", this);
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
    end
    forever begin
        @(posedge vif.clk);
        axi4_lite_cg.sample();
    end
join


endtask
endclass