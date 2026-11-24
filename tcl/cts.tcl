save_block -as ${NAME}_cts
open_block ${NAME}_cts

# Build, route and optimize the clock tree using FC's default CTS settings.
# Perform all three command at once:
# build_clock: Build and optimize the buffered clock tree
# route_clock: Detail-route the synthesized clock nets (routes the clock nets, not all the data/signal nets)
# final_optimization: Perform ***post-CTS STA***, placement and **global-route**-based optimization (so routing path will show up but without assigned width)
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

# Check placement congestion before investing in CTS and detailed routing
report_congestion -rerun_global_router > reports_fc/cts_congestion.rpt

# Because CTS can insert additional clock-tree cells.
connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

# Verify physical power connectivity
check_pg_connectivity -check_std_cell_pins all
check_pg_missing_vias
check_pg_drc

# check for design violations
check_clock_tree > reports_fc/check_clock_tree.rpt

# report CTS constraints (configurations)
# if max_transition, max_capacitance, target_skew, etc. not set before clock_opt, then FC uses default configuration
report_clock_settings -type configurations > reports_fc/cts_constraints.rpt

# checks the timing-analysis setup, including missing clocks, missing I/O constraints, and unconstrained endpoints
check_timing > reports_fc/postCTS_check_timing.rpt

# updated postCTS clock uncertainty constraint, remove clock skew part based on the postCTS timing report
# setup clock skew: ~0.13, but account for jitter: reduce from 0.13 to 0.05
# real jitter information need PLL/oscillator specification
# hold clock skew: ~0.04, so reduce from 0.07 to 0.03
set postcts_setup_uncertainty 0.05
set postcts_hold_uncertainty  0.03

foreach scenario {FUNC_SS FUNC_TT FUNC_FF} {
  set_clock_uncertainty -setup $postcts_setup_uncertainty [get_clocks CLK]
  set_clock_uncertainty -hold $postcts_hold_uncertainty [get_clocks CLK]
}

# update timing first before analyzing timing!
update_timing -full

# Analyze the design after clock implementation
foreach scenario {FUNC_SS FUNC_TT FUNC_FF} {
    current_scenario $scenario
    # Perform & report post-CTS STA
    report_timing -scenarios $scenario -delay_type max -max_paths 10 -transition_time > reports_fc/postCTS_${scenario}_setup.rpt
    report_timing -scenarios $scenario -delay_type min -max_paths 10 -transition_time -significant_digits 5 > reports_fc/postCTS_${scenario}_hold.rpt
}

# QoR stands for Quality of Results, show max clock latency indicating how well the clock tree was implemented
report_clock_qor -show_paths -largest 2 > reports_fc/cts_clock_qor.rpt

save_block
save_lib
