# Shared by DC and FC. Time = ns; capacitance = fF in this Nangate library.
# Keep the lab's 100 ns clock and 20 ns I/O timing budget.
# Assumed 0ns clock network latency (from source to ff), will be addressed after CTS
create_clock -name CLK -period 100 [get_ports CLK]
# get_clocks get the clock object named CLK
set_clock_uncertainty -setup 0.2 [get_clocks CLK]
set_clock_uncertainty -hold 0.1 [get_clocks CLK]
set_clock_transition 0.05 [get_clocks CLK]

# RST is included: this lab models reset release as a timed input too.
# Synchronous reset	    Treat as a data input; setup/hold checks apply
# Asynchronous reset	Check recovery/removal and minimum pulse width as appropriate; reset assertion and release require special consideration
# clk is modeled differently from data inputs (set_clock commands above), so exclude from here
set data_inputs [remove_from_collection [all_inputs] [get_ports CLK]]

# delay relative to the clk, the -clock option accepts a clock name, so CLK is sufficient.
# not scenario specific I/O delay constraint (-min doesn't mean FF scenario)
set_input_delay -max 20 -clock CLK $data_inputs
set_input_delay -min 2 -clock CLK $data_inputs

set_output_delay -max 20 -clock CLK [all_outputs]
# receiving register requires 2 ns hold time (assume board wire has zero delay)
# notice it's -2!!!
set_output_delay -min -2 -clock CLK [all_outputs]

set_driving_cell -lib_cell BUF_X2 -pin Z $data_inputs
# Learning assumption: 10 fF = 0.01 pF per output, instead of the old 75 pF.
set_load 10 [all_outputs]

# No need to set _wire_load_model, use the default model in the library
