`uvm_analysis_imp_decl(_wr);
`uvm_analysis_imp_decl(_rd);

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)
    uvm_analysis_imp_rd #(axi_transaction, axi_scoreboard) rd_ap_imp;
    uvm_analysis_imp_wr #(axi_transaction, axi_scoreboard) wr_ap_imp;

    function new(string name, uvm_component parent);
    super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_ap_imp = new("wr_ap_imp", this);
    rd_ap_imp = new("rd_ap_imp", this);
    endfunction

    bit [31:0] temp;
    //bit [31:0] data[128] = '{default: 32'h0};
    bit [7:0] ref_mem[bit[31:0]]; //byte_addressable

    function bit [31:0] get_beat_addr(bit [31:0] start_addr, bit [7:0] len, bit [2:0] size, bit [1:0] burst_type, int beat_idx);
    int num_bytes;
    int burst_length;
    bit [31:0] aligned_addr;
    bit [31:0] wrap_boundary;
    bit [31:0] current_addr;

    num_bytes = 1<<size;
    burst_length = len + 1;
    aligned_addr = start_addr & ~(num_bytes - 1);
    if(beat_idx == 0) begin
        return aligned_addr;
    end

    case (burst_type)
        2'b00: begin
            current_addr = start_addr;
        end
        2'b01: begin
            current_addr = aligned_addr + (beat_idx*num_bytes);
        end
        2'b10: begin
            bit [31:0] wrap_mask = (num_bytes* burst_length) - 1;
            wrap_boundary = start_addr & ~wrap_mask;

            current_addr = aligned_addr + (beat_idx * num_bytes);

            if(current_addr >= (wrap_boundary + (num_bytes*burst_length))) begin
                current_addr = current_addr - (num_bytes*burst_length);
            end
        end
        default: current_addr = start_addr;
    endcase

    return current_addr;
    endfunction

    virtual function void write_wr(axi_transaction tr);
    int num_bytes = 1 << tr.size;
    bit [31:0] current_addr;

    for(int i = 0; i <= tr.len; i++) begin
        current_addr = get_beat_addr(tr.addr, tr.len, tr.size, tr.burst, i);
        // Optional: Print the start of every beat, regardless of WSTRB
        `uvm_info("SCO_MEM", $sformatf("--- Processing Beat %0d at Addr %0h ---", i, current_addr), UVM_HIGH)
        for(int byte_idx = 0; byte_idx < num_bytes; byte_idx++)begin
            if(tr.wstrb[i][byte_idx] == 1'b1) begin
                bit [31:0] exact_byte_addr = current_addr + byte_idx;

                ref_mem[exact_byte_addr] = tr.wdata[i][(byte_idx*8) +: 8];

                // FIX: Added 'Beat %0d' and 'Lane %0d' for exact traceability
                `uvm_info("SCO_MEM", $sformatf("[Beat %0d] Wrote %0h to address %0h (Lane %0d)", 
                        i, ref_mem[exact_byte_addr], exact_byte_addr, byte_idx), UVM_HIGH)
            end
        end
    end

/*if(tr.op == 1) begin
        `uvm_info(get_type_name(), $sformatf("[SCO]: Write Transaction: OP: %0b, awaddr: %0h, wdata: %0h, bresp: %0b", tr.op, tr.awaddr, tr.wdata, tr.bresp), UVM_MEDIUM)
        if(tr.bresp == 3) `uvm_error(get_type_name(),"[SCO]: DEC Error")
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
    */
    endfunction

    virtual function void write_rd(axi_transaction tr);
    int num_bytes = 1<<tr.size;
    bit [31:0] current_addr;
    bit [7:0] expected_byte;
    bit [7:0] actual_byte;
    bit match_failed;

    `uvm_info("SCO_RD", $sformatf("Checking ARADDR: %0h, LEN: %0d, BURST: %0b", tr.addr, tr.len, tr.burst), UVM_LOW)

    foreach(tr.rdata[i]) begin
        current_addr = get_beat_addr(tr.addr, tr.len, tr.size, tr.burst, i);
        match_failed = 0;

        for(int byte_idx = 0; byte_idx < num_bytes; byte_idx++) begin
            bit [31:0] exact_byte_addr = current_addr + byte_idx;

            //If the first beat is not aligned to the start address, skip the bytes before the start address
            if(i == 0 && exact_byte_addr < tr.addr) begin
                continue;
            end

            actual_byte = tr.rdata[i][(byte_idx*8) +: 8];

            if(ref_mem.exists(exact_byte_addr)) begin
                expected_byte = ref_mem[exact_byte_addr];
            end
            else begin
                expected_byte = 8'h00;
            end

            if(actual_byte !== expected_byte) begin
                `uvm_error("SCO_DATA_MISMATCH", $sformatf("Addr: %0h | Expected: %0h | Actual: %0h (Beat %0d, Byte %0d)", exact_byte_addr, expected_byte, actual_byte, i, byte_idx))
                match_failed = 1;
            end
        end
        if(!match_failed) begin
            `uvm_info("SCO_PASS", $sformatf("Beat %0d passed", i), UVM_LOW)
        end
    end
    endfunction
endclass