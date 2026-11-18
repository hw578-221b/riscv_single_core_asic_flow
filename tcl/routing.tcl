# This script is the final signal-routing and post-route optimization stage

save_block -as ALU_TOP_routed
open_block ALU_TOP_routed

# builds the detailed signal interconnect
route_auto

# post-route timing and physical optimization:
# Cell resizing	     Replace a weak driver with a stronger cell to improve delay
# Buffer insertion	 Improve slow or high-capacitance nets
# Hold repair	     Insert delay or otherwise adjust short paths
# Cell relocation	 Move cells to improve timing or routing
# DRC-related repair Resolve remaining physical routing violations
route_opt

connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

# Verify physical power connectivity
check_pg_connectivity -check_std_cell_pins all
check_pg_missing_vias
check_pg_drc

# checks the routing result for physical routing problems, not full foundry signoff DRC or LVS check
check_routes > reports_fc/final_routes.rpt

save_block
save_lib
