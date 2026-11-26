# Power ring -> vertical stripes -> standard-cell row rails. Dimensions are um.
# These are starting dimensions for the lab; inspect PG DRC/connectivity below.
# This script generates internal power distribution, it does not define power pads, bumps, or an external supply connection.
# So it's ***not a complete chip-level power-delivery design***.

save_block -as ${NAME}_power
open_block ${NAME}_power

create_pg_ring_pattern ring_pattern \
    -horizontal_layer metal5 -horizontal_width 1 -horizontal_spacing 1 \
    -vertical_layer metal6 -vertical_width 1 -vertical_spacing 1

# tells FC where and how to use the ring_pattern
# ring_strategy: Name assigned to this strategy.
# -core: Apply it around the core.
# {pattern: ring_pattern}: Use the previously defined ring geometry.
# {nets: {VDD VSS}}: Generate conductors for both supply nets.
# {offset: {0.5 0.5}}: Apply x/y offsets of 0.5 µm relative to the selected core reference boundary.
set_pg_strategy ring_strategy -core \
    -pattern {{pattern: ring_pattern} {nets: {VDD VSS}} {offset: {0.5 0.5}}}

# This is the command that actually generates the metal shapes and vias for the specified strategy.
compile_pg -strategies ring_strategy

# 
# The entire -layers argument is a nested Tcl list. Each inner group describes one property of a routing layer.
# vertical_layer: metal6: Create vertical PG stripes on metal6.
# width: 1: Each stripe is 1 µm wide.
# spacing: 1: Neighboring VDD/VSS stripes in the group have 1 µm spacing.
# pitch: 20: Repeat the stripe pattern with a 20 µm pitch.
create_pg_mesh_pattern stripe_pattern -layers {
    {{vertical_layer: metal6} {width: 1} {spacing: 3} {pitch: 17} {offset: 2}}
}

# How to choose pitch:
# Suppose core width were approximately 45 µm
# 10 µm  Dense     Lower rail resistance (less IR drop), more routing resources consumed
# 20 µm  Moderate  Reasonable experimental starting point
# 30 µm  Sparse    More signal-routing space, potentially higher IR drop

# -extension {{stop: outermost_ring}} tells FC to extend the stripe geometry toward the outermost power ring 
# instead of simply stopping at the core boundary.
set_pg_strategy stripe_strategy -core \
    -pattern {{pattern: stripe_pattern} {nets: {VDD VSS}}} \
    -extension {{stop: outermost_ring}}

compile_pg -strategies stripe_strategy

# creates a pattern for metal1 power rails aligned to standard-cell placement rows.
# create_pg_std_cell_conn_pattern is specialized for standard-cell rows. It is not a generic stripe generator like create_pg_mesh_pattern.
# no rail width: FC can use the width of the standard-cell PG pins when -rail_width is omitted.
# no rail pitch: rail locations are determined by standard-cell row geometry and the standard-cell PG pin locations
# no horizontal_layer: For a conventional horizontal standard-cell row, the rails run horizontally along the rows.
# no -extension {{stop: outermost_ring}}: they connect to metal6 stripes through vias, instead of contacting the outer power ring directly
create_pg_std_cell_conn_pattern rail_pattern -layers {metal1}

set_pg_strategy rail_strategy -core \
    -pattern {{pattern: rail_pattern} {nets: {VDD VSS}}}

# Connect the metal1 rails to the metal6 stripes with stacked vias.
# {existing: strap} {layers: metal6} Select existing PG straps on M6 (match stripe layer)
# {strategies: rail_strategy} Match geometry created by the rail strategy
# {intersection: undefined}	Match intersections not covered by earlier rules
# {via_master: nil}	Do not insert vias at those unspecified intersections
# via master is a template or rule that specifies the physical structure of a via connection.
set_pg_strategy_via_rule rail_vias -via_rule {
    {{{existing: strap} {layers: metal6}} {strategies: rail_strategy} {via_master: default}}
    {{intersection: undefined} {via_master: nil}}
}
compile_pg -strategies rail_strategy -via_rule rail_vias

# checks the physical power network for design-rule violations such as insufficient spacing, illegal overlap and via issues.
check_pg_drc
# checks the electrical connectivity of the power network, including disconnected straps, floating supply segments and cell PG connections
check_pg_connectivity
check_pg_missing_vias

# Put the signal pins (top level ports) on the boundary using metal3/metal4.
# -self: Apply the constraint to the current block itself
# In Fusion Compiler, a design can contain hierarchical blocks:
# TOP_CHIP
# ├── CPU_BLOCK
# ├── CACHE_BLOCK
# └── ALU_BLOCK
# You could configure pin constraints for a particular child block:
# set_block_pin_constraints \
#     -cells [get_cells ALU_BLOCK] \
#     -allowed_layers {metal3 metal4}

# -allowed_layers: Restrict the layers on which pins may be placed
# For a simple ALU, intermidiate metal3/metal4 is a reasonable initial choice, as reaching a high-layer pin from lower-layer cells may require more vias
set_block_pin_constraints -self -allowed_layers {metal3 metal4}

# actually place the pins of the current design block
# pin locations are preliminary, since std_cells not placed yet. They can be refined later when placement and congestion information becomes more accurate.
# Put after power planing: lets the pin placer consider the PG structures
# Put before std_cells placement: giving standard-cell placement an established I/O interface
place_pins -self

save_block
save_lib
