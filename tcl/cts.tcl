save_block -as ALU_TOP_cts
open_block ALU_TOP_cts

# Build, route and optimize the clock tree using FC's default CTS settings.
# Perform all three command at once:
# build_clock: Build and optimize the buffered clock tree
# route_clock: Detail-route the synthesized clock nets (routes the clock nets, not all the data/signal nets)
# final_optimization: Perform post-CTS timing, placement and global-route-based optimization (so routing path will show up but without assigned width)
clock_opt

# What is CTS trying to optimize?
# The three main clock-tree metrics are:
# - Insertion delay (clock latency): Time for the clock to travel from its defined source to a register's clock pin.
# - Clock skew: Difference between clock arrival times at different register clock pins.
# - Clock transition: How quickly the clock voltage changes between logic levels.

# There are two ways STA can model a clock network.
# Ideal clock: Clock distribution delay is modeled using ideal-clock assumptions, 
# rather than tracing a physically implemented clock tree.
# Propagated clock: The timing engine calculates clock arrival times through the actual clock buffers and interconnect, 
# using the available parasitic estimates or extracted parasitics.
# clock_opt automatically marks the synthesized clocks as propagated in the active scenarios

# foreach scenario {FUNC_SS FUNC_TT FUNC_FF} {
#     current_scenario $scenario
#     set_propagated_clock [all_clocks]
# }

# Because CTS can insert additional clock-tree cells.
connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

# Verify physical power connectivity
check_pg_connectivity -check_std_cell_pins all
check_pg_missing_vias
check_pg_drc

# check for design violations
check_clock_tree > reports_fc/check_clock_tree.rpt

# QoR stands for Quality of Results. This command summarizes how well the clock tree was implemented.
report_clock_qor -show_paths -largest 2 > reports_fc/cts_clock_qor.rpt

# report CTS constraints (configurations)
# if max_transition, max_capacitance, target_skew, etc. not set before clock_opt, then use default configuration
report_clock_settings -type configurations

save_block
save_lib
