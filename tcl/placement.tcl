# performs standard-cell placement and optimization

save_block -as ALU_TOP_placement
open_block ALU_TOP_placement

# Allow the library's tie-high/low cells to drive logic constants.Nangate marks these cells dont_use/dont_touch by default.
set tie_cells [get_lib_cells {*/LOGIC1_X1 */LOGIC0_X1}]
set_attribute $tie_cells dont_use false
set_attribute $tie_cells dont_touch false
# -include optimization	Permit their use in optimization operations
set_lib_cell_purpose -include optimization $tie_cells

# main placement-and-optimization command
place_opt

# Why place add_tie_cell after placement:
# 1. Placement optimization may restructure logic or introduce instances. 
#    Performing tie-cell insertion after that optimization ensures the remaining constant connections are handled.
# 2. Placement information is available, which helps the implementation account for physical locations
add_tie_cells -tie_high_lib_cells */LOGIC1_X1 -tie_low_lib_cells */LOGIC0_X1

# As discussed above, place_opt normally performs legalization as part of its flow.
# However, you subsequently run: add_tie_cells ... which inserts additional cells into the design.
# The placement is now different from what existed at the end of place_opt
# Legalization: adjusts cell positions to satisfy physical placement constraints
legalize_placement

# Detect remaining placement legality violations
# legalize_placement is a repair command: It attempts to fix illegal cell placements.
# check_legality is a verification command: It checks for placement violations but does not fix them.
check_legality

# reconnect VDD/VSS after placement, as place_opt and add_tie_cells can introduce new standard-cell instances
# But this command does not create new physical metal routes or vias!!!! so check connectivity
connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

# Verify physical power connectivity
# There's no need to regenerate all metal1 rails automatically each time placement adds a buffer or tie cell. 
# If the power rails already span the legal placement rows and the new cells are placed on those rows, their 
# PG pins should be able to connect to the existing rails. Regenerate or repair physical structures only when checks reveal a problem.
check_pg_connectivity -check_std_cell_pins all
check_pg_missing_vias
check_pg_drc

save_block
save_lib
