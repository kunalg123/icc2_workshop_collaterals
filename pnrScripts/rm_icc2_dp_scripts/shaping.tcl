##########################################################################################
# Tool: IC Compiler II 
# Script: shaping.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Open design
####################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

if { [file exists place_io] } {
   set PREVIOUS_STEP_LABEL_NAME $PLACE_IO_LABEL_NAME
} else {
   set PREVIOUS_STEP_LABEL_NAME $PRE_SHAPING_LABEL_NAME
}

open_block ${DESIGN_NAME}/${PREVIOUS_STEP_LABEL_NAME}

puts "RM-info: Saving design ${DESIGN_NAME}/$PREVIOUS_STEP_LABEL_NAME to ${SHAPING_LABEL_NAME} label name"
save_block -hier -force \
  -label ${SHAPING_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${SHAPING_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${SHAPING_LABEL_NAME} -ref_libs_for_edit


####################################
## Pre-shaping customizations
####################################
if {[file exists [which $TCL_USER_SHAPING_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_SHAPING_PRE_SCRIPT]"
   source $TCL_USER_SHAPING_PRE_SCRIPT
} elseif {$TCL_USER_SHAPING_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_SHAPING_PRE_SCRIPT($TCL_USER_SHAPING_PRE_SCRIPT) is invalid. Please correct it."
}

# Load PNS Strategy
if [file exists [which $TCL_SHAPING_PNS_STRATEGY_FILE]] {
   puts "RM-info : Sourcing TCL_SHAPING_PNS_STRATEGY_FILE ($TCL_SHAPING_PNS_STRATEGY_FILE)"
   source -echo $TCL_SHAPING_PNS_STRATEGY_FILE
}

if [file exists [which $TCL_MANUAL_SHAPING_FILE]] {
   puts "RM-info : Skipping shaping, loading floorplan information from TCL_MANUAL_SHAPING_FILE ($TCL_MANUAL_SHAPING_FILE) "
   source -echo $TCL_MANUAL_SHAPING_FILE
} else {
   if [file exists [which $TCL_SHAPING_CONSTRAINTS_FILE]] {
      puts "RM-info : sourcing TCL_SHAPING_CONSTRAINTS_FILE ($TCL_SHAPING_CONSTRAINTS_FILE)"
      source -echo $TCL_SHAPING_CONSTRAINTS_FILE
   }

   if [file exists [which $SHAPING_CONSTRAINTS_FILE]] {
      puts "RM-info : Adding -constraint_file $SHAPING_CONSTRAINTS_FILE to SHAPING_CMD_OPTIONS"
      lappend SHAPING_CMD_OPTIONS {*}"-constraint_file $SHAPING_CONSTRAINTS_FILE"
   }
   # Shaping will consider the layer constraints during shaping

   ####################################
   # Check Design: Pre-Block Shaping
   ####################################
   if {$CHECK_DESIGN} { 
      redirect -file ${REPORTS_DIR_SHAPING}/check_design.pre_block_shaping \
       {check_design -ems_database check_design.pre_block_shaping.ems -checks dp_pre_block_shaping}
   }

   ###############################################
   # Shape the blocks and place top level macros
   ###############################################
   report_shaping_options > $REPORTS_DIR_SHAPING/report_shaping_option.rpt

   puts "RM-info : Running block shaping (shape_blocks $SHAPING_CMD_OPTIONS)"
   eval shape_blocks $SHAPING_CMD_OPTIONS

   report_block_shaping -core_area_violations -overlap -flyline_crossing > $REPORTS_DIR_SHAPING/report_block_shape.rpt
}

####################################
## Post-shaping customizations
####################################
if {[file exists [which $TCL_USER_SHAPING_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_SHAPING_POST_SCRIPT]"
   source $TCL_USER_SHAPING_POST_SCRIPT
} elseif {$TCL_USER_SHAPING_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_SHAPING_POST_SCRIPT($TCL_USER_SHAPING_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

print_message_info -ids * -summary
echo [date] > shaping
 
exit 
