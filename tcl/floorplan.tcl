# This script runs after des_import.tcl and MMMC.tcl
# when Fusion Compiler already has your synthesized ALU netlist, technology definitions, cell libraries, and timing scenarios

save_block -as ${NAME}_floorplan
open_block ${NAME}_floorplan

# Core utilization is the ratio of the standard-cell area to the total core area
# The remaining space is needed for routing access, buffering, cell resizing, timing fixes, and other implementation changes.
# A lower utilization generally makes placement and routing easier, but increases area and can increase wire lengths.

# *******This value can be optimized via PPA analysis*********.

# -side_ratio {1 1}: defines the relative lengths of the two sides of the rectangular core (W: H).
# -core_offset 5: This is the spacing between the core boundary and the die boundary (5um).
initialize_floorplan -core_utilization 0.50 -side_ratio {1 1} -core_offset 5

# defining the layer range that FC should generally use for signal routing (soft routing constraints here, not absolute prohibitions)
# -min_routing_layer metal2: Set metal2 as the lower routing-layer limit
# -max_routing_layer metal6: Set metal6 as the upper routing-layer limit
# In many standard-cell technologies, metal1 is heavily used for local cell pin access and intra-cell interconnect.
set_ignored_layers -min_routing_layer metal2 -max_routing_layer metal6

# report relavant dimensions useful for power planning
report_design -floorplan > reports_fc/floorplan_info.rpt

save_block
save_lib
