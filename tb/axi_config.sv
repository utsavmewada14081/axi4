class axi_config extends uvm_object;
    `uvm_object_utils(axi_config)

    uvm_active_passive_enum is_active   = UVM_ACTIVE;
    virtual axi_if                     vif;
    int unsigned                        addr_width = 32;
    int unsigned                        data_width = 64;
    int unsigned                        id_width   = 4;

    int unsigned max_outstanding_wr = 8;
    int unsigned max_outstanding_rd = 8;

    bit          backpressure_enable   = 1;
    int unsigned bready_delay_min      = 0;
    int unsigned bready_delay_max      = 8;
    int unsigned rready_delay_min      = 0;
    int unsigned rready_delay_max      = 8;

    bit          random_latency_enable = 1;
    int unsigned inter_txn_delay_min   = 0;
    int unsigned inter_txn_delay_max   = 16;

    bit          concurrent_rw_enable  = 1;

    bit          allow_unaligned_addr  = 1;
    bit          allow_max_burst       = 1;
    bit          enforce_4kb_boundary  = 1;

    bit          negative_test_enable  = 0;
    int unsigned violations_injected   = 0;
    int unsigned violations_detected   = 0;

    bit          coverage_enable       = 1;

    // --- no-DUT / master+slave loopback mode ---
    // When has_dut = 0, axi4_env builds a second, reactive slave agent
    // (axi4_slave_agent) that responds to the master agent directly --
    // no real DUT needed. Default (1) preserves the original behavior:
    // one master agent, a real DUT instantiated in tb_top.
    bit          has_dut               = 1;

    // --- slave-side knobs (only used when has_dut = 0) ---
    int unsigned slave_mem_bytes        = 65536;
    bit          slave_backpressure_enable = 1;
    int unsigned awready_delay_min      = 0;
    int unsigned awready_delay_max      = 4;
    int unsigned wready_delay_min       = 0;
    int unsigned wready_delay_max       = 4;
    int unsigned arready_delay_min      = 0;
    int unsigned arready_delay_max      = 4;
    int unsigned bvalid_delay_min       = 0;
    int unsigned bvalid_delay_max       = 4;
    int unsigned rvalid_delay_min       = 0;
    int unsigned rvalid_delay_max       = 4;
    bit          slave_error_inject_enable = 0;
    int unsigned slave_error_inject_pct = 0;   // 0-100, chance of SLVERR per burst

    function new(string name = "axi_config");
        super.new(name);
    endfunction
endclass