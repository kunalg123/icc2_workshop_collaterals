### Example script.  For details please refer to the IC Compiler II Design Planning User Guide and command man pages


################################################################################
#-------------------------------------------------------------------------------
# P G   R I N G   C R E A T I O N
#-------------------------------------------------------------------------------
################################################################################
create_pg_ring_pattern ring_pattern -horizontal_layer metal9 \
    -horizontal_width {5} -horizontal_spacing {2} \
    -vertical_layer metal10 -vertical_width {5} \
    -vertical_spacing {2} -corner_bridge false
set_pg_strategy core_ring -core -pattern \
    {{pattern: ring_pattern}{nets: {VDD VSS}}{offset: {3 3}}} \
    -extension {{stop: innermost_ring}}

################################################################################
#-------------------------------------------------------------------------------
# P A D   T O   R I N G   P G   C O N N E C T I O N S
#-------------------------------------------------------------------------------
################################################################################

#create_pg_macro_conn_pattern hm_pattern -pin_conn_type scattered_pin -layer {metal7 metal8}
#create_pg_macro_conn_pattern pad_pattern -pin_conn_type scattered_pin -layer {M7 M6}

#set all_pg_pads [get_cells * -hier -filter "ref_name==VDD_NS || ref_name==VSS_NS"]
#set_pg_strategy s_pad -macros $all_pg_pads  -pattern {{name: pad_pattern} {nets: {VDD VDD_LOW VSS}}}


################################################################################
#-------------------------------------------------------------------------------
# P G   M E S H   C R E A T I O N
#-------------------------------------------------------------------------------
################################################################################

create_pg_mesh_pattern pg_mesh1 \
   -parameters {w1 p1 w2 p2 f t} \
   -layers {{{vertical_layer: metal10} {width: @w1} {spacing: interleaving} \
        {pitch: @p1} {offset: @f} {trim: @t}} \
 	     {{horizontal_layer: metal9 } {width: @w2} {spacing: interleaving} \
        {pitch: @p2} {offset: @f} {trim: @t}}}


set_pg_strategy s_mesh1 \
   -pattern {{pattern: pg_mesh1} {nets: {VDD VSS VSS VDD}} \
{offset_start: 10 20} {parameters: 4 80 6 120 3.344 false}} \
   -core -extension {{stop: outermost_ring}}



################################################################################
#-------------------------------------------------------------------------------
# M A C R O   P G   C O N N E C T I O N S
#-------------------------------------------------------------------------------
################################################################################
#set toplevel_hms [filter_collection [get_cells * -physical_context] "is_hard_macro == true"]
#set_pg_strategy macro_con -macros $toplevel_hms -pattern {{name: hm_pattern} {nets: {VDD VSS}}}



################################################################################
#-------------------------------------------------------------------------------
# S T A N D A R D    C E L L    R A I L    I N S E R T I O N
#-------------------------------------------------------------------------------
################################################################################
create_pg_std_cell_conn_pattern \
    std_cell_rail  \
    -layers {metal1} \
    -rail_width 0.06

set_pg_strategy rail_strat -core \
    -pattern {{name: std_cell_rail} {nets: VDD VSS} }





