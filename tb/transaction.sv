class axi4_lite_transaction extends uvm_sequence_item;
randc bit op;
rand bit [31:0] awaddr;
rand bit [31:0] araddr;
rand bit [31:0] wdata;
bit [31:0] rdata;
bit [1:0] wresp;
bit [1:0] rresp;

constraint valid_addr_range {awaddr inside {[0:128]}; araddr inside {[0:128]};}
constraint addr_distribution {awaddr dist{[0:32] :/ 30, [33:64] :/ 20, [65:96] :/ 20, [97:127] :/ 25, 128 :/ 5}; araddr dist{[0:32] :/ 30, [33:64] :/ 20, [65:96] :/ 20, [97:127] :/ 25, 128 :/ 5};}
constraint valid_data_range {wdata inside {[32'h0:32'hFFFF_FFFF]}; rdata inside {[32'h0:32'hFFFF_FFFF]};}
constraint data_distribution {wdata dist{32'h0000_0000 := 2,
    32'hFFFF_FFFF := 2,
    32'hAAAA_AAAA := 2,
    32'h5555_5555 := 2,
    32'h0000_00FF := 2,
    32'hFF00_0000 := 2,
    32'h0000_FFFF := 2,
    [32'h0000_0100:32'h0000_FFFE] :/ 25,
    [32'h0001_0000:32'hFFFE_FFFF] :/ 36,
    [32'hFFFF_0000:32'hFFFF_FFFE] :/ 25};

rdata dist{32'h0000_0000 := 2,
    32'hFFFF_FFFF := 2,
    32'hAAAA_AAAA := 2,
    32'h5555_5555 := 2,
    32'h0000_00FF := 2,
    32'hFF00_0000 := 2,
    32'h0000_FFFF := 2,
    [32'h0000_0100:32'h0000_FFFE] :/ 25,
    [32'h0001_0000:32'hFFFE_FFFF] :/ 36,
    [32'hFFFF_0000:32'hFFFF_FFFE] :/ 25};}

    `uvm_object_utils_begin(axi4_lite_transaction)
    `uvm_field_int(op, UVM_ALL_ON)
    `uvm_field_int(awaddr, UVM_ALL_ON)
    `uvm_field_int(araddr, UVM_ALL_ON)
    `uvm_field_int(wdata, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(wresp, UVM_ALL_ON)
    `uvm_field_int(rresp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4_lite_transaction");
    super.new(name);
    endfunction
endclass