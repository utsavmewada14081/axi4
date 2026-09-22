class axi4_lite_test extends uvm_test;
`uvm_component_utils(axi4_lite_test)

function new(string name, uvm_component parent);
super.new(name, parent);
endfunction

axi4_lite_env m_top_env;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
m_top_env = axi4_lite_env::type_id::create("m_top_env", this);
endfunction

virtual function void end_of_elaboration_phase(uvm_phase phase);
uvm_top.print_topology();
endfunction

virtual task run_phase(uvm_phase phase);
axi4_lite_sequence m_seq = axi4_lite_sequence::type_id::create("m_seq");
phase.raise_objection(this);
m_seq.start(m_top_env.m_agent.m_sequencer);
phase.drop_objection(this);
endtask
endclass