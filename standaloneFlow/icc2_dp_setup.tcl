puts "RM-info : Running script [info script]\n"
##########################################################################################
# Tool: IC Compiler II 
# Script: icc2_dp_setup.tcl 
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

##########################################################################################
# 				Flow Setup
##########################################################################################
set DP_FLOW         "flat"    ;# hier or flat
set FLOORPLAN_STYLE "channel" ;# Supported design styles channel, abutted
set CHECK_DESIGN    "true"    ;# run atomic check_design pre checks prior to DP commands

set DISTRIBUTED 0  ;# Use distributed runs
### It is required to include the set_host_options command to enable distributed mode tasks. For example,
set_host_options -max_cores 8
#set_host_options -name block_script -submit_command [list qsub -P bnormal -l mem_free=6G,qsc=o -cwd]

set BLOCK_DIST_JOB_FILE             ""     ;# File to set block specific resource requests for distributed jobs
# For example:
#   set_host_options -name block_script  -submit_command "bsub -q normal"
#   set_host_options -name large_block   -submit_command "bsub -q huge"
#   set_host_options -name special_block -submit_command "rsh" local_machine
#   set_app_options -block [get_block block4] -list {plan.distributed_run.block_host large_block}
#   set_app_options -block [get_block block5] -list {plan.distributed_run.block_host large_block}
#   set_app_options -block [get_block block2] -list {plan.distributed_run.block_host special_block}
#  
#   All the jobs associated with blocks that do not have the plan.distributed_run.block_host app option specified
#   will run using the block_script host option. The jobs for blocks block4 and block5 will use the large_block 
#   host option. The job form  block2  will  use  the  special_block host option.


##########################################################################################
# If the design is run with MIBs then change the block list appropriately
##########################################################################################
set DP_BLOCK_REFS                     [list] ;# design names for each physical block (including black boxes) in the design;
                                             ;# this includes bottom and mid level blocks in a Multiple Physical Hierarchy (MPH) design
set DP_INTERMEDIATE_LEVEL_BLOCK_REFS  [list data_memory] ;# design reference names for mid level blocks only
set DP_BB_BLOCK_REFS                  [list] ;# Black Box reference names 
set BOTTOM_BLOCK_VIEW             "abstract" ;# Support abstract or design view for bottom blocks
                                             ;# in the hier flow
set INTERMEDIATE_BLOCK_VIEW       "abstract" ;# Support abstract or design view for intermediate blocks

if { [info exists INTERMEDIATE_BLOCK_VIEW] && $INTERMEDIATE_BLOCK_VIEW == "abstract" } {
   set_app_options -name abstract.allow_all_level_abstract -value true  ;# Dafult value is false
}

# Provide blackbox instanace: target area, BB UPF file, BB Timing file, boundary
#set DP_BB_BLOCK_REFS "leon3s_bb"
#set DP_BB_BLOCKS(leon3s_bb,area)        [list 1346051] ;
#set DP_BB_BLOCKS(leon3s_bb,upf)         [list ${des_dir}/leon3s_bb.upf] ;
#set DP_BB_BLOCKS(leon3s_bb,timing)      [list ${des_dir}/leon3s_bbt.tcl] ;
#set DP_BB_BLOCKS(leon3s_bb,boundary)    { {x1 y1} {x2 y1} {x2 y2} {x1 y2} {x1 y1} } ;
#set DP_BB_SPLIT    "true"


##########################################################################################
# 				CONSTRAINTS / UPF INTENT
##########################################################################################
set TCL_TIMING_RULER_SETUP_FILE       "" ;# file sourced to define parasitic constraints for use with timing ruler 
                                          # before full extraction environment is defined
                                          # Example setup file:
                                          #       set_parasitic_parameters \
                                          #         -early_spec para_WORST \
                                          #         -late_spec para_WORST
set CONSTRAINT_MAPPING_FILE           "" ;# Constraint Mapping File. Default is "split/mapfile"
set TCL_UPF_FILE                      "" ;# Optional power intent TCL script


