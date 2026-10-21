typedef enum bit [1:0] {AXI4_FIXED = 2'b00, AXI4_INCR = 2'b01, AXI4_WRAP = 2'b10} axi4_burst_e;
typedef enum bit       {AXI4_WRITE = 1'b0,  AXI4_READ  = 1'b1} axi4_dir_e;
typedef enum bit [1:0] {AXI4_OKAY = 2'b00, AXI4_EXOKAY = 2'b01,
                         AXI4_SLVERR = 2'b10, AXI4_DECERR = 2'b11} axi4_resp_e;

typedef enum {
    VIOL_NONE,
    VIOL_4KB_CROSS,
    VIOL_WRAP_BAD_LEN,
    VIOL_SIZE_TOO_LARGE,
    VIOL_WLAST_EARLY,
    VIOL_VALID_DROP
} axi4_violation_e;

class axi_transaction extends uvm_sequence_item;
    rand axi4_dir_e dir;
    rand bit [31:0] addr;
    rand bit [7:0] len;
    rand bit [2:0] size;
    rand axi4_burst_e burst;

    rand bit [63:0] wdata[];
    rand bit [3:0] wstrb[];

    bit [63:0] rdata[];
    bit [3:0] rstrb[];

    bit [1:0] resp;

    rand axi4_violation_e   inject_violation;

    static int unsigned bus_bytes = 8;

    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_array_int(wdata, UVM_ALL_ON)
        `uvm_field_array_int(rdata, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
        `uvm_field_int(len, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)
        `uvm_field_enum(axi4_dir_e, dir, UVM_ALL_ON)
        `uvm_field_enum(axi4_burst_e, burst, UVM_ALL_ON)
        `uvm_field_enum(axi4_violation_e, inject_violation, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_transaction");
    super.new(name);
    endfunction

    //=========================================================================
    // Shared address / byte-lane helpers. ONE implementation used by the
    // scoreboard, the slave driver, coverage and this class itself.
    // Static versions take raw fields (so callers that only have pin values,
    // like the slave driver, need no transaction object); the instance
    // wrappers below just forward this object's own fields.
    //=========================================================================

    // Address of beat i (0-based). Only beat 0 may be unaligned; later INCR
    // beats snap to the transfer-size grid. FIXED never moves. WRAP walks
    // inside its aligned container and wraps from the top back to the bottom.
    static function bit [31:0] calc_beat_addr(bit [31:0] addr, bit [7:0] len,
                                              bit [2:0] size, bit [1:0] burst,
                                              int unsigned i);
        int unsigned nb      = 1 << size;
        bit [31:0]   aligned = (addr >> size) << size;
        int unsigned total   = nb * (int'(len) + 1);
        bit [31:0]   lower;
        if (i == 0) return addr;
        case (burst)
            AXI4_FIXED: return addr;
            AXI4_WRAP: begin
                lower = (addr / total) * total;
                return lower + ((aligned - lower + i * nb) % total);
            end
            default: return aligned + i * nb;   // INCR
        endcase
    endfunction

    // Bit l set => data-bus byte lane l carries valid data in beat i.
    static function bit [7:0] calc_lane_mask(bit [31:0] addr, bit [7:0] len,
                                             bit [2:0] size, bit [1:0] burst,
                                             int unsigned i);
        int unsigned nb = 1 << size;
        bit [31:0]   a  = calc_beat_addr(addr, len, size, burst, i);
        bit [31:0]   aligned_a = (a >> size) << size;
        int unsigned lo = a % bus_bytes;
        int unsigned hi = (aligned_a % bus_bytes) + nb - 1;
        bit [31:0]   m;
        if (hi > bus_bytes - 1) hi = bus_bytes - 1;   // oversized AxSIZE: clamp to the bus
        m = ((32'd1 << (hi - lo + 1)) - 1) << lo;
        return m[7:0];
    endfunction

    // Memory byte address carried by lane `lane` of beat i.
    static function bit [31:0] calc_lane_byte_addr(bit [31:0] addr, bit [7:0] len,
                                                   bit [2:0] size, bit [1:0] burst,
                                                   int unsigned i, int unsigned lane);
        bit [31:0] a = calc_beat_addr(addr, len, size, burst, i);
        return (a / bus_bytes) * bus_bytes + lane;
    endfunction

    // Unaligned = start address not a multiple of the TRANSFER size
    // (not of the bus width).
    static function bit calc_is_unaligned(bit [31:0] addr, bit [2:0] size);
        return (addr & ((32'd1 << size) - 1)) != 0;
    endfunction

    // INCR bursts only: FIXED never advances and WRAP stays inside its
    // container, so neither can cross a 4KB page. Uses the ALIGNED start
    // (a legal unaligned start inside the last beat's window must not count).
    static function bit calc_crosses_4kb(bit [31:0] addr, bit [7:0] len,
                                         bit [2:0] size, bit [1:0] burst);
        int unsigned off, bytes;
        if (burst != AXI4_INCR) return 0;
        off   = ((addr[11:0] >> size) << size);
        bytes = ((int'(len) + 1) << size);
        return (off + bytes) > 4096;
    endfunction

    //constraint valid_addr_range {addr inside {[0:128]};}
    //constraint addr_distribution {addr dist{[0:32] :/ 30, [33:64] :/ 20, [65:96] :/ 20, [97:127] :/ 25, 128 :/ 5};}
    constraint valid_data_range {
        foreach (wdata[i]) {
            wdata[i] inside {[64'h0000_0000_0000_0000 : 64'hFFFF_FFFF_FFFF_FFFF]};
        }
        foreach (rdata[i]) {
            rdata[i] inside {[64'h0000_0000_0000_0000 : 64'hFFFF_FFFF_FFFF_FFFF]};
        }
    }

    constraint viol_dist{
        inject_violation dist{
            VIOL_NONE := 25,
            VIOL_4KB_CROSS := 15,
            VIOL_WRAP_BAD_LEN := 15,
            VIOL_SIZE_TOO_LARGE := 15,
            VIOL_WLAST_EARLY := 15,
            VIOL_VALID_DROP := 15
        };
    }

    constraint data_distribution {
        foreach (wdata[i]) {
            wdata[i] dist{64'h0000_0000_0000_0000 := 2,
        64'hFFFF_FFFF_FFFF_FFFF := 2,
        64'hAAAA_AAAA_AAAA_AAAA := 2,
        64'h5555_5555_5555_5555 := 2,
        64'h0000_00FF_0000_00FF := 2,
        64'hFF00_0000_FF00_0000 := 2,
        64'h0000_FFFF_FFFF_FFFF := 2,
        [64'h0000_0100_0000_0100:64'h0000_0000_0000_FFFE] :/ 25,
        [64'h0001_0000_0000_0000:64'hFFFE_FFFE_FFFE_FFFF] :/ 36,
        [64'hFFFF_0000_0000_0000:64'hFFFF_FFFF_FFFF_FFFE] :/ 25};
        }
        
        foreach (rdata[i]) {
        rdata[i] dist{64'h0000_0000_0000_0000 := 2,
        64'hFFFF_FFFF_FFFF_FFFF := 2,
        64'hAAAA_AAAA_AAAA_AAAA := 2,
        64'h5555_5555_5555_5555 := 2,
        64'h0000_00FF_0000_00FF := 2,
        64'hFF00_0000_FF00_0000 := 2,
        64'h0000_FFFF_FFFF_FFFF := 2,
        [64'h0000_0100_0000_0100:64'h0000_0000_0000_FFFE] :/ 25,
        [64'h0001_0000_0000_0000:64'hFFFE_FFFE_FFFE_FFFF] :/ 36,
        [64'hFFFF_0000_0000_0000:64'hFFFF_FFFF_FFFF_FFFE] :/ 25};
        }
    }

    constraint c_burst_length{
        wdata.size() inside {[0:(len + 1)]};
        wstrb.size() inside {[0:(len + 1)]};
    }

    /*constraint c_default_legal {
        soft inject_violation == VIOL_NONE;
    }

    constraint c_fixed_len_reasonable {
        burst == AXI4_FIXED -> len inside {[0:15]};
    }

    constraint c_addr_default_aligned {
        soft addr[2:0] == 3'b000;
    }

    constraint c_data_size {
        wdata.size() == len + 1;
        wstrb.size() == len + 1;
    }*/
    
    constraint c_max_burst_weight {
        burst == AXI4_INCR -> len dist {[0:14] :/ 50, [15:254] :/ 30, 255 :/ 20};
        burst == AXI4_WRAP -> len dist {[0:14] :/ 50, [15:254] :/ 50};
    }

    constraint c_burst_dist {
        burst dist {AXI4_FIXED := 20, AXI4_INCR := 40, AXI4_WRAP := 40};
    }

    constraint c_viol_link {
        if(inject_violation inside {VIOL_NONE, VIOL_WLAST_EARLY, VIOL_VALID_DROP}) {
            (1 << size) <= bus_bytes;
            (burst == AXI4_WRAP) -> len inside {1, 3, 7, 15};
            (burst == AXI4_WRAP) -> ((addr & ((1 << size) - 1)) == 0);  // WRAP start must be aligned
            (burst == AXI4_INCR) ->
                (((int'(addr[11:0]) >> size) << size) + ((int'(len) + 1) << size)) <= 4096;
        }

        if(inject_violation == VIOL_4KB_CROSS){
            burst == AXI4_INCR;
            (1 << size) <= bus_bytes;
            (((int'(addr[11:0]) >> size) << size) + ((int'(len) + 1) << size)) > 4096;
        }
        if (inject_violation == VIOL_WRAP_BAD_LEN) {
            burst == AXI4_WRAP;
            !(len inside {1, 3, 7, 15});
            (1 << size) <= bus_bytes;
            ((addr & ((1 << size) - 1)) == 0);
        }
        if (inject_violation == VIOL_SIZE_TOO_LARGE) {
            (1 << size) > bus_bytes;
            burst == AXI4_INCR;
            (((int'(addr[11:0]) >> size) << size) + ((int'(len) + 1) << size)) <= 4096;
        }
        // Pin-level: just make sure the fields allow the misbehavior
        if (inject_violation == VIOL_WLAST_EARLY) { dir == AXI4_WRITE; len > 0; }
        if (inject_violation == VIOL_VALID_DROP)  { dir == AXI4_WRITE; }
    }

    // ---- instance wrappers (forward this object's own fields) ----
    function bit [31:0] beat_addr(int unsigned i);
        return calc_beat_addr(addr, len, size, burst, i);
    endfunction
    function bit [7:0] lane_mask(int unsigned i);
        return calc_lane_mask(addr, len, size, burst, i);
    endfunction
    function bit [31:0] lane_byte_addr(int unsigned i, int unsigned lane);
        return calc_lane_byte_addr(addr, len, size, burst, i, lane);
    endfunction
    function bit is_unaligned();
        return calc_is_unaligned(addr, size);
    endfunction
    function bit crosses_4kb();
        return calc_crosses_4kb(addr, len, size, burst);
    endfunction

    function int unsigned burst_bytes();
        return (len + 1) * (1 << size);
    endfunction

    function string convert2string();
        return $sformatf("dir=%s addr=0x%08h len=%0d size=%0d burst=%s viol=%s", dir.name(), addr, len, size, burst.name(), inject_violation.name());
    endfunction

    function axi4_violation_e classify();
        if (size > 3) return VIOL_SIZE_TOO_LARGE;
        if (burst == AXI4_WRAP && !(len inside {1, 3, 7, 15})) return VIOL_WRAP_BAD_LEN;
        if (burst == AXI4_INCR &&
            (((int'(addr[11:0]) >> size) << size) + ((int'(len) + 1) << size)) > 4096) return VIOL_4KB_CROSS;
        return VIOL_NONE;   // field-level view only; pin-level violations aren't visible here
    endfunction

    function void post_randomize();
        axi4_violation_e c;
        // Strobes may only be set on lanes that carry valid data in that beat.
        // Done here (not as a constraint) because the lane mask depends on
        // addr/size/burst, which are being solved in the same call.
        foreach (wstrb[i]) wstrb[i] &= lane_mask(i);
        if (inject_violation inside {VIOL_NONE, VIOL_4KB_CROSS, VIOL_WRAP_BAD_LEN, VIOL_SIZE_TOO_LARGE, VIOL_WLAST_EARLY, VIOL_VALID_DROP}
            && c != inject_violation) begin
            c = classify();
            if(c != inject_violation) begin
                `uvm_error("TXN", $sformatf("label %s but fields classify as %s", inject_violation.name(), c.name()))
            end
        end
    endfunction
endclass