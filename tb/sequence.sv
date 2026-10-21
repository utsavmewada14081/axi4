class axi_sequence extends uvm_sequence #(axi_transaction);
`uvm_object_utils(axi_sequence)
`uvm_declare_p_sequencer(axi_virtual_sequencer)

function new(string name = "axi_sequence");
super.new(name);
endfunction

int count = 0;

virtual task pre_body();
uvm_phase phase = starting_phase;
if(starting_phase != null)
starting_phase.raise_objection(this);
endtask

virtual task body();
fork
    repeat(100) begin
        axi_transaction wr_tr;
        wr_tr = axi_transaction::type_id::create("wr_tr");
        assert(wr_tr.randomize()) else begin
        `uvm_error(get_type_name, "Randomization failed")
        end
        start_item(wr_tr, -1, p_sequencer.wr_sequencer);
        `uvm_info(get_type_name(), $sformatf("[GEN]: awaddr: %0h, awsize: %3b, awlen: %8b, awburst: %2b, wstrb: %0p, wdata: %0p", wr_tr.addr, wr_tr.size, wr_tr.len, wr_tr.burst, wr_tr.wstrb, wr_tr.wdata), UVM_MEDIUM)
        finish_item(wr_tr);
    end
    repeat(100) begin
        axi_transaction rd_tr;
        rd_tr = axi_transaction::type_id::create("rd_tr");
        assert(rd_tr.randomize()) else begin
            `uvm_error(get_type_name, "Randomization failed")
        end
        start_item(rd_tr, -1, p_sequencer.rd_sequencer);
        `uvm_info(get_type_name(), $sformatf("[GEN]: araddr: %0h, arsize: %3b, arlen: %8b, arburst: %2b", rd_tr.addr, rd_tr.size, rd_tr.len, rd_tr.burst), UVM_MEDIUM)
        finish_item(rd_tr);
    end
join

endtask

virtual task post_body();
uvm_phase phase = starting_phase;
if(starting_phase != null)
starting_phase.drop_objection(this);
endtask
endclass

class read_after_write_seq extends uvm_sequence;
  `uvm_object_utils(read_after_write_seq)
  `uvm_declare_p_sequencer(axi_virtual_sequencer) // Replace with your actual p_sequencer type

  function new(string name = "read_after_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi_transaction wr_tr;
    axi_transaction rd_tr;

    // Loop to test multiple random configurations
    repeat (200) begin
      
      // --------------------------------------------------------
      // 1. Execute the Write Transaction
      // --------------------------------------------------------
      wr_tr = axi_transaction::type_id::create("wr_tr");
      
      start_item(wr_tr, -1, p_sequencer.wr_sequencer);
      
      assert(wr_tr.randomize()/* with {
        wr_tr.inject_violation == VIOL_NONE; // Ensure no violation is injected for the write
      }*/
      with{
        wr_tr.dir == AXI4_WRITE; // Ensure the direction is set to WRITE
      }) else begin
        `uvm_error(get_type_name(), "Write transaction randomization failed")
      end
      
      `uvm_info(get_type_name(), $sformatf("[GEN] WRITE -> Addr: %0h | Len: %0d | Size: %0d | Burst: %0b | VIOL: %s", 
                wr_tr.addr, wr_tr.len, wr_tr.size, wr_tr.burst, wr_tr.inject_violation.name()), UVM_MEDIUM)
      
      // Blocks until the entire write burst completes on the bus
      finish_item(wr_tr); 

      // --------------------------------------------------------
      // 2. Execute the Read Transaction (Constrained to match)
      // --------------------------------------------------------
      rd_tr = axi_transaction::type_id::create("rd_tr");
      
      start_item(rd_tr, -1, p_sequencer.rd_sequencer);
      
      // The 'with' block forces the randomizer to match the write's variables
      assert (rd_tr.randomize() /*with {
        rd_tr.inject_violation == VIOL_NONE; // Ensure no violation is injected for the read
        addr  == wr_tr.addr;
        len   == wr_tr.len;
        size  == wr_tr.size;
        burst == wr_tr.burst;
      }*/
      with{
        rd_tr.dir == AXI4_READ; // Ensure the direction is set to READ
      }) else begin
        `uvm_error(get_type_name(), "Read inline constraint failed")
      end
      
      `uvm_info(get_type_name(), $sformatf("[GEN] READ  -> Addr: %0h | Len: %0d | Size: %0d | Burst: %0b | VIOL: %s", 
                rd_tr.addr, rd_tr.len, rd_tr.size, rd_tr.burst, rd_tr.inject_violation.name()), UVM_MEDIUM)
      
      // Blocks until the read burst completes
      finish_item(rd_tr);
      
    end
  endtask
endclass