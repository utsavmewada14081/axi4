class axi4_lite_agent extends uvm_agent;
`uvm_component_utils(axi4_lite_agent)

function new(string name, uvm_component parent);
super.new(name, parent);
endfunction

axi4_lite_driver m_driver;
axi4_lite_monitor m_monitor;
uvm_sequencer #(axi4_lite_transaction) m_sequencer;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);

if(get_is_active()) begin
    m_sequencer = uvm_sequencer #(axi4_lite_transaction)::type_id::create("m_sequencer", this);
    m_driver = axi4_lite_driver::type_id::create("m_driver", this);
end

m_monitor = axi4_lite_monitor::type_id::create("m_monitor", this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);

if(get_is_active())
m_driver.seq_item_port.connect(m_sequencer.seq_item_export);

endfunction
endclass