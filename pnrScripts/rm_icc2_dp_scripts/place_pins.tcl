##########################################################################################
# Tool: IC Compiler II 
# Script: place_pins.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Open design
####################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

if { [file exists clock_trunk_planning] } {
   set PREVIOUS_STEP_LABEL_NAME $CLOCK_TRUNK_PLANNING_LABEL_NAME
} else {
   set PREVIOUS_STEP_LABEL_NAME $CREATE_POWER_LABEL_NAME
}

open_block ${DESIGN_NAME}/${PREVIOUS_STEP_LABEL_NAME}

puts "RM-info: Saving design ${DESIGN_NAME}/$PREVIOUS_STEP_LABEL_NAME to ${PLACE_PINS_LABEL_NAME} label name"
save_block -hier -force \
  -label ${PLACE_PINS_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PLACE_PINS_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PLACE_PINS_LABEL_NAME} -ref_libs_for_edit

####################################
## Pre-place_pins customizations
####################################
if {[file exists [which $TCL_USER_PLACE_PINS_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PLACE_PINS_PRE_SCRIPT]"
   source $TCL_USER_PLACE_PINS_PRE_SCRIPT
} elseif {$TCL_USER_PLACE_PINS_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PLACE_PINS_PRE_SCRIPT($TCL_USER_PLACE_PINS_PRE_SCRIPT) is invalid. Please correct it."
}


################################################################################
# Constrain pins
# This file contains all the TCL set_*_pin_constraints
# Note: Feedthroughs are not enabled by default; Enable feedthroughs either through the Tcl pin constraints command or through the pin constraints file
################################################################################
if {[file exists [which $TCL_PIN_CONSTRAINT_FILE]] && !$PLACEMENT_PIN_CONSTRAINT_AWARE} {
   source -echo $TCL_PIN_CONSTRAINT_FILE
}

################################################################################
# This file contains the pin constraints in pin constraint format, not TCL
# see above
# If placement was pin costraints aware, the pin constraints have already been loaded
################################################################################
if {[file exists [which $CUSTOM_PIN_CONSTRAINT_FILE]] && !$PLACEMENT_PIN_CONSTRAINT_AWARE} {
   read_pin_constraints -file_name $CUSTOM_PIN_CONSTRAINT_FILE
}

################################################################################
# If incremental pin constraints exist and incremental mode is enabled, load them
################################################################################
if {$USE_INCREMENTAL_DATA && [file exists $OUTPUTS_DIR/preferred_pin_locations.tcl]} {
   read_pin_constraints -file_name $OUTPUTS_DIR/preferred_pin_locations.tcl
}
################################################################################
# If abutted floorplan style enable feedthrough creation for clocks
################################################################################
if {$FLOORPLAN_STYLE == "abutted"} {
   set_app_options -name plan.pins.exclude_clocks_from_feedthroughs -value false
}

################################################################################
# Enable timing driven pin placement
################################################################################
if {$TIMING_PIN_PLACEMENT} {
   if {[file exists $TCL_TIMING_ESTIMATION_SETUP_FILE]} {
      puts "RM-info : Sourcing  TCL_TIMING_ESTIMATION_SETUP_FILE ($TCL_TIMING_ESTIMATION_SETUP_FILE)"
      source -echo $TCL_TIMING_ESTIMATION_SETUP_FILE
   }
 
   if {$DP_FLOW == "hier"} {
      # Setup host options if running distributed
      if {$DISTRIBUTED} {
         set HOST_OPTIONS "-host_options block_script"
      } else {
         set HOST_OPTIONS ""
      }
 
      if {$DP_BB_BLOCK_REFS != ""} {
         # Get list of all non blackbox references
         set non_bb_blocks $DP_BLOCK_REFS
         foreach bb $DP_BB_BLOCK_REFS {
            set idx [lsearch -exact $non_bb_blocks $bb]
            set non_bb_blocks [lreplace $non_bb_blocks $idx $idx]
         }
 
         # Get list of all non blackbox instances
         set non_bb_insts ""
         foreach ref $non_bb_blocks {
            set non_bb_insts "$non_bb_insts [get_object_name [get_cells -hier -filter ref_name==$ref]]"
         }
 
         # Find all non black boxes instances at lowest hierachy levels
         set non_bb_for_abs [lsort -unique [get_attribute -objects [filter_collection [get_cells $non_bb_insts] "!has_child_physical_hierarchy"] -name ref_name]]
      
         # Create abstracts for all non black boxes at lowest hierachy levels
         set CMD_OPTIONS "-estimate_timing $HOST_OPTIONS -blocks [list $non_bb_for_abs]"
         puts "RM-info : Running create_abstract $CMD_OPTIONS"
         eval create_abstract $CMD_OPTIONS
      
         # Load constraints and create abstracts for BB blocks
         set CMD_OPTIONS "-blocks [list $DP_BB_BLOCK_REFS] -type SDC $HOST_OPTIONS"
         puts "RM-info : Running load_block_constraints $CMD_OPTIONS"
         eval load_block_constraints $CMD_OPTIONS
      
         set CMD_OPTIONS "-blocks [list $DP_BB_BLOCK_REFS] $HOST_OPTIONS"
         puts "RM-info : Running create_abstract $CMD_OPTIONS"
         eval create_abstract $CMD_OPTIONS
      
      } elseif {$DP_BLOCK_REFS != ""} {
           set CMD_OPTIONS "-estimate_timing $HOST_OPTIONS -all_blocks"
           puts "RM-info : Running create_abstract $CMD_OPTIONS"
           eval create_abstract $CMD_OPTIONS
      }
 
      # Load constraints for intermediate level blocks with design view
      if {$DP_INTERMEDIATE_LEVEL_BLOCK_REFS != "" && $INTERMEDIATE_BLOCK_VIEW != "abstract"} {
         set CMD_OPTIONS "-blocks [list $DP_INTERMEDIATE_LEVEL_BLOCK_REFS] -type SDC $HOST_OPTIONS"
         puts "RM-info : Running load_block_constraints $CMD_OPTIONS"
         eval load_block_constraints $CMD_OPTIONS
      }
   }
   # enable timing driven global routing
   set_app_options -as_user_default -list {route.global.timing_driven true}
}

####################################
# Check Design: Pre-Pin Placement
####################################
if {$CHECK_DESIGN} { 
   redirect -file ${REPORTS_DIR_PLACE_PINS}/check_design.pre_pin_placement \
    {check_design -ems_database check_design.pre_pin_placement.ems -checks dp_pre_pin_placement}
}

if [sizeof_collection [get_cells -quiet -hierarchical -filter "is_multiply_instantiated_block"]] { 
   check_mib_alignment
}

# Note: 
# If you need to re-run place_pins, it is recommended that you first remove previously created 
# feedthroughs (i.e. run remove_feedthroughs before re-running place_pins).
# If you do not want to disrupt your current pin placement, you can either set the physical status 
# of your block pins to fixed using the set_attribute command like so:
#    icc2_shell> set_attribute [get_terminals -of_objects [get_pins block/A]] physical_status fixed)
# Or you can assign pins for selected nets using place_pins -nets ...; 
# When the "-nets ..." option is used, the place_pins command will place pins only for the specified nets. 
# See the remove_feedthroughs and place_pins man pages for details.

if {$PLACE_PINS_SELF} {
   place_pins -self
}

if {$DP_FLOW == "hier"} {
   place_pins
}

################################################################################
# Dump pin constraints for re-use later in an incremental build
################################################################################
if {$DP_FLOW == "hier"} {
   write_pin_constraints \
      -file_name $OUTPUTS_DIR/preferred_pin_locations.tcl \
      -physical_pin_constraint {side | offset | layer} \
      -from_existing_pins

   ################################################################################
   # Verfiy Pin assignment results
   # If errors are found they will be stored in an .err file and can be browsed
   # with the integrated error browser.
   ################################################################################
   switch $FLOORPLAN_STYLE {
      channel {redirect -file $REPORTS_DIR_PLACE_PINS/check_pin_placement.rpt {check_pin_placement -alignment true -pre_route true \
               -sides true -stacking true -pin_spacing true -layers true}}
      abutted {redirect -file $REPORTS_DIR_PLACE_PINS/check_pin_placement.rpt {check_pin_placement -pre_route true -sides true \
               -stacking true -pin_spacing true -layers true -single_pin all -synthesized_pins true}}
   }

   ################################################################################
   #Generate a pin placement report to assess pin placement
   ################################################################################
   redirect -file $REPORTS_DIR_PLACE_PINS/report_feedthrough.rpt {report_feedthroughs -reporting_style net_based }
   redirect -file $REPORTS_DIR_PLACE_PINS/report_pin_placement.rpt {report_pin_placement}

   # check_mv_design -erc_mode and -power_connectivity
   redirect -file $REPORTS_DIR_PLACE_PINS/check_mv_design.erc_mode {check_mv_design -erc_mode}
   redirect -file $REPORTS_DIR_PLACE_PINS/check_mv_design.power_connectivity {check_mv_design -power_connectivity}
}

if {$PLACE_PINS_SELF} {
   # Write top-level port constraint file based on actual port locations in the design for reuse during incremental run.
   write_pin_constraints -self \
      -file_name $OUTPUTS_DIR/preferred_port_locations.tcl \
      -physical_pin_constraint {side | offset | layer} \
      -from_existing_pins

   # Verify Top-level Port Placement Results
   check_pin_placement -self -pre_route true -pin_spacing true -sides true -layers true -stacking true

   # Generate Top-level Port Placement Report
   report_pin_placement -self > $REPORTS_DIR_PLACE_PINS/report_port_placement.rpt
}

####################################
## Post-place_pins customizations
####################################
if {[file exists [which $TCL_USER_PLACE_PINS_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PLACE_PINS_POST_SCRIPT]"
   source $TCL_USER_PLACE_PINS_POST_SCRIPT
} elseif {$TCL_USER_PLACE_PINS_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PLACE_PINS_POST_SCRIPT($TCL_USER_PLACE_PINS_POST_SCRIPT) is invalid. Please correct it."
}


save_lib -all

print_message_info -ids * -summary
echo [date] > place_pins

exit 

