class axi_env extends uvm_env;
`uvm_component_utils(axi_env)

function new(string name, uvm_component parent);
super.new(name, parent);
endfunction

axi_agent m_agent;
axi_scoreboard m_scoreboard;
axi_slave_agent slave_agent;
axi_config cfg;
axi_coverage coverage;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) `uvm_fatal("ENV", "axi_config not set")
m_agent = axi_agent::type_id::create("m_agent", this);
m_scoreboard = axi_scoreboard::type_id::create("m_scoreboard", this);
uvm_config_db#(axi_config)::set(this, "m_agent",    "cfg", cfg);
slave_agent = axi_slave_agent::type_id::create("slave_agent", this);
uvm_config_db#(axi_config)::set(this, "slave_agent", "cfg", cfg);
coverage = axi_coverage::type_id::create("coverage", this);
uvm_config_db#(axi_config)::set(this, "coverage", "cfg", cfg);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
m_agent.m_monitor.wr_ap.connect(m_scoreboard.wr_ap_imp);
m_agent.m_monitor.rd_ap.connect(m_scoreboard.rd_ap_imp);
m_agent.m_monitor.wr_ap.connect(coverage.wr_imp);
m_agent.m_monitor.rd_ap.connect(coverage.rd_imp);
endfunction
endclass