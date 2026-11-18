# pg_objects: Power/ground-related objects and connections
# physical_only_cells: Cells used for physical implementation rather than ordinary logic
# leaf_module_declarations: Verilog module definitions for referenced leaf library cells,
# such as NAND2_X1, since verilog only instantiate them, instead of definiting them directly
# A leaf cell is a cell at the bottom of a design hierarchy: it contains no further instantiated submodules 

# suitable for uses such as logical verification
write_verilog -hierarchy all \
    -exclude {pg_objects physical_only_cells leaf_module_declarations} outputs/ALU_TOP.v
# retains PG objects and physical-only cells
write_verilog -hierarchy all -exclude {leaf_module_declarations} outputs/ALU_TOP_pg.v

# .lef: Design Exchange Format
# Format	Main information	                Purpose
# .v	    Cells and logical connectivity	    Logic simulation, equivalence checking
# .def	    Placement and routing information	Exchange physical-design data between EDA tools
# .gds	    Actual layer geometry and hierarchy	Physical layout inspection, verification, manufacturing handoff
write_def outputs/ALU_TOP.def

# update timing before exporting parasitics and generating reports
update_timing -full

# Export extracted wire resistance/capacitance in SPEF format
write_parasitics -format SPEF -output outputs/ALU_TOP

# > is a Synopsys command-interface feature, not a general Tcl language operator

# Separate timing reports and delay files for SS, TT and FF.
foreach scenario {FUNC_SS FUNC_TT FUNC_FF} {
    current_scenario $scenario
    # Perform/report maximum-delay (setup-oriented) STA
    redirect -file reports_fc/${scenario}_setup.rpt { report_timing -delay_type max -max_paths 10 -transition_time}
    # Perform/report minimum-delay (hold-oriented) STA
    redirect -file reports_fc/${scenario}_hold.rpt { report_timing -delay_type min -max_paths 10 -transition_time}
    redirect -file reports_fc/${scenario}_violations.rpt { report_constraints -all_violators }
    redirect -file reports_fc/${scenario}_power.rpt { report_power }
    redirect -file reports_fc/${scenario}_check_timing.rpt { check_timing }
    # let you see how the same physical implementation has different characterized delays under SS, TT and FF conditions
    write_sdf outputs/ALU_TOP_${scenario}.sdf
}

current_scenario FUNC_TT
write_sdc -output outputs/ALU_TOP.sdc

# reports timing-path-group information, area, cell statistics and design-rule violations
# reports all active scenarios by default
redirect -file reports_fc/qor.rpt { report_qor }

save_block
save_lib

# Generate GDS File
# -hierarchy all: includes the design hierarchy and referenced library cells.
# -lib_cell_view frame: exports the cells' abstract physical views, built from your LEF, instead of full transistor layouts.
# outputs/ALU_TOP_pnr.gds: specifies the output filename.
write_gds -hierarchy all -lib_cell_view frame outputs/ALU_TOP_pnr.gds

# In Synopsys's physical libraries, a standard cell can have different views.
# View	    Contains	                                            Used for
# frame	    Cell boundary, pins, routing obstructions, via regions	Placement and routing
# design	Detailed cell layout geometry and connectivity	        Full physical representation