##########################################################################################
# 				TOP LEVEL FLOORPLAN CREATION (die, pad, RDL) / PLACE IO
##########################################################################################
set TCL_PHYSICAL_CONSTRAINTS_FILE     "" ;# TCL script for primary die area creation. If specified, DEF_FLOORPLAN_FILES will be loaded after TCL_PHYSICAL_CONSTRAINTS_FILE
set TCL_PRE_COMMIT_FILE               "" ;# file sourced to set attributes, lib cell purposes, .. etc on specific cells, prior to running commit_block
set TCL_USER_INIT_DP_POST_SCRIPT      "" ;# An optional Tcl file to be sourced at the very end of init_dp.tcl before save_block.


##########################################################################################
# 				PRE_SHAPING
##########################################################################################
set TCL_USER_PRE_SHAPING_PRE_SCRIPT   "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PRE_SHAPING_POST_SCRIPT  "" ;# An optional Tcl file to be sourced at the very end of the task

##########################################################################################
# 				PLACE_IO
##########################################################################################
set TCL_PAD_CONSTRAINTS_FILE          "/home/kunal/workshop/icc2_workshop_collaterals/pnrScripts/pad_placement_constraints.tcl" ;# file sourced to create everything needed by place_io to complete IO placement
                                         ;# including flip chip bumps, and io constraints
set TCL_RDL_FILE                      "" ;# file sourced to create RDL routes
set TCL_USER_PLACE_IO_PRE_SCRIPT      "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACE_IO_POST_SCRIPT     "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				SHAPING
##########################################################################################
switch $FLOORPLAN_STYLE {
   channel {set SHAPING_CMD_OPTIONS           "-channels true"} 
   abutted {set SHAPING_CMD_OPTIONS           "-channels false"} 
}

set TCL_SHAPING_CONSTRAINTS_FILE      "" ;# Specify any constraints prior to shaping i.e. set_shaping_options
                                          # or specify some block shapes manually, for example:
                                          #    set_block_boundary -cell block1 -boundary {{2.10 2.16} {2.10 273.60} \
                                          #    {262.02 273.60} {262.02 2.16}} -orientation R0
                                          #    set_fixed_objects [get_cells block1]
                                          # Support TCL based shaping constraints
                                          # An example is in rm_icc2_dp_scripts/tcl_shaping_constraints_example.tcl
set SHAPING_CONSTRAINTS_FILE          "" ;# Will be included as the -constraint_file option for shape_blocks
set TCL_SHAPING_PNS_STRATEGY_FILE     "" ;# file sourced to create PG strategies for block grid creation
set TCL_MANUAL_SHAPING_FILE           "" ;# File sourced to re-create all block shapes.
                                          # If this file exists, automatic shaping will be by-passed.
                                          # Existing auto or manual block shapes can be written out using the following:
                                          #    write_floorplan -objects <BLOCK_INSTS>
set TCL_USER_SHAPING_PRE_SCRIPT       "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_SHAPING_POST_SCRIPT      "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				PLACEMENT
##########################################################################################
set TCL_PLACEMENT_CONSTRAINTS_FILE    "" ;# Placeholder for any macro or standard cell placement constraints & options.
                                          # File is sourced prior to DP placement
set PLACEMENT_PIN_CONSTRAINT_AWARE    "false" ;# tells create_placement to consider pin constraints during placement
set USE_INCREMENTAL_DATA              "0" ;# Use floorplan constraints that were written out on a previous run
set CONGESTION_DRIVEN_PLACEMENT       "" ;# Set to one of the following: std_cell, macro, or both to enable congestion driven placement
set TIMING_DRIVEN_PLACEMENT           "" ;# Set to one of the following: std_cell, macro, or both to enable timing driven placement
set TCL_USER_PLACEMENT_PRE_SCRIPT     "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACEMENT_POST_SCRIPT    "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
#				GLOBAL PLANNING
##########################################################################################
set TCL_GLOBAL_PLANNING_FILE          "" ;#Global planning for bus/critical nets


##########################################################################################
# 				PNS
##########################################################################################
set TCL_PNS_FILE                      "./pns_example.tcl" ;# File sourced to define all power structures. 
                                          # This file will include the following types of PG commands:
                                          #   PG Regions
                                          #   PG Patterns
                                          #   PG Strategies
                                          # Note: The file should not contain compile_pg statements
                                          # An example is in rm_icc2_dp_scripts/pns_example.tcl
