##########################################################################################
# Tool: IC Compiler II 
# Script: create_power.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Open design
####################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

open_block ${DESIGN_NAME}/${PLACEMENT_LABEL_NAME}

save_block -hier -force \
  -label ${CREATE_POWER_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${CREATE_POWER_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${CREATE_POWER_LABEL_NAME} -ref_libs_for_edit

####################################
## Pre-create_power customizations
####################################
if {[file exists [which $TCL_USER_CREATE_POWER_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_CREATE_POWER_PRE_SCRIPT]"
   source $TCL_USER_CREATE_POWER_PRE_SCRIPT
} elseif {$TCL_USER_CREATE_POWER_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_CREATE_POWER_PRE_SCRIPT($TCL_USER_CREATE_POWER_PRE_SCRIPT) is invalid. Please correct it."
}

####################################
# GLOBAL PLANNING
####################################
if [file exists $TCL_GLOBAL_PLANNING_FILE] {
   puts "RM-info : Sourcing TCL_GLOBAL_PLANNING_FILE ($TCL_GLOBAL_PLANNING_FILE)"
   source -echo $TCL_GLOBAL_PLANNING_FILE
}

####################################
# Check Design: Pre-Power Insertion
####################################
if {$CHECK_DESIGN} { 
   redirect -file ${REPORTS_DIR_CREATE_POWER}/check_design.pre_power_insertion \
    {check_design -ems_database check_design.pre_power_insertion.ems -checks dp_pre_power_insertion}
}

####################################
# PNS/PNA 
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
   if {[file exists $TCL_PG_PUSHDOWN_FILE]} {
      puts "RM-info : Souring TCL_PG_PUSHDOWN_FILE ($TCL_PG_PUSHDOWN_FILE)"
      source $TCL_PG_PUSHDOWN_FILE
   } else {
      puts "RM-info : Automatic pushdown of PG geometries enabled. Pushing down into all blcoks"
      set pg [get_nets * -filter "net_type == power || net_type == ground" -quiet]

      if {[sizeof_collection $pg] > 0} {
         set_push_down_object_options \
            -object_type           {pg_routing} \
            -top_action            remove \
            -block_action          {copy create_pin_shape}
         push_down_objects $pg
      }
   }
}

if {[file exists $TCL_POST_PNS_FILE]} {
   puts "RM-info : Sourcing TCL_POST_PNS_FILE ($TCL_POST_PNS_FILE)"
   source -echo $TCL_POST_PNS_FILE
}

# Check phyiscal connectivity
check_pg_connectivity -check_std_cell_pins none

# Create error report for PG ignoring std cells because they are not legalized
check_pg_drc -ignore_std_cells

# check_mv_design -erc_mode and -power_connectivity
redirect -file $REPORTS_DIR_CREATE_POWER/check_mv_design.erc_mode {check_mv_design -erc_mode}
redirect -file $REPORTS_DIR_CREATE_POWER/check_mv_design.power_connectivity {check_mv_design -power_connectivity}

####################################
## Post-create_power customizations
####################################
if {[file exists [which $TCL_USER_CREATE_POWER_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_CREATE_POWER_POST_SCRIPT]"
   source $TCL_USER_CREATE_POWER_POST_SCRIPT
} elseif {$TCL_USER_CREATE_POWER_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_CREATE_POWER_POST_SCRIPT($TCL_USER_CREATE_POWER_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

print_message_info -ids * -summary
echo [date] > create_power

exit 


