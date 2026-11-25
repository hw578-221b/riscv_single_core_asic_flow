# Preserve the existing implementation.
save_block -as SingleCoreSys_hold_fix
open_block SingleCoreSys_hold_fix

mkdir reports_fc/report_fix
set PATH1 reports_fc/report_fix

set hold_endpoints [get_pins {
    dcache/dpath/memresp_data_reg/q_reg_45_/D
    dcache/dpath/memresp_data_reg/q_reg_46_/D
}]

set_route_opt_target_endpoints -hold_endpoints_collection $hold_endpoints

route_opt
update_timing -full

foreach scenario {FUNC_SS FUNC_TT FUNC_FF} {
    current_scenario $scenario

    # Perform & report post-routing STA, those two commands also need -scenarios $scenario to get scenario specific analysis!!
    report_timing -scenarios $scenario -delay_type max -max_paths 10 -transition_time -significant_digits 5 > ${PATH1}/${scenario}_setup.rpt
    report_timing -scenarios $scenario -delay_type min -max_paths 10 -transition_time -significant_digits 5 > ${PATH1}/${scenario}_hold.rpt

    report_constraints -all_violators > ${PATH1}/${scenario}_violations.rpt
}

# this fix doesn't work, the two hold violations still there after optimizing