set PNS_CHARACTERIZE_FLOW             "true"  ;# Perform PG characterization and implementation
set TCL_COMPILE_PG_FILE               "./compile_pg_example.tcl" ;# File should contain all the compile_pg_* commands to create the power networks 
                                          # specified in the strategies in the TCL_PNS_FILE. 
                                          # An example is in rm_icc2_dp_scripts/compile_pg_example.tcl
set TCL_PG_PUSHDOWN_FILE              "" ;# Create this file to facilitate manual pushdown and bypass auto pushdown in the flow.
set TCL_POST_PNS_FILE                 "" ;# If it exists, this file will be sourced after PG creation.
set TCL_USER_CREATE_POWER_PRE_SCRIPT  "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_CREATE_POWER_POST_SCRIPT "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				PLACE PINS
##########################################################################################
##Note:Feedthroughs are disabled by default. Enable feedthroughs either through set_*_pin_constraints  Tcl commands or through Pin constraints file
set TCL_PIN_CONSTRAINT_FILE           "" ;# file sourced to apply set_*_pin_constraints to the design
set CUSTOM_PIN_CONSTRAINT_FILE        "" ;# will be loaded via read_pin_constraints -file
                                         ;# used for more complex pin constraints, 
                                         ;# or in constraint replay
set PLACE_PINS_SELF                   "true" ;# Set to true if the block's top level pins are not all connected to IO drivers.
set TIMING_PIN_PLACEMENT              "true" ;# Set to true for timing driven pin placement
set TCL_USER_PLACE_PINS_PRE_SCRIPT    "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACE_PINS_POST_SCRIPT   "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				PRE-TIMING
##########################################################################################
set TCL_USER_PRE_TIMING_PRE_SCRIPT    "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PRE_TIMING_POST_SCRIPT   "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				TIMING ESTIMATION
##########################################################################################
set TCL_TIMING_ESTIMATION_SETUP_FILE       "" ;# Specify any constraints prior to timing estimation
set TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT  "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_TIMING_ESTIMATION_POST_SCRIPT "" ;# An optional Tcl file to be sourced at the very end of the task
set TCL_LIB_CELL_DONT_USE_FILE             "" ;# A Tcl file for customized don't use ("set_lib_cell_purpose -exclude <purpose>" commands);
                                              ;#  to prevent estimate_timing picking a lib_cell not used by pnr flow.
                                              ;#  please specify non-optimization purpose lib cells in the file. 


##########################################################################################
# 				BUDGETING
##########################################################################################
set TCL_BUDGETING_SETUP_FILE                "" ;# Specify any constraints prior to budgeting
set TCL_BOUNDARY_BUDGETING_CONSTRAINTS_FILE "" ;# An optional user constraints file to override compute_budget_constraints
set TCL_USER_BUDGETING_PRE_SCRIPT           "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_BUDGETING_POST_SCRIPT          "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
## System Variables (there's no need to change the following)
##########################################################################################
set WORK_DIR ./work
set WORK_DIR_WRITE_DATA ./write_data_dir
if !{[file exists $WORK_DIR]} {file mkdir $WORK_DIR}

set SPLIT_CONSTRAINTS_LABEL_NAME split_constraints
set INIT_DP_LABEL_NAME init_dp
set PRE_SHAPING_LABEL_NAME pre_shaping
set PLACE_IO_LABEL_NAME place_io
set SHAPING_LABEL_NAME shaping
set PLACEMENT_LABEL_NAME placement
set CREATE_POWER_LABEL_NAME create_power
set CLOCK_TRUNK_PLANNING_LABEL_NAME clock_trunk_planning
set PLACE_PINS_LABEL_NAME place_pins
set PRE_TIMING_LABEL_NAME pre_timing
set TIMING_ESTIMATION_LABEL_NAME timing_estimation
set BUDGETING_LABEL_NAME budgeting

# Block label to be release by write_data
if {$DP_FLOW == "flat"} {
   set WRITE_DATA_LABEL_NAME timing_estimation
} else {
   set WRITE_DATA_LABEL_NAME budgeting
}

## Directories
set OUTPUTS_DIR	"./outputs_icc2"	;# Directory to write output data files; mainly used by write_data.tcl
set REPORTS_DIR	"./rpts_icc2"		;# Directory to write reports; mainly used by report_qor.tcl

