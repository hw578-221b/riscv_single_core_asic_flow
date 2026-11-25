# pg_objects: Power/ground-related objects and connections
# physical_only_cells: Cells used for physical implementation rather than ordinary logic
# leaf_module_declarations: Verilog module definitions for referenced leaf library cells,
# such as NAND2_X1, since verilog only instantiate them, instead of definiting them directly
# A leaf cell is a cell at the bottom of a design hierarchy: it contains no further instantiated submodules 

# suitable for uses such as logical verification
write_verilog -hierarchy all \
    -exclude {pg_objects physical_only_cells leaf_module_declarations} outputs/${NAME}_GL.v
# retains PG objects and physical-only cells
write_verilog -hierarchy all -exclude {leaf_module_declarations} outputs/${NAME}_GL_pg.v

# .lef: Design Exchange Format
# Format	Main information	                Purpose
# .v	    Cells and logical connectivity	    Logic simulation, equivalence checking
# .def	    Placement and routing information	Exchange physical-design data between EDA tools
# .gds	    Actual layer geometry and hierarchy	Physical layout inspection, verification, manufacturing handoff
write_def outputs/${NAME}.def

file mkdir reports_fc/report_final
set PATH reports_fc/report_final

# update timing before exporting parasitics and generating reports!!!!!!!!!!
update_timing -full

# Export extracted wire resistance/capacitance in SPEF format
#write_parasitics -format SPEF -output outputs/${NAME}

check_timing > ${PATH}/postRoute_check_timing.rpt

report_area -hierarchy > ${PATH}/pnr_final_area.rpt

# Separate timing reports and delay files for SS, TT and FF.
foreach scenario {FUNC_SS FUNC_TT FUNC_FF} {
    current_scenario $scenario

    # Perform & report post-routing STA, those two commands also need -scenarios $scenario to get scenario specific analysis!!
    report_timing -scenarios $scenario -delay_type max -max_paths 10 -transition_time -significant_digits 5 > ${PATH}/${scenario}_setup.rpt
    report_timing -scenarios $scenario -delay_type min -max_paths 10 -transition_time -significant_digits 5 > ${PATH}/${scenario}_hold.rpt

    report_constraints -all_violators > ${PATH}/${scenario}_violations.rpt
    report_power > ${PATH}/${scenario}_power.rpt
    # switching activity report
    report_activity -verbose > ${PATH}/${scenario}_activity.rpt
    # let you see how the same physical implementation has different characterized delays under SS, TT and FF conditions
    write_sdf outputs/${NAME}_${scenario}.sdf
}

current_scenario FUNC_TT
write_sdc -output outputs/${NAME}.sdc

# reports timing-path-group information, area, cell statistics and design-rule violations
# reports all active scenarios by default
redirect -file ${PATH}/qor.rpt { report_qor }

save_block
save_lib

# Generate GDS File
# -hierarchy all: includes the design hierarchy and referenced library cells.
# -lib_cell_view frame: exports the cells' abstract physical views, built from your LEF, instead of full transistor layouts.
# outputs/ALU_TOP_pnr.gds: specifies the output filename.
write_gds -hierarchy all -lib_cell_view frame outputs/${NAME}_pnr.gds

# In Synopsys's physical libraries, a standard cell can have different views.
# View	    Contains	                                            Used for
# frame	    Cell boundary, pins, routing obstructions, via regions	Placement and routing
# design	Detailed cell layout geometry and connectivity	        Full physical representation
