class axi_agent extends uvm_agent;
`uvm_component_utils(axi_agent)

function new(string name, uvm_component parent);
super.new(name, parent);
endfunction

axi_driver m_driver;
axi_monitor m_monitor;
uvm_sequencer #(axi_transaction) wr_sequencer;
uvm_sequencer #(axi_transaction) rd_sequencer;
axi_config cfg;
axi_virtual_sequencer vseqr;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg))
    `uvm_fatal("AGT", "axi_config not set")


if(cfg.is_active == UVM_ACTIVE) begin
wr_sequencer = uvm_sequencer #(axi_transaction)::type_id::create("wr_sequencer", this);
rd_sequencer = uvm_sequencer #(axi_transaction)::type_id::create("rd_sequencer", this);
uvm_config_db#(axi_config)::set(this, "m_driver", "cfg", cfg);
m_driver = axi_driver::type_id::create("m_driver", this);
vseqr = axi_virtual_sequencer::type_id::create("vseqr", this);
end
uvm_config_db#(axi_config)::set(this, "m_monitor", "cfg", cfg);
m_monitor = axi_monitor::type_id::create("m_monitor", this);

endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);

if(cfg.is_active == UVM_ACTIVE) begin
    m_driver.seq_item_port.connect(wr_sequencer.seq_item_export);
m_driver.rd_seq_item_port.connect(rd_sequencer.seq_item_export);
vseqr.wr_sequencer = wr_sequencer;
vseqr.rd_sequencer = rd_sequencer;
end
endfunction
endclass