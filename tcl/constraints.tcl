# Shared by DC and FC. Time = ns; capacitance = fF in this Nangate library.
# Assumed 0ns clock network latency (from source to ff), will be addressed after CTS
set clk_period 3.5
create_clock -name CLK -period $clk_period [get_ports clk]
# get_clocks get the clock object named CLK
# initial allowance for pre-CTS skew budgeting
set_clock_uncertainty -setup 0.13 [get_clocks CLK]
set_clock_uncertainty -hold 0.07 [get_clocks CLK]
# assumption before CTS
set_clock_transition 0.05 [get_clocks CLK]

# Synchronous reset	    Treat as a data input; setup/hold checks apply
# Asynchronous reset	Check recovery/removal and minimum pulse width as appropriate; reset assertion and release require special consideration
# clk is modeled differently from data inputs (set_clock commands above), so exclude from here (but rst is included)
set data_inputs [remove_from_collection [all_inputs] [get_ports clk]]

# delay relative to the clk, the -clock option accepts a clock name, so CLK is sufficient.
# not scenario specific I/O delay constraint (-min doesn't mean FF scenario)
set_input_delay -max [expr 0.2*$clk_period] -clock CLK $data_inputs
set_input_delay -min 0.1 -clock CLK $data_inputs

set_output_delay -max [expr 0.2*$clk_period] -clock CLK [all_outputs]
# receiving register requires 2 ns hold time (assume board wire has zero delay), notice it's -2!!!
set_output_delay -min -0.1 -clock CLK [all_outputs]

# set driving cell for data input ports (not clk port)
# pin Z is the driving cell's output pin

# Suppose, using illustrative numbers rather than your library’s actual values:
# - The internal gates and wiring present a load of 80 fF.
# - The buffer’s timing tables predict an output transition of 0.15 ns at that load.
# - The buffer has a maximum allowed load of 50 fF.
# if don't set -no_design_rule, then DC will import driver's 50 fF maximum-load limit to input ports
# and treat 80fF as violating the imported limit, DC may add addtional buffers inside the design
# Choose the default when the driver is a real interface requirement
# Choose -no_design_rule when the cell is only a representative slew model and interface limits are specified separately
set_driving_cell -lib_cell BUF_X2 -pin Z -no_design_rule $data_inputs
# set load capacitance for output ports (10 fF)
set_load 10 [all_outputs]

# No need to set_wire_load_model, use the default model in the library
# operating condition will be set in MMMC scripts
