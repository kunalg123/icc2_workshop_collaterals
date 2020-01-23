source -echo ./icc2_common_setup.tcl
source -echo ./icc2_dp_setup.tcl
if {[file exists ${WORK_DIR}/$DESIGN_LIBRARY]} {
   file delete -force ${WORK_DIR}/${DESIGN_LIBRARY}
}
###---NDM Library creation---###
set create_lib_cmd "create_lib ${WORK_DIR}/$DESIGN_LIBRARY"
if {[file exists [which $TECH_FILE]]} {
   lappend create_lib_cmd -tech $TECH_FILE ;# recommended
} elseif {$TECH_LIB != ""} {
   lappend create_lib_cmd -use_technology_lib $TECH_LIB ;# optional
}
lappend create_lib_cmd -ref_libs $REFERENCE_LIBRARY
puts "RM-info : $create_lib_cmd"
eval ${create_lib_cmd}

###---Read Synthesized Verilog---###
if {$DP_FLOW == "hier" && $BOTTOM_BLOCK_VIEW == "abstract"} {
   # Read in the DESIGN_NAME outline.  This will create the outline
   puts "RM-info : Reading verilog outline (${VERILOG_NETLIST_FILES})"
   read_verilog_outline -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
   } else {
   # Read in the full DESIGN_NAME.  This will create the DESIGN_NAME view in the database
   puts "RM-info : Reading full chip verilog (${VERILOG_NETLIST_FILES})"
   read_verilog -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
}

## Technology setup for routing layer direction, offset, site default, and site symmetry.
#  If TECH_FILE is specified, they should be properly set.
#  If TECH_LIB is used and it does not contain such information, then they should be set here as well.
if {$TECH_FILE != "" || ($TECH_LIB != "" && !$TECH_LIB_INCLUDES_TECH_SETUP_INFO)} {
   if {[file exists [which $TCL_TECH_SETUP_FILE]]} {
      puts "RM-info : Sourcing [which $TCL_TECH_SETUP_FILE]"
      source -echo $TCL_TECH_SETUP_FILE
   } elseif {$TCL_TECH_SETUP_FILE != ""} {
      puts "RM-error : TCL_TECH_SETUP_FILE($TCL_TECH_SETUP_FILE) is invalid. Please correct it."
   }
}

# Specify a Tcl script to read in your TLU+ files by using the read_parasitic_tech command
if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_PARASITIC_SETUP_FILE]"
   source -echo $TCL_PARASITIC_SETUP_FILE
} elseif {$TCL_PARASITIC_SETUP_FILE != ""} {
   puts "RM-error : TCL_PARASITIC_SETUP_FILE($TCL_PARASITIC_SETUP_FILE) is invalid. Please correct it."
} else {
   puts "RM-info : No TLU plus files sourced, Parastic library containing TLU+ must be included in library reference list"
}

###---Routing settings---###
## Set max routing layer
if {$MAX_ROUTING_LAYER != ""} {set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER}
## Set min routing layer
if {$MIN_ROUTING_LAYER != ""} {set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER}

####################################
# Check Design: Pre-Floorplanning
####################################
if {$CHECK_DESIGN} {
   redirect -file ${REPORTS_DIR_INIT_DP}/check_design.pre_floorplan     {check_design -ems_database check_design.pre_floorplan.ems -checks dp_pre_floorplan}
}

####################################
# Floorplanning
####################################
#initialize_floorplan -core_utilization 0.05
initialize_floorplan -honor_pad_limit 
save_lib -all

####################################
## PG Pin connections
#####################################
puts "RM-info : Running connect_pg_net -automatic on all blocks"
connect_pg_net -automatic -all_blocks
save_block -force       -label ${PRE_SHAPING_LABEL_NAME}
save_lib -all

