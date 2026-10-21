`uvm_analysis_imp_decl(_cwr)
`uvm_analysis_imp_decl(_crd)

class axi_coverage extends uvm_component;
    `uvm_component_utils(axi_coverage)

    uvm_analysis_imp_cwr #(axi_transaction, axi_coverage) wr_imp;
    uvm_analysis_imp_crd #(axi_transaction, axi_coverage) rd_imp;

    axi_config cfg;

    /*covergroup axi_cg with function sample(axi_transaction tr);
    option.per_instance = 1;
    option.name = "axi_cg";
    rst_n: coverpoint tr.rst_n {
        bins rst_n_0 = {0};
        bins rst_n_1 = {1};
    }
    awvalid: coverpoint tr.awvalid {
        bins awvalid_0 = {0};
        bins awvalid_1 = {1};
    }
    awready: coverpoint tr.awready {
        bins awready_0 = {0};
        bins awready_1 = {1};
    }
    arvalid: coverpoint tr.arvalid {
        bins arvalid_0 = {0};
        bins arvalid_1 = {1};
    }
    arready: coverpoint tr.arready {
        bins arready_0 = {0};
        bins arready_1 = {1};
    }
    wvalid: coverpoint tr.wvalid {
        bins wvalid_0 = {0};
        bins wvalid_1 = {1};
    }
    wready: coverpoint tr.wready {
        bins wready_0 = {0};
        bins wready_1 = {1};
    }
    bvalid: coverpoint tr.bvalid {
        bins bvalid_0 = {0};
        bins bvalid_1 = {1};
    }
    bready: coverpoint tr.bready {
        bins bready_0 = {0};
        bins bready_1 = {1};
    }
    rvalid: coverpoint tr.rvalid {
        bins rvalid_0 = {0};
        bins rvalid_1 = {1};
    }
    rready: coverpoint tr.rready {
        bins rready_0 = {0};
        bins rready_1 = {1};
    }
    awaddr: coverpoint tr.awaddr {
        
        // 1. Extreme Boundaries
        bins addr_zero = {0};
        bins addr_max  = {127};

        bins addr_low  = {[1:43]};
        bins addr_mid  = {[44:85]};
        bins addr_high = {[86:127]};
    }
    araddr: coverpoint tr.araddr {
        
        // 1. Extreme Boundaries
        bins addr_zero = {0};
        bins addr_max  = {127};

        bins addr_low  = {[1:43]};
        bins addr_mid  = {[44:85]};
        bins addr_high = {[86:127]};
    }
    wdata: coverpoint tr.wdata {
        
        // 1. Extreme Corner Cases (Stuck-at fault detection)
        bins all_zeros = {64'h0000_0000_0000_0000};
        bins all_ones  = {64'hFFFF_FFFF_FFFF_FFFF};
        
        // 2. Cross-coupling & Toggle Stress Patterns
        bins alt_a = {64'hAAAA_AAAA_AAAA_AAAA}; // 1010...
        bins alt_5 = {64'h5555_5555_5555_5555}; // 0101...
        
        // 3. Byte/Half-word Boundaries (Common logic truncation points)
        bins low_byte_max  = {64'h0000_00FF_0000_00FF};
        bins high_byte_max = {64'hFF00_0000_FF00_0000};
        bins half_word_max = {64'h0000_FFFF_FFFF_FFFF};
        
        // 4. Broad Ranges (Ensures datapath sees a spread of magnitudes)
        // Using 4 bins for the middle ranges keeps memory overhead low
        bins small_vals = {[64'h0000_0100_0000_0100 : 64'h0000_00FF_FFFF_FFFE]};
        bins mid_vals[4]= {[64'h0001_0000_0001_0000 : 64'hFFFE_FFFE_FFFE_FFFF]}; 
        bins large_vals = {[64'hFFFF_0000_FFFF_0000 : 64'hFFFF_FFFF_FFFF_FFFE]};
        
        // 5. Critical Transitions (Datapath switching/timing stress)
        bins toggle_0_to_1 = (64'h0000_0000_0000_0000 => 64'hFFFF_FFFF_FFFF_FFFF);
        bins toggle_1_to_0 = (64'hFFFF_FFFF_FFFF_FFFF => 64'h0000_0000_0000_0000);
        bins toggle_a_to_5 = (64'hAAAA_AAAA_AAAA_AAAA => 64'h5555_5555_5555_5555);
        
        // 6. Catch-all for anything outside defined bins (Optional but good practice)
        bins others = default;
    }
    rdata: coverpoint tr.rdata {
        
        // 1. Extreme Corner Cases (Stuck-at fault detection)
        bins all_zeros = {64'h0000_0000_0000_0000};
        bins all_ones  = {64'hFFFF_FFFF_FFFF_FFFF};
        
        // 2. Cross-coupling & Toggle Stress Patterns
        bins alt_a = {64'hAAAA_AAAA_AAAA_AAAA}; // 1010...
        bins alt_5 = {64'h5555_5555_5555_5555}; // 0101...
        
        // 3. Byte/Half-word Boundaries (Common logic truncation points)
        bins low_byte_max  = {64'h0000_00FF_0000_00FF};
        bins high_byte_max = {64'hFF00_0000_FF00_0000};
        bins half_word_max = {64'h0000_FFFF_FFFF_FFFF};
        
        // 4. Broad Ranges (Ensures datapath sees a spread of magnitudes)
        // Using 4 bins for the middle ranges keeps memory overhead low
        bins small_vals = {[64'h0000_0100_0000_0100 : 64'h0000_00FF_FFFF_FFFE]};
        bins mid_vals[4]= {[64'h0001_0000_0001_0000 : 64'hFFFE_FFFE_FFFE_FFFF]}; 
        bins large_vals = {[64'hFFFF_0000_FFFF_0000 : 64'hFFFF_FFFF_FFFF_FFFE]};
        
        // 5. Critical Transitions (Datapath switching/timing stress)
        bins toggle_0_to_1 = (64'h0000_0000_0000_0000 => 64'hFFFF_FFFF_FFFF_FFFF);
        bins toggle_1_to_0 = (64'hFFFF_FFFF_FFFF_FFFF => 64'h0000_0000_0000_0000);
        bins toggle_a_to_5 = (64'hAAAA_AAAA_AAAA_AAAA => 64'h5555_5555_5555_5555);
        
        // 6. Catch-all for anything outside defined bins (Optional but good practice)
        bins others = default;
    }
    bresp: coverpoint tr.bresp {
        bins bresp_0 = {0};
        bins bresp_3 = {3};
    }
    rresp: coverpoint tr.rresp {
        bins rresp_0 = {0};
        bins rresp_3 = {3};
    }

    endgroup*/

    covergroup cg_core with function sample(axi_transaction tr);
        option.per_instance = 1;
        cp_dir:   coverpoint tr.dir;
        cp_burst: coverpoint tr.burst;
        cp_size:  coverpoint tr.size    { bins sizes[] = {[0:3]}; }
        cp_len:   coverpoint tr.len {
            bins single      = {0};
            bins short_burst = {[1:15]};
            bins long_burst  = {[16:254]};
            bins max_burst   = {255};
        }
        cx_burst_size: cross cp_burst, cp_size;
    endgroup

    covergroup cg_corner with function sample(axi_transaction tr);
        option.per_instance = 1;
        cp_unaligned: coverpoint (tr.addr[2:0] != 3'b000) {
            bins aligned   = {0};
            bins unaligned = {1};
        }
        cp_4kb_boundary: coverpoint tr.crosses_4kb() {
            bins no_cross = {0};
            bins crosses  = {1};
        }
        cp_wrap_max: coverpoint (tr.burst == AXI4_WRAP && tr.len == 15) {
            bins hit = {1};
        }
        cp_max_incr: coverpoint (tr.burst == AXI4_INCR && tr.len == 255) {
            bins hit = {1};
        }
    endgroup

    /*covergroup cg_stress with function sample(axi4_transaction tr, int unsigned wait_cycles,
                                                int unsigned outstanding_depth);
        option.per_instance = 1;
        cp_wait: coverpoint wait_cycles {
            bins none      = {0};
            bins short_bp  = {[1:4]};
            bins long_bp   = {[5:15]};
            bins extreme   = {[16:$]};
        }
        cp_outstanding: coverpoint outstanding_depth {
            bins low  = {[1:2]};
            bins mid  = {[3:6]};
            bins high = {[7:$]};
        }
        cx_wait_dir: cross cp_wait, tr.dir;
    endgroup*/

    covergroup cg_negative with function sample(axi_transaction tr);
        option.per_instance = 1;
        cp_violation: coverpoint tr.inject_violation {
            bins none          = {VIOL_NONE};
            bins cross_4kb     = {VIOL_4KB_CROSS};
            bins wrap_bad_len  = {VIOL_WRAP_BAD_LEN};
            bins size_too_big  = {VIOL_SIZE_TOO_LARGE};
            bins wlast_early   = {VIOL_WLAST_EARLY};
            bins valid_drop    = {VIOL_VALID_DROP};
        }
    endgroup

    function new(string name, uvm_component parent);
    super.new(name, parent);
    wr_imp = new("wr_imp", this);
    rd_imp = new("rd_imp", this);
    cg_core     = new();
    cg_corner   = new();
    //cg_stress   = new();
    cg_negative = new();
    endfunction

    function void sample_common(axi_transaction tr);
        if (!cfg.coverage_enable) return;
        cg_core.sample(tr);
        cg_corner.sample(tr);
        cg_negative.sample(tr);
        //axi_cg.sample(tr);
        //cg_stress.sample(tr, 0, 1);
    endfunction

    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("COV", "axi_config not set")
    endfunction

    virtual function void write_cwr(axi_transaction tr);
        sample_common(tr);
    endfunction

    virtual function void write_crd(axi_transaction tr);
        sample_common(tr);
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf(
            "cg_core=%.2f%% cg_corner=%.2f%% cg_negative=%.2f%%",
            cg_core.get_coverage(), cg_corner.get_coverage(), cg_negative.get_coverage()), UVM_LOW)
    endfunction
endclass