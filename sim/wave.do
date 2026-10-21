onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axi_tb_top_no_dut/vif/clk
add wave -noupdate /axi_tb_top_no_dut/vif/rst_n
add wave -noupdate /axi_tb_top_no_dut/vif/awready
add wave -noupdate /axi_tb_top_no_dut/vif/awvalid
add wave -noupdate /axi_tb_top_no_dut/vif/awaddr
add wave -noupdate /axi_tb_top_no_dut/vif/awlen
add wave -noupdate /axi_tb_top_no_dut/vif/awsize
add wave -noupdate /axi_tb_top_no_dut/vif/awburst
add wave -noupdate /axi_tb_top_no_dut/vif/wready
add wave -noupdate /axi_tb_top_no_dut/vif/wvalid
add wave -noupdate /axi_tb_top_no_dut/vif/wdata
add wave -noupdate /axi_tb_top_no_dut/vif/wstrb
add wave -noupdate /axi_tb_top_no_dut/vif/wlast
add wave -noupdate /axi_tb_top_no_dut/vif/bready
add wave -noupdate /axi_tb_top_no_dut/vif/bvalid
add wave -noupdate /axi_tb_top_no_dut/vif/bresp
add wave -noupdate /axi_tb_top_no_dut/vif/arready
add wave -noupdate /axi_tb_top_no_dut/vif/arvalid
add wave -noupdate /axi_tb_top_no_dut/vif/araddr
add wave -noupdate /axi_tb_top_no_dut/vif/arlen
add wave -noupdate /axi_tb_top_no_dut/vif/arsize
add wave -noupdate /axi_tb_top_no_dut/vif/arburst
add wave -noupdate /axi_tb_top_no_dut/vif/rready
add wave -noupdate /axi_tb_top_no_dut/vif/rvalid
add wave -noupdate /axi_tb_top_no_dut/vif/rdata
add wave -noupdate /axi_tb_top_no_dut/vif/rresp
add wave -noupdate /axi_tb_top_no_dut/vif/rlast
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 361
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {520 ns} {826 ns}
