puts "RM-info: Running script [info script]\n"
##########################################################################################
# Tool: IC Compiler II
# Script: init_design.mcmm_example.auto_expanded.tcl (template)
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

## Note :
#  1. To see the full list of mode / corner / scenario specific commands, 
#      refer to SolvNet 1777585 : "Multicorner-multimode constraint classification" 
#
#  2. Corner operating conditions are recommended to be specified directly through 
#     set_process_number, set_voltage and set_temperature
#
#	The PVT resolution function always finds the closest PVT match between the operating conditions and 
#      	the library pane.
#	A Corner operating condition may be specified directly with the set_process_number, set_voltage and 
#	set_temperature commands or indirectly with the set_operating_conditions command.
#	The set_process_label command may be used to distinguish between library panes with the same PVT 
#	values but different process labels.

##############################################################################################
# The following is a sample script to create two scenarios with scenario constraints provided,
# and let the constraints auto expanded to associated modes and scenarios. At the end of script,
# remove_duplicate_timing_contexts is used to improve runtime and capacity without loss of constraints.

# Reading of the TLUPlus files should be done beforehand,
# so the parasitic models can be referred to in the constraints.
# Specify TCL_PARASITIC_SETUP_FILE in icc2_common_setup.tcl for your read_parasitic_tech commands.
# read_parasitic_tech_example.tcl is provided as an example.
##############################################################################################

########################################
## Variables
########################################
## Scenario constraints; expand the section as needed
set scenario1 				"func1" ;# name of scenario1
set scenario_constraints($scenario1)    "/home/kunal/workshop/icc2_workshop_collaterals/raven_wrapper.sdc" ;# for all scenario1 specific constraints

#set scenario2 				"func2" ;# name of scenario2
#set scenario_constraints($scenario2)    "/home/kunal/design/picosoc/rtl/picorv32.sdc" ;# for all scenario2 specific constraints

########################################
## Create modes, corners, and scenarios
########################################
remove_modes -all; remove_corners -all; remove_scenarios -all

foreach s [array name scenario_constraints] {
	create_mode $s
	create_corner $s
	create_scenario -name $s -mode $s -corner $s
	set_parasitic_parameters -late_spec temp1 -early_spec temp1 -library ${DESIGN_NAME}${LIBRARY_SUFFIX} 
	set_voltage 1.10 -corner [current_corner] -object_list [get_supply_nets VDD] 
}

########################################
## Populate constraints 
########################################
## Populate scenario constraints which will then be automatically expanded to its associated modes and corners
foreach s [array name scenario_constraints] {
	current_scenario $s
	puts "RM-info: current_scenario $s"
	puts "RM-info: source $scenario_constraints($s)"
	source $scenario_constraints($s)

	# pls ensure $scenario_constraints($s) includes set_parasitic_parameters command for the corresponding corner,
	# for example, set_parasitic_parameters -late_spec $parasitics1 -early_spec $parasitics2,
	# where the command points to the parasitics read by the read_parasitic_tech commands.
	# Specify TCL_PARASITIC_SETUP_FILE in icc2_common_setup.tcl for your read_parasitic_tech commands.
	# read_parasitic_tech_example.tcl is provided as an example.	
}

########################################
## Configure analysis settings for scenarios
########################################
# Below are just examples to show usage of set_scenario_status (actual usage shold depend on your objective)
# scenario1 is a setup scenario and scenario2 is a hold scenario
set_scenario_status $scenario1 -none -setup true -hold true -leakage_power true -dynamic_power true -max_transition true -max_capacitance true -min_capacitance false -active true
#set_scenario_status $scenario2 -none -setup false -hold true -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true -active true

#redirect -file ${REPORTS_DIR}/${INIT_DESIGN_BLOCK_NAME}.report_scenarios.rpt {report_scenarios} 
redirect -file ${DESIGN_NAME}.report_scenarios.rpt {report_scenarios}
## To remove duplicate modes, corners, scenarios, and to improve runtime and capacity without loss of constraints :
remove_duplicate_timing_contexts

puts "RM-info: Completed script [info script]\n"

