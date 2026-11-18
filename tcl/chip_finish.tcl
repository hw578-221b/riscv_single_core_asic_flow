save_block -as ALU_TOP_finished
open_block ALU_TOP_finished

# Fill unused row space, largest filler first. This is not metal-density fill.
create_stdcell_fillers -lib_cells {
    */FILLCELL_X32 */FILLCELL_X16 */FILLCELL_X8
    */FILLCELL_X4 */FILLCELL_X2 */FILLCELL_X1
}
connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

redirect -file reports_fc/final_legality.rpt { check_legality }
redirect -file reports_fc/final_pg_drc.rpt { check_pg_drc }
redirect -file reports_fc/final_pg_connectivity.rpt { check_pg_connectivity }
redirect -file reports_fc/final_pg_via.rpt { check_pg_missing_vias }
# Layout Versus Schematic (LVS) verification
# It searches for electrical connectivity errors such as shorts (unintended wire connections),
# opens (broken or missing connections), and floating routes
redirect -file reports_fc/final_lvs.rpt { check_lvs }

save_block
save_lib
