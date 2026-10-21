//=============================================================================
// axi4_slave_driver.sv
// Reactive responder -- never calls start_item/finish_item, since a slave
// doesn't initiate anything. It just watches the request channels (via
// slv_cb, sampled) and drives the ready/response side (also via slv_cb,
// driven), servicing writes into an internal memory model and reads back
// out of it. This is what lets the VIP run "master vs. slave, no real DUT"
// for bring-up or VIP self-test.
//
// Architecturally this mirrors axi4_dummy_slave.sv's RTL behavior, but as
// a class-based UVM component so it's config-driven the same way the
// master driver is (ready delays, response codes, error injection) instead
// of being a fixed always-OKAY RTL stub.
//=============================================================================
class axi_slave_driver extends uvm_component;
    `uvm_component_utils(axi_slave_driver)

    virtual axi_if vif;
    axi_config cfg;

    bit [7:0] mem[bit [31:0]];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("SLVDRV", "axi_config not set")
        vif = cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        drive_idle_defaults();
        wait_reset_done();
        fork
            write_responder();
            read_responder();
        join
    endtask

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

    task drive_idle_defaults();
        vif.slv_cb.awready <= 1'b0;
        vif.slv_cb.wready  <= 1'b0;
        vif.slv_cb.bvalid  <= 1'b0;
        vif.slv_cb.bresp   <= 2'b00;
        vif.slv_cb.arready <= 1'b0;
        vif.slv_cb.rvalid  <= 1'b0;
        vif.slv_cb.rlast   <= 1'b0;
    endtask

    task wait_reset_done();
        @(posedge vif.rst_n);
        @(vif.slv_cb);
`uvm_info("SLVDRV", "reset done, starting responders", UVM_LOW)

    endtask

    //-------------------------------------------------------------------
    // Write responder: accept one AW beat, accept LEN+1 W beats writing
    // into mem[], then issue one B response.
    //-------------------------------------------------------------------
    task write_responder();
        forever begin
            bit [31:0] addr;
            bit [7:0]  len;
            bit [2:0]  size;
            bit [1:0]  burst;
            int unsigned d, bpb;

            // ---- accept AW ----
            @(vif.slv_cb);
            vif.slv_cb.awready <= 1'b1;
            `uvm_info("SLVDRV", "waiting for AWVALID", UVM_LOW)
            do @(vif.slv_cb); while (!vif.slv_cb.awvalid);
            addr  = vif.slv_cb.awaddr;
            len   = vif.slv_cb.awlen;
            size  = vif.slv_cb.awsize;
            burst = vif.slv_cb.awburst;
            vif.slv_cb.awready <= 1'b0;

            // ---- accept W beats ----
            bpb = 1 << size;

            // 1. Assert wready ONCE before the burst begins

            for (int i = 0; i <= len; i++) begin
                bit [31:0] current_beat_addr;
                
                vif.slv_cb.wready <= 1'b1; 
                // 2. Synchronous wait for valid data
                do begin
                    @(vif.slv_cb); 
                end while (!vif.slv_cb.wvalid);
                
                // 3. Calculate exact address using the shared function
                current_beat_addr = get_beat_addr(addr, len, size, burst, i);
                
                // 4. Map the valid strobes to the memory
                for (int b = 0; b < bpb; b++) begin
                    if (vif.slv_cb.wstrb[b] == 1'b1) begin
                        bit [31:0] exact_byte_addr = current_beat_addr + b;
                        mem[exact_byte_addr] = vif.slv_cb.wdata[b*8 +: 8];
                    end
                end
            end

            // 5. De-assert wready immediately after the final beat
            vif.slv_cb.wready <= 1'b0;

            // ---- issue B ----
            vif.slv_cb.bresp  <= pick_resp();
            `uvm_info("SLVDRV", $sformatf("write complete, issuing BRESP=%2b", vif.slv_cb.bresp), UVM_LOW)
            vif.slv_cb.bvalid <= 1'b1;
            do @(vif.slv_cb); while (!vif.slv_cb.bready);
            vif.slv_cb.bvalid <= 1'b0;
        end
    endtask

    //-------------------------------------------------------------------
    // Read responder: accept one AR beat, then drive LEN+1 R beats read
    // back out of mem[], asserting RLAST on the final beat.
    //-------------------------------------------------------------------
    task read_responder();
        forever begin
            bit [31:0] addr;
            bit [7:0]  len;
            bit [2:0]  size;
            bit [1:0]  burst;
            int unsigned d, bpb;

            @(vif.slv_cb);
            vif.slv_cb.arready <= 1'b1;
            do @(vif.slv_cb); while (!vif.slv_cb.arvalid);
            addr  = vif.slv_cb.araddr;
            len   = vif.slv_cb.arlen;
            size  = vif.slv_cb.arsize;
            burst = vif.slv_cb.arburst;
            vif.slv_cb.arready <= 1'b0;

            bpb = 1 << size;
            for (int i = 0; i <= len; i++) begin
                bit [31:0] current_beat_addr;
                bit [63:0] beat_data;
                beat_data = '0;

                current_beat_addr = get_beat_addr(addr, len, size, burst, i);
                for (int b = 0; b < bpb; b++) begin
                    bit [31:0] exact_byte_addr = current_beat_addr + b;
                    beat_data[b*8 +: 8] = mem.exists(exact_byte_addr) ? mem[exact_byte_addr] : 8'h00;
                end

                vif.slv_cb.rdata  <= beat_data;
                vif.slv_cb.rresp  <= pick_resp();
                vif.slv_cb.rlast  <= (i == len);
                vif.slv_cb.rvalid <= 1'b1;
                do @(vif.slv_cb); while (!vif.slv_cb.rready);
                vif.slv_cb.rvalid <= 1'b0;
                vif.slv_cb.rlast  <= 1'b0;
            end
        end
    endtask

    function bit [1:0] pick_resp();
        if (cfg.slave_error_inject_enable && $urandom_range(99, 0) < cfg.slave_error_inject_pct)
            return 2'b10; // SLVERR
        return 2'b00;     // OKAY
    endfunction
endclass