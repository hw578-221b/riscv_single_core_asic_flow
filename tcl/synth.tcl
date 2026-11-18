# Run in Design Compiler, from this folder: dc_shell -f synth.tcl
# Re-synthesize the ALU: the old lab's mapped netlist uses different cells.
if {![file exists std_cells/NangateOpenCellLibrary_slow.db]} {
    error "First run: lc_shell -f build_libs.tcl"
}

# Set and access working directory
set PROJECT_DIR /home/hwang/EDA/projects/Lab_PnR_Synopsys_Simp
cd $PROJECT_DIR

# creates three directories relative to DC's working directory
file mkdir work_dc syn reports_dc
define_design_lib WORK -path ./work_dc

lappend search_path $PROJECT_DIR/std_cells
lappend search_path $PROJECT_DIR/rtl

# Map at SS. FC will later analyze the result at SS, TT and FF.
# Synthesize using the slow-corner standard-cell library. This DC run performs single-corner optimization.
# In Fusion Compiler, configure SS/TT/FF MMMC scenarios before placement and physical optimization.
# Check timing throughout PnR optimization and perform post-route multi-corner STA with extracted parasitics.

# Synthesis normally prioritizes setup optimization, while hold repair is commonly performed during and after CTS. Reasons:
# Before CTS, the actual clock skew is unknown. After CTS, positive skew could introduce hold violations even if the synthesis-stage hold check passed.
# Also, hold timing is usually easier to repair physically by adding delay cells or buffers, whereas fixing setup timing may require restructuring the combinational logic.
set target_library [list NangateOpenCellLibrary_slow.db]

# concat is a Tcl command that concatenates lists, producing one flat list of elements.
# if target library consist of two elements, then "set link_library [list * $target_library]"" return two list elements:
# *, {slow.db fast.db}
# while concat return 3 elements *, slow.db, fast.db
set link_library [concat [list *] $target_library]

# analyze + elaborate (parse the file + build design hierarchy) instead of read_file (legacy flow)
analyze -format verilog {
    Decoder.v 
    ARITHMETIC_UNIT.v 
    LOGIC_UNIT.v
    SHIFT_UNIT.v 
    CMP_UNIT.v 
    ALU_TOP.v
}
# also resolves Verilog parameters/generates
elaborate ALU_TOP
# link act on current design, so explictly set this beforehand
current_design ALU_TOP
# Resolves the references to instantiated submodules and library cells
link

# performs structural consistency checks
check_design > reports_dc/syn_check.rpt

source constraints.tcl

# Function: prevent or fix electrical violations where a single wire (net) is directly tied to multiple chip ports or hard-coded constants.

# The 3 Tasks Executed by set_fix_multiple_port_nets -all -buffer_constants:
# Task 1: Fixing Feedthrough Nets (Port-to-Port)
# • The Situation: An input port on your chip bypasses all logic and wires directly out of an output port
#   (Feedthrough Violations: physical design tools (PnR) struggle to calculate timing or handle isolation).
# • The Fix: The command rips up the direct wire and inserts a physical buffer in between them. This gives the PnR tool a physical cell to place and calculate timing on.
# Task 2: Fixing Multi-Driven Ports (Driver-to-Multiple-Ports)
# • The Situation: A single internal logic gate drives two or more top-level output ports simultaneously.
# • The Fix: It duplicates the signal by adding independent buffer cells for each port. This isolates the ports so that electrical noise on an external circuit board pin 
#   won't travel back down the wire and corrupt the other pin.
# Task 3: Fixing Constant Nets (The -buffer_constants part)
# • The Situation: Your RTL code contains hard-coded constants (e.g., assign my_signal = 1'b0; or an unused pin tied to ground).
# • The Fix: It forces the tool to insert a physical buffer right after a tie cell, preventing that single constant node from becoming a giant, chip-wide shared net.

# Without the -buffer_constants command, the synthesis tool might create just one Tie-High cell to save space:
#                       ┌───► Wire snaking to North Corner (Flip-Flop 1)
#                       ├───► Wire snaking to South Corner (Flip-Flop 2)
#   [Single Tie-Cell] ──┼───► Wire snaking to East Corner  (Flip-Flop 3)
#                       └───► ... snaking to 5,000 destinations! 
#                       (One tiny cell choked by physics(not enough drive strength); wires clog the whole chip)
# Buffer cell has large, strong internal transistors designed to pull massive amounts of current straight from the main power lines.
#                       ┌───► [Buffer A] ──► Drives 10 local gates in North Corner
#   [Single Tie-Cell] ──┼───► [Buffer B] ──► Drives 10 local gates in South Corner
#                       └───► [Buffer C] ──► Drives 10 local gates in East Corner
#                       (The Tie-Cell now only drives a few local buffers. The buffers do the heavy lifting near the actual gates!)

# -all: look at every variation of multi-port net configuration, without it, may ony fix specific types like feedthrough from input to output
# -buffer_constants: buffer the constant generator () with buffers 
set_fix_multiple_port_nets -all -buffer_constants

compile

# After synthesis, DC may produce internal identifiers containing characters that need to be escaped or renamed for convenient Verilog output, like alu/logic$1.
# change_names can normalize it to a Verilog-compatible identifier
# - -rules verilog: Apply Verilog naming conventions.
# - -hierarchy: Apply the rules throughout the entire design hierarchy, not just the current level.
change_names -rules verilog -hierarchy

# check if there is any missing or problematic timing constraints
check_timing                                > reports_dc/timing_check.rpt
report_timing -delay_type max -max_paths 20 > reports_dc/timing.rpt
report_area -hierarchy                      > reports_dc/area.rpt
report_power -hierarchy                     > reports_dc/power.rpt
report_constraint -all_violators            > reports_dc/constraints.rpt

write -format verilog -hierarchy -output syn/ALU_TOP_mapped.v
write_sdc syn/ALU_TOP_mapped.sdc
