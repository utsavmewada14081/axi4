class axi4_lite_scoreboard extends uvm_scoreboard;
`uvm_component_utils(axi4_lite_scoreboard)
uvm_analysis_imp #(axi4_lite_transaction, axi4_lite_scoreboard) ap_imp;

function new(string name, uvm_component parent);
super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
ap_imp = new("ap_imp", this);
endfunction

bit [31:0] temp;
bit [31:0] data[128] = '{default: 32'h0};

virtual function void write(axi4_lite_transaction tr);
if(tr.op == 1) begin
        `uvm_info(get_type_name(), $sformatf("[SCO]: Write Transaction: OP: %0b, awaddr: %0h, wdata: %0h, wresp: %0b", tr.op, tr.awaddr, tr.wdata, tr.wresp), UVM_MEDIUM)
        if(tr.wresp == 3) `uvm_error(get_type_name(),"[SCO]: DEC Error")
        else begin
            data[tr.awaddr] = tr.wdata;
            `uvm_info(get_type_name(), $sformatf("[SCO]: Data written to memory Addr: %0h Data: %0h", tr.awaddr, tr.wdata), UVM_MEDIUM)
        end
    end
    else begin
        `uvm_info(get_type_name(), $sformatf("[SCO]: Read Transaction: OP: %0b, araddr: %0h, rdata: %0h, rresp: %0b", tr.op, tr.araddr, tr.rdata, tr.rresp), UVM_MEDIUM)
        temp = data[tr.araddr];
        if(tr.rresp == 3) begin
            `uvm_error(get_type_name(), "[SCO]: DEC Error")
        end
        else if(temp == tr.rdata && tr.rresp == 0) begin
            `uvm_info(get_type_name(), $sformatf("[SCO]: Data read from memory Addr: %0h Data: %0h", tr.araddr, tr.rdata), UVM_MEDIUM)
        end
        else begin
            `uvm_info(get_type_name(), $sformatf("[SCO]: Data mismatch Addr: %0h Expected: %0h Read: %0h", tr.araddr, temp, tr.rdata), UVM_MEDIUM)
        end
    end
    `uvm_info(get_type_name(), "-----------------------------------------------------------------------", UVM_MEDIUM)
endfunction
endclass