set REPORTS_DIR_SPLIT_CONSTRAINTS $REPORTS_DIR/$SPLIT_CONSTRAINTS_LABEL_NAME
set REPORTS_DIR_INIT_DP $REPORTS_DIR/$INIT_DP_LABEL_NAME
set REPORTS_DIR_PRE_SHAPING $REPORTS_DIR/$PRE_SHAPING_LABEL_NAME
set REPORTS_DIR_PLACE_IO $REPORTS_DIR/$PLACE_IO_LABEL_NAME
set REPORTS_DIR_SHAPING $REPORTS_DIR/$SHAPING_LABEL_NAME
set REPORTS_DIR_PLACEMENT $REPORTS_DIR/$PLACEMENT_LABEL_NAME
set REPORTS_DIR_CREATE_POWER $REPORTS_DIR/$CREATE_POWER_LABEL_NAME
set REPORTS_DIR_CLOCK_TRUNK_PLANNING $REPORTS_DIR/$CLOCK_TRUNK_PLANNING_LABEL_NAME
set REPORTS_DIR_PLACE_PINS $REPORTS_DIR/$PLACE_PINS_LABEL_NAME
set REPORTS_DIR_PRE_TIMING $REPORTS_DIR/$PRE_TIMING_LABEL_NAME
set REPORTS_DIR_TIMING_ESTIMATION $REPORTS_DIR/$TIMING_ESTIMATION_LABEL_NAME
set REPORTS_DIR_BUDGETING $REPORTS_DIR/$BUDGETING_LABEL_NAME

if !{[file exists $REPORTS_DIR]} {file mkdir $REPORTS_DIR}
if !{[file exists $OUTPUTS_DIR]} {file mkdir $OUTPUTS_DIR}
if !{[file exists $REPORTS_DIR_SPLIT_CONSTRAINTS]} {file mkdir $REPORTS_DIR_SPLIT_CONSTRAINTS}
if !{[file exists $REPORTS_DIR_INIT_DP]} {file mkdir $REPORTS_DIR_INIT_DP}
if !{[file exists $REPORTS_DIR_PRE_SHAPING]} {file mkdir $REPORTS_DIR_PRE_SHAPING}
if !{[file exists $REPORTS_DIR_PLACE_IO]} {file mkdir $REPORTS_DIR_PLACE_IO}
if !{[file exists $REPORTS_DIR_SHAPING]} {file mkdir $REPORTS_DIR_SHAPING}
if !{[file exists $REPORTS_DIR_PLACEMENT]} {file mkdir $REPORTS_DIR_PLACEMENT}
if !{[file exists $REPORTS_DIR_CREATE_POWER]} {file mkdir $REPORTS_DIR_CREATE_POWER}
if !{[file exists $REPORTS_DIR_CLOCK_TRUNK_PLANNING]} {file mkdir $REPORTS_DIR_CLOCK_TRUNK_PLANNING}
if !{[file exists $REPORTS_DIR_PLACE_PINS]} {file mkdir $REPORTS_DIR_PLACE_PINS}
if !{[file exists $REPORTS_DIR_PRE_TIMING]} {file mkdir $REPORTS_DIR_PRE_TIMING}
if !{[file exists $REPORTS_DIR_TIMING_ESTIMATION]} {file mkdir $REPORTS_DIR_TIMING_ESTIMATION}
if !{[file exists $REPORTS_DIR_BUDGETING]} {file mkdir $REPORTS_DIR_BUDGETING}


if {[info exists env(LOGS_DIR)]} {
   set log_dir $env(LOGS_DIR)
} else {
   set log_dir ./logs_icc2 
}


set search_path [list ./rm_icc2_dp_scripts ./rm_icc2_pnr_scripts $WORK_DIR ] 
lappend search_path .

##########################################################################################
# 				Optional Settings
##########################################################################################
set_message_info -id PVT-012 -limit 1
set_message_info -id PVT-013 -limit 1
set search_path "/home/kunal/workshop/icc2_workshop_collaterals/"
set_app_var link_library "nangate_typical.db sram_32_1024_freepdk45_TT_1p0V_25C_lib.db"

puts "RM-info : Completed script [info script]\n"
