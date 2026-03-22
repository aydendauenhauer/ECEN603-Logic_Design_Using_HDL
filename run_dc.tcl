set link_library {* lsi_10k.db dw_foundation.sldb}
set target_library {lsi_10k.db}

define_design_lib WORK -path ./work

analyze -format verilog {router_top.v fifo_sync.v packet_register.v dest_decode.v router_fsm.v output_block.v}
elaborate router_top
link
check_design

create_clock -name clk -period 12.5 [get_ports clk]

compile

report_area > area.rpt
report_timing -path full -delay max -max_paths 1 > timing.rpt
check_design > check_design.rpt

quit
