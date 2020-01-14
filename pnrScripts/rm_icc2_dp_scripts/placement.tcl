##########################################################################################
# Tool: IC Compiler II 
# Script: placement.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Open design
####################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

open_block ${DESIGN_NAME}/${SHAPING_LABEL_NAME}

save_block -hier -force \
  -label ${PLACEMENT_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PLACEMENT_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PLACEMENT_LABEL_NAME} -ref_libs_for_edit

####################################
## Pre-placement customizations
####################################
if {[file exists [which $TCL_USER_PLACEMENT_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PLACEMENT_PRE_SCRIPT]"
   source $TCL_USER_PLACEMENT_PRE_SCRIPT
} elseif {$TCL_USER_PLACEMENT_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PLACEMENT_PRE_SCRIPT($TCL_USER_PLACEMENT_PRE_SCRIPT) is invalid. Please correct it."
}

####################################
# Push rows and tracks into blocks if no site_arrays exist
####################################
if {[llength [get_site_arrays -quiet]] == 0} {
   puts "RM-info : pushing down site_rows into all blocks"
   push_down_objects [get_site_rows]
}

if [file exists [which $TCL_PLACEMENT_CONSTRAINTS_FILE]] {
   puts "RM-info : sourcing file TCL_PLACEMENT_CONSTRAINTS_FILE ($TCL_PLACEMENT_CONSTRAINTS_FILE)"
   source -echo $TCL_PLACEMENT_CONSTRAINTS_FILE
}

####################################
# place std cells and macros
# -floorplan enables macro placement
####################################
if [sizeof_collection [get_cells -hier -filter is_hard_macro==true -quiet]] {
   set all_macros [get_cells -hier -filter is_hard_macro==true]
   # Check top-level 
   report_macro_constraints -allowed_orientations -preferred_location -alignment_grid -align_pins_to_tracks $all_macros > $REPORTS_DIR_PLACEMENT/report_macro_constraints.rpt
}

# If pin-constraint aware placement is used then sourcing all pin constraint files before placement
if {$PLACEMENT_PIN_CONSTRAINT_AWARE == "true"} {
   puts "RM-info : pin aware pin placement enabled (PLACEMENT_PIN_CONSTRAINT_AWARE == $PLACEMENT_PIN_CONSTRAINT_AWARE)"
   if {[file exists [which $TCL_PIN_CONSTRAINT_FILE]]} {
      puts "RM-info : sourcing TCL_PIN_CONSTRAINT_FILE $TCL_PIN_CONSTRAINT_FILE"
      source -echo $TCL_PIN_CONSTRAINT_FILE
   }
   if {[file exists [which $CUSTOM_PIN_CONSTRAINT_FILE]]} {
      puts "RM-info : sourcing CUSTOM_PIN_CONSTRAINT_FILE $CUSTOM_PIN_CONSTRAINT_FILE"
      read_pin_constraints -file_name $CUSTOM_PIN_CONSTRAINT_FILE
   }
}

# To support incremental macro placement constraints, enable it and write out the preferred locations file
if {$USE_INCREMENTAL_DATA && [file exists $OUTPUTS_DIR/preferred_macro_locations.tcl]} {
   source $OUTPUTS_DIR/preferred_macro_locations.tcl
}

####################################
# Check Design: Pre-Placement
####################################
if {$CHECK_DESIGN} { 
   redirect -file ${REPORTS_DIR_PLACEMENT}/check_design.pre_macro_placement \
    {check_design -ems_database check_design.pre_macro_placement.ems -checks dp_pre_macro_placement}
}


####################################
# Configure placement
####################################
if {$DISTRIBUTED} {
   set HOST_OPTIONS "-host_options block_script"
} else {
   set HOST_OPTIONS ""
}

set CMD_OPTIONS "-floorplan $HOST_OPTIONS"

if {[info exist CONGESTION_DRIVEN_PLACEMENT] && $CONGESTION_DRIVEN_PLACEMENT != ""} {
   set_app_option -name plan.place.congestion_driven_mode -value $CONGESTION_DRIVEN_PLACEMENT
   set CMD_OPTIONS "$CMD_OPTIONS -congestion"
}

if {[info exist TIMING_DRIVEN_PLACEMENT] && $TIMING_DRIVEN_PLACEMENT != ""} {
   if {$DP_BLOCK_REFS != ""} {
      # If the bottom blocks are abstracts, then create_placement -timing_driven will automatically
      # update the abstracts
      # If it is a full netlist design, then load the constraints
      if {$BOTTOM_BLOCK_VIEW != "abstract"} {
         puts "RM-info : Running load_block_constraints -type SDC $HOST_OPTIONS -all_blocks"
         eval load_block_constraints -type SDC $HOST_OPTIONS -all_blocks
      }
   } else {
      # If the block is flat, load timing information into the design.
      # Specify a Tcl script to read in your TLU+ files by using the read_parasitic_tech command
      if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
         puts "RM-info : Sourcing [which $TCL_PARASITIC_SETUP_FILE]"
         source -echo $TCL_PARASITIC_SETUP_FILE
      } elseif {$TCL_PARASITIC_SETUP_FILE != ""} {
         puts "RM-error : TCL_PARASITIC_SETUP_FILE($TCL_PARASITIC_SETUP_FILE) is invalid. Please correct it."
      } else {
         puts "RM-info : No TLU plus files sourced, Parastic library containing TLU+ must be included in library reference list"
      }

      if {[file exists $TCL_MCMM_SETUP_FILE]} {
         puts "RM-info : Loading TCL_MCMM_SETUP_FILE ($TCL_MCMM_SETUP_FILE)"
         source -echo $TCL_MCMM_SETUP_FILE 
      } else {
         puts "RM-error : Cannot find TCL_MCMM_SETUP_FILE ($TCL_MCMM_SETUP_FILE)"
         error
      }
   }
   set CMD_OPTIONS "$CMD_OPTIONS -timing_driven"
   puts "RM-info : Running timing driven placement for $TIMING_DRIVEN_PLACEMENT."
}

puts "RM-info : Running create_placement $CMD_OPTIONS"
eval create_placement $CMD_OPTIONS

report_placement \
   -physical_hierarchy_violations all \
   -wirelength all -hard_macro_overlap \
   -verbose high > $REPORTS_DIR_PLACEMENT/report_placement.rpt

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

if {$DP_FLOW == "hier"} {
   # Derive block instances from block references if not already defined.
   set DP_BLOCK_INSTS ""
   foreach ref "$DP_BLOCK_REFS" {
      set DP_BLOCK_INSTS "$DP_BLOCK_INSTS [get_object_name [get_cells -hier -filter ref_name==$ref]]"
   }
   set_attribute -quiet [get_cells $DP_BLOCK_INSTS] status fixed
}

####################################
## Post-placement customizations
####################################
if {[file exists [which $TCL_USER_PLACEMENT_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PLACEMENT_POST_SCRIPT]"
   source $TCL_USER_PLACEMENT_POST_SCRIPT
} elseif {$TCL_USER_PLACEMENT_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PLACEMENT_POST_SCRIPT($TCL_USER_PLACEMENT_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

print_message_info -ids * -summary
echo [date] > placement

exit 
