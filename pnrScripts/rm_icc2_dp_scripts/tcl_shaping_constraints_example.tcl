### Example script.  For details please refer to the IC Compiler II Design Planning User Guide and command man pages


################################################################################
#-------------------------------------------------------------------------------
# Enable TCL-based Shaping Constraints 
#-------------------------------------------------------------------------------
################################################################################
set_app_options -name plan.shaping.import_tcl_shaping_constraints -value true


################################################################################
#-------------------------------------------------------------------------------
# Create Shaping Groups
#-------------------------------------------------------------------------------
################################################################################
create_group -name TOP                -shaping [get_cells  {u1 u2 u3 u4}]
create_group -name BOTTOM             -shaping [get_cells  {u5 u6 u7 u8}]
create_group -name TOP_and_BOTTOM     -shaping [get_groups {TOP BOTTOM}]


################################################################################
#-------------------------------------------------------------------------------
# Specify Type of Layout for Each Shaping Group
#-------------------------------------------------------------------------------
################################################################################
create_shaping_constraint [get_groups -shaping TOP]            -type array_layout -array_layout east
create_shaping_constraint [get_groups -shaping BOTTOM]         -type array_layout -array_layout west
create_shaping_constraint [get_groups -shaping TOP_and_BOTTOM] -type array_layout -array_layout south


################################################################################
#-------------------------------------------------------------------------------
# Specify Channel Size Constraints
#-------------------------------------------------------------------------------
################################################################################
set ch1 [create_shaping_channel -neighbor [get_cells u1] -left_min 15 -left_max 20 -right_min 15 -right_max 20]
create_shaping_constraint [get_cells u2] -type external_channels -neighbor_channel $ch1
set ch2 [create_shaping_channel -neighbor [get_cells u3] -left_min 15 -left_max 20 -right_min 15 -right_max 20]
create_shaping_constraint [get_cells u4] -type external_channels -neighbor_channel $ch2







