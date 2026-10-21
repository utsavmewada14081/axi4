class axi_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(axi_virtual_sequencer)

    uvm_sequencer #(axi_transaction) wr_sequencer;
    uvm_sequencer #(axi_transaction) rd_sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass