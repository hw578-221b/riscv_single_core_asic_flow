# Three CELL timing corners, using the actual Nangate library PVT values.
# The kit has ONE RC technology file. It is reused, not relabeled as RCmin/RCmax.

# Reset existing MCMM configuration
remove_scenarios -all
remove_modes -all
remove_corners -all

# Mode: How the circuit operates, like FUNC: Normal operation; SCAN: Scan-shift testing, LOW_POWER: Reduced-frequency operation
# Corner: Under what physical and environmental conditions it operates (PVT + interconnect RC conditions)
# Scenario: One specific combination of mode and corner used for timing analysis and optimization.

# One available interconnect RC model (typical)
read_parasitic_tech -name RC_TYP \
    -tlup std_cells/NangateOpenCellLibrary.tlup \
    -layermap std_cells/NangateOpenCellLibrary.layermap

# One functional mode
create_mode FUNC

# SS: slow cells, 0.95 V, 125 C.
create_corner SS
create_scenario -name FUNC_SS -mode FUNC -corner SS
current_scenario FUNC_SS
# must agree with the definition
set_process_number 1
set_voltage 0.95
set_temperature 125

# TT: typical cells, 1.10 V, 25 C.
create_corner TT
create_scenario -name FUNC_TT -mode FUNC -corner TT
current_scenario FUNC_TT
set_process_number 1
set_voltage 1.10
set_temperature 25

# FF: fast cells, 1.25 V, 0 C (not -40 C for this library).
create_corner FF
create_scenario -name FUNC_FF -mode FUNC -corner FF
current_scenario FUNC_FF
set_process_number 1
set_voltage 1.25 
set_temperature 0

# Exploratory assumption: 0.1 transitions per clock cycle,
# with each functional input high for 50% of the interval.
set activity_inputs \
    [remove_from_collection [all_inputs] [get_ports {clk reset}]]

# The same functional constraints apply to all three scenarios.
foreach scenario {FUNC_SS FUNC_TT FUNC_FF} {
    current_scenario $scenario
    set_parasitic_parameters -early_spec RC_TYP -late_spec RC_TYP
    source constraints.tcl

    # Configure for basic dynamic power estimate
    # Static probability: Fraction of time at logic 1
    # Toggle rate: Number of transitions per clock period, counting both rising and falling transitions
    set_switching_activity -static_probability 0.5 -toggle_rate 0.1 -base_clock CLK $activity_inputs
    # Active-high reset remains deasserted during normal execution.
    set_switching_activity -static_probability 0.0 -toggle_rate 0.0 [get_ports reset]

    # this command does not run any analysis itself, it only configures which corners/modes are visible, while the report_* does the full analysis & reporting.
    # syntax: set_scenario_status <scenario_name> <analysis_options>
    # -active true: Enable the scenario's selected analysis/optimization
    # for example: -leakage_power true: Enable leakage-power analysis
    set_scenario_status $scenario -active true -setup true -hold true -leakage_power true -dynamic_power true
}

current_scenario FUNC_SS
report_scenarios > reports_fc/scenarios.rpt
