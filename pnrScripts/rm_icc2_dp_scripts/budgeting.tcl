##########################################################################################
# Tool: IC Compiler II 
# Script: budgeting.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

################################################################################
# Open design
################################################################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

open_block ${DESIGN_NAME}/${TIMING_ESTIMATION_LABEL_NAME}

save_block -hier -force \
  -label ${BUDGETING_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${BUDGETING_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${BUDGETING_LABEL_NAME} -ref_libs_for_edit

####################################
## Pre-budgeting customizations
####################################
if {[info exists TCL_USER_BUDGETING_PRE_SCRIPT] && [file exists [which $TCL_USER_BUDGETING_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_BUDGETING_PRE_SCRIPT]"
   source $TCL_USER_BUDGETING_PRE_SCRIPT
} elseif {[info exists TCL_USER_BUDGETING_PRE_SCRIPT] && $TCL_USER_BUDGETING_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_BUDGETING_PRE_SCRIPT($TCL_USER_BUDGETING_PRE_SCRIPT) is invalid. Please correct it."
}

################################################################################
# Load budgeting user setup file if defined
################################################################################
if {[info exists TCL_BUDGETING_SETUP_FILE] && [file exists [which $TCL_BUDGETING_SETUP_FILE]]} {
   puts "RM-info : Sourcing TCL_BUDGETING_SETUP_FILE ($TCL_BUDGETING_SETUP_FILE)"
   source -echo $TCL_BUDGETING_SETUP_FILE
}

####################################
# Check Design: Pre-Budgets
####################################
if {$CHECK_DESIGN} { 
   redirect -file ${REPORTS_DIR_BUDGETING}/check_design.pre_budgeting \
    {check_design -ems_database check_design.pre_budgeting.ems -checks dp_pre_budgeting}
}

################################################################################
# Budgeting
################################################################################
# Derive block instances from block references if not already defined.
set DP_BLOCK_INSTS ""
foreach ref "$DP_BLOCK_REFS" {
   set DP_BLOCK_INSTS "$DP_BLOCK_INSTS [get_object_name [get_cells -hier -filter ref_name==$ref]]"
}

set_budget_options -add_blocks $DP_BLOCK_INSTS
compute_budget_constraints -setup_delay -boundary -latency_targets actual -balance true

################################################################################
# Load boundary budgeting constraint file if defined
################################################################################
if {[info exists TCL_BOUNDARY_BUDGETING_CONSTRAINTS_FILE] && [file exists [which $TCL_BOUNDARY_BUDGETING_CONSTRAINTS_FILE ]]} {
   puts "RM-info : Sourcing TCL_BOUNDARY_BUDGETING_CONSTRAINTS_FILE ($TCL_BOUNDARY_BUDGETING_CONSTRAINTS_FILE)"
   source -echo $TCL_BOUNDARY_BUDGETING_CONSTRAINTS_FILE
}

###############################################################################
# Write Out Budgets
################################################################################
write_budgets -output block_budgets -all_blocks -force

################################################################################
# Generate Budget Reports
################################################################################
report_budget -latency > $REPORTS_DIR_BUDGETING/report_budget.latency
report_budget -html_dir $REPORTS_DIR_BUDGETING/${DESIGN_NAME}.budget.html

################################################################################
# Write Out Budget Constraints
################################################################################
write_script -include budget -force -output $REPORTS_DIR_BUDGETING/${DESIGN_NAME}.budget_constraints

####################################
## Post-budgeting customizations
####################################
if {[info exists TCL_USER_BUDGETING_POST_SCRIPT] && [file exists [which $TCL_USER_BUDGETING_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_BUDGETING_POST_SCRIPT]"
   source $TCL_USER_BUDGETING_POST_SCRIPT
} elseif {[info exists TCL_USER_BUDGETING_POST_SCRIPT] && $TCL_USER_BUDGETING_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_BUDGETING_POST_SCRIPT($TCL_USER_BUDGETING_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

################################################################################
# Load Block Budget Constraints
################################################################################
if {$DISTRIBUTED} {
   set HOST_OPTIONS "-host_options block_script"
} else {
   set HOST_OPTIONS ""
}

set load_block_budgets_script "./rm_icc2_dp_scripts/load_block_budgets.tcl" 
eval run_block_script -script $load_block_budgets_script \
     -blocks [list "${DP_BLOCK_REFS}"] \
     -work_dir ./work_dir/load_block_budgets ${HOST_OPTIONS}

print_message_info -ids * -summary
echo [date] > budgeting
 
exit 
