# first pass fix for 70% core utilization

save_block -as SingleCoreSys_hold_fix2
open_block SingleCoreSys_hold_fix2

file mkdir reports_fc/report_fix
set PATH1 reports_fc/report_fix

set buf_cell [get_cells eco_cell_5_0]
if {[sizeof_collection $buf_cell] != 1} {
    error "Resolve more than 1 buffer cell instance"
}

size_cell -lib_cell */BUF_X2 $buf_cell

# handles placement/legalization of cells involved in an ECO
# -legalize_only: snap cells onto valid placement, sites near their current location, skip global placement or timing/wirelength optimization, typical in hold time fix
place_eco_cells -cells $buf_cell -legalize_only

# performs incremental routing to implement the ECO connections
route_eco

update_timing -full

connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

check_legality
check_routes > ${PATH1}/route_check.rpt

check_pg_connectivity -check_std_cell_pins all
check_pg_missing_vias
check_pg_drc

foreach scenario {FUNC_SS FUNC_TT FUNC_FF} {
    current_scenario $scenario

    # Perform & report post-routing STA, those two commands also need -scenarios $scenario to get scenario specific analysis!!
    report_timing -scenarios $scenario -delay_type max -max_paths 10 -transition_time -significant_digits 5 > ${PATH1}/${scenario}_setup.rpt
    report_timing -scenarios $scenario -delay_type min -max_paths 10 -transition_time -significant_digits 5 > ${PATH1}/${scenario}_hold.rpt

    report_constraints -all_violators > ${PATH1}/${scenario}_violations.rpt
}

save_block
save_lib

# check if cell resizing succeeded or not by running: should return "BUF_X2"
# get_attribute [get_cells eco_cell_5_0] ref_name

# Run these command to retrieve the eco-fixed path
# report_timing -scenarios FUNC_FF -delay_type min \
#     -to [get_ports "icache_miss"] -significant_digits 5 >> ${PATH1}/FUNC_FF_eco_hold_path.rpt

# report_timing -scenarios FUNC_SS -delay_type max \
#     -to [get_ports "icache_miss"] -significant_digits 5 >> ${PATH1}/FUNC_SS_eco_setup_path.rpt
