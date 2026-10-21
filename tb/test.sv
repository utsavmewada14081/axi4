class axi_base_test extends uvm_test;
`uvm_component_utils(axi_base_test)

function new(string name="axi_base_test", uvm_component parent);
super.new(name, parent);
endfunction

axi_env m_top_env;
axi_config cfg;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
cfg = axi_config::type_id::create("cfg");
if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", cfg.vif)) `uvm_fatal("TEST", "virtual axi_if not set")
configure(cfg);
uvm_config_db#(axi_config)::set(this, "m_top_env", "cfg", cfg);
m_top_env = axi_env::type_id::create("m_top_env", this);
endfunction

virtual function void configure(axi_config c);
        c.is_active = UVM_ACTIVE;
    endfunction

virtual function void end_of_elaboration_phase(uvm_phase phase);
uvm_top.print_topology();
endfunction

virtual task run_phase(uvm_phase phase);
//axi_sequence seq = axi_sequence::type_id::create("seq");
read_after_write_seq seq = read_after_write_seq::type_id::create("seq");
phase.raise_objection(this);
seq.start(m_top_env.m_agent.vseqr);
phase.drop_objection(this);
endtask
endclass