####################################
### Place IO
######################################
if {[file exists [which $TCL_PAD_CONSTRAINTS_FILE]]} {
   puts "RM-info : Loading TCL_PAD_CONSTRAINTS_FILE file ($TCL_PAD_CONSTRAINTS_FILE)"
   source -echo $TCL_PAD_CONSTRAINTS_FILE

   puts "RM-info : running place_io"
   place_io
}
set_attribute [get_cells -hierarchical -filter pad_cell==true] status fixed

save_block -hier -force   -label ${PLACE_IO_LABEL_NAME}
save_lib -all

####################################
### Memory Placement
######################################
if [sizeof_collection [get_cells -hier -filter is_hard_macro==true -quiet]] {
   set all_macros [get_cells -hier -filter is_hard_macro==true]
   # Check top-level
   report_macro_constraints -allowed_orientations -preferred_location -alignment_grid -align_pins_to_tracks $all_macros > $REPORTS_DIR_PLACEMENT/report_macro_constraints.rpt
}

###---Place Macro at user defined locations---### 
#if {$USE_INCREMENTAL_DATA && [file exists $OUTPUTS_DIR/preferred_macro_locations.tcl]} {
source $OUTPUTS_DIR/preferred_macro_locations.tcl
#}

####################################
# Configure placement
####################################
if {$DISTRIBUTED} {
   set HOST_OPTIONS "-host_options block_script"
} else {
   set HOST_OPTIONS ""
}
set CMD_OPTIONS "-floorplan $HOST_OPTIONS"

########################################
## Read parasitic files
########################################
if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_PARASITIC_SETUP_FILE]"
   source -echo $TCL_PARASITIC_SETUP_FILE
    } elseif {$TCL_PARASITIC_SETUP_FILE != ""} {
   puts "RM-error : TCL_PARASITIC_SETUP_FILE($TCL_PARASITIC_SETUP_FILE) is invalid. Please correct it."
    } else {
   puts "RM-info : No TLU plus files sourced, Parastic library containing TLU+ must be included in library reference list"
    }

########################################
## Read constraints
########################################
if {[file exists $TCL_MCMM_SETUP_FILE]} {
   puts "RM-info : Loading TCL_MCMM_SETUP_FILE ($TCL_MCMM_SETUP_FILE)"
   source -echo $TCL_MCMM_SETUP_FILE
   } else {
   puts "RM-error : Cannot find TCL_MCMM_SETUP_FILE ($TCL_MCMM_SETUP_FILE)"
   error
   }
set CMD_OPTIONS "$CMD_OPTIONS -timing_driven"
set plan.place.auto_generate_blockages true

eval create_placement $CMD_OPTIONS
report_placement    -physical_hierarchy_violations all    -wirelength all -hard_macro_overlap    -verbose high > $REPORTS_DIR_PLACEMENT/report_placement.rpt

# write out macro preferred locations based on latest placement
# If this file exists on subsequent runs it will be used to drive the macro placement
if [sizeof_collection [get_cells -hier -filter is_hard_macro==true -quiet]] {
   file delete -force $OUTPUTS_DIR/preferred_macro_locations.tcl
   set all_macros [get_cells -hier -filter is_hard_macro==true]
   derive_preferred_macro_locations $all_macros -file $OUTPUTS_DIR/preferred_macro_locations.tcl
}

####################################
# Fix all shaped blocks and macros
####################################
if [sizeof_collection [get_cells -hier -filter is_hard_macro==true -quiet]] {
   set_attribute -quiet [get_cells -hierarchical -filter is_hard_macro==true] status fixed
}

save_block -hier -force   -label ${PLACEMENT_LABEL_NAME}
save_lib -all

####################################
# Create Power
####################################
if {[file exists $TCL_PNS_FILE]} {
   puts "RM-info : Sourcing TCL_PNS_FILE ($TCL_PNS_FILE)"
   source -echo $TCL_PNS_FILE
}

