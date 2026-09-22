class axi4_lite_sequence extends uvm_sequence #(axi4_lite_transaction);
`uvm_object_utils(axi4_lite_sequence)

function new(string name = "axi4_lite_sequence");
super.new(name);
endfunction

int count = 0;

virtual task pre_body();
uvm_phase phase = starting_phase;
if(starting_phase != null)
starting_phase.raise_objection(this);
endtask

virtual task body();
repeat(250) begin
    req = axi4_lite_transaction::type_id::create("req");
    start_item(req);
    assert(req.randomize()) else begin
        `uvm_error(get_type_name, "Randomization failed")
    end
    `uvm_info(get_type_name(), $sformatf("[GEN]: op: %0d, awaddr: %0h, araddr: %0h, wdata: %0h", req.op, req.awaddr, req.araddr, req.wdata), UVM_MEDIUM)
    finish_item(req);
end
endtask

virtual task post_body();
uvm_phase phase = starting_phase;
if(starting_phase != null)
starting_phase.drop_objection(this);
endtask
endclass