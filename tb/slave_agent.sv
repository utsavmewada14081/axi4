//=============================================================================
// axi4_slave_agent.sv
// Deliberately thin: just the reactive slave driver. No sequencer (a slave
// doesn't initiate transactions to be sequenced) and no monitor of its own
// -- the master agent's monitor already observes this same bus, and a
// second monitor here would double-count every transaction into the
// scoreboard/coverage.
//=============================================================================
class axi_slave_agent extends uvm_agent;
    `uvm_component_utils(axi_slave_agent)

    axi_slave_driver driver;
    axi_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("SLVAGT", "axi_config not set")
        driver = axi_slave_driver::type_id::create("driver", this);
        uvm_config_db#(axi_config)::set(this, "driver", "cfg", cfg);
    endfunction
endclass