if {$PNS_CHARACTERIZE_FLOW == "true" && $TCL_COMPILE_PG_FILE != ""} {
   puts "RM-info : RUNNING PNS CHARACTERIZATION FLOW because \$PNS_CHARACTERIZE_FLOW == true"
   characterize_block_pg -output block_pg -compile_pg_script $TCL_COMPILE_PG_FILE
   set_constraint_mapping_file ./block_pg/pg_mapfile
   # run_block_compile_pg will honor the set_editability settings by default
   if {$DISTRIBUTED} { 
      set HOST_OPTIONS "-host_options block_script"
   } else {
      set HOST_OPTIONS ""
   }
   puts "RM-info : Running run_block_compile_pg $HOST_OPTIONS"
   eval run_block_compile_pg ${HOST_OPTIONS}

} else {
   if {$TCL_COMPILE_PG_FILE != ""} {
      source $TCL_COMPILE_PG_FILE
   } else {
      puts "RM-info : No Power Networks Implemented as TCL_COMPILE_PG_FILE does not exist"
   }
}

check_pg_connectivity -check_std_cell_pins none
# Create error report for PG ignoring std cells because they are not legalized
check_pg_drc -ignore_std_cells
# check_mv_design -erc_mode and -power_connectivity
redirect -file $REPORTS_DIR_CREATE_POWER/check_mv_design.erc_mode {check_mv_design -erc_mode}
redirect -file $REPORTS_DIR_CREATE_POWER/check_mv_design.power_connectivity {check_mv_design -power_connectivity}

save_block -hier -force   -label ${CREATE_POWER_LABEL_NAME}
save_lib -all

####################################
# Pin Placement
####################################
if {[file exists [which $TCL_PIN_CONSTRAINT_FILE]] && !$PLACEMENT_PIN_CONSTRAINT_AWARE} {
   source -echo $TCL_PIN_CONSTRAINT_FILE
}
set_app_options -as_user_default -list {route.global.timing_driven true}

if {$CHECK_DESIGN} {
   redirect -file ${REPORTS_DIR_PLACE_PINS}/check_design.pre_pin_placement     {check_design -ems_database check_design.pre_pin_placement.ems -checks dp_pre_pin_placement}
}

if {$PLACE_PINS_SELF} {
   place_pins -self
}

if {$PLACE_PINS_SELF} {
   # Write top-level port constraint file based on actual port locations in the design for reuse during incremental run.
   write_pin_constraints -self       -file_name $OUTPUTS_DIR/preferred_port_locations.tcl       -physical_pin_constraint {side | offset | layer}       -from_existing_pins

   # Verify Top-level Port Placement Results
   check_pin_placement -self -pre_route true -pin_spacing true -sides true -layers true -stacking true

   # Generate Top-level Port Placement Report
   report_pin_placement -self > $REPORTS_DIR_PLACE_PINS/report_port_placement.rpt
}

save_block -hier -force   -label ${PLACE_PINS_LABEL_NAME}
save_lib -all

####################################
# Timing estimation
####################################
estimate_timing
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.rpt     {report_timing -corner estimated_corner -mode [all_modes]}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor     {report_qor    -corner estimated_corner}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor.sum {report_qor    -summary}

save_block -hier -force   -label ${TIMING_ESTIMATION_LABEL_NAME}
save_lib -all


set path_dir [file normalize ${WORK_DIR_WRITE_DATA}]
set write_block_data_script ./write_block_data.tcl
source ${write_block_data_script}

####################################
# Place, CTS, Route
####################################
set_host_options -max_cores 8
remove_corners [get_corners estimated_corner]
set_app_options -name place.coarse.continue_on_missing_scandef -value true
place_opt
clock_opt
route_auto -max_detail_route_iterations 5
set FILLER_CELLS [get_object_name [sort_collection -descending [get_lib_cells NangateOpenCellLibrary/FILL*] area]]
create_stdcell_fillers -lib_cells $FILLER_CELLS

save_block -hier -force   -label post_route
save_lib -all

