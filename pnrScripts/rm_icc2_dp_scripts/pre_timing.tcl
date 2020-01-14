##########################################################################################
# Tool: IC Compiler II 
# Script: pre_timing.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Open design
####################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

open_block ${DESIGN_NAME}/${PLACE_PINS_LABEL_NAME} 

save_block -hier -force \
  -label ${PRE_TIMING_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PRE_TIMING_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PRE_TIMING_LABEL_NAME} -ref_libs_for_edit

####################################
## Pre-pre_timing customizations
####################################
if {[file exists [which $TCL_USER_PRE_TIMING_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PRE_TIMING_PRE_SCRIPT]"
   source $TCL_USER_PRE_TIMING_PRE_SCRIPT
} elseif {$TCL_USER_PRE_TIMING_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PRE_TIMING_PRE_SCRIPT($TCL_USER_PRE_TIMING_PRE_SCRIPT) is invalid. Please correct it."
}

if {[file exists $TCL_TIMING_ESTIMATION_SETUP_FILE]} {
   puts "RM-info : Sourcing  TCL_TIMING_ESTIMATION_SETUP_FILE ($TCL_TIMING_ESTIMATION_SETUP_FILE)"
   source -echo $TCL_TIMING_ESTIMATION_SETUP_FILE
}

##################################################################################################
## 		Lib cell usage restrictions (set_lib_cell_purpose)				##
##################################################################################################
## Excluded cells
##  Provide your excluded lib cell constraints with "set_lib_cell_purpose -exclude <purpose>" commands
if {[file exists [which $TCL_LIB_CELL_DONT_USE_FILE]]} {
        puts "RM-info: Sourcing [which $TCL_LIB_CELL_DONT_USE_FILE]"
        source $TCL_LIB_CELL_DONT_USE_FILE
} elseif {$TCL_LIB_CELL_DONT_USE_FILE != ""} {
        puts "RM-error: TCL_LIB_CELL_DONT_USE_FILE($TCL_LIB_CELL_DONT_USE_FILE) is invalid. Pls correct it."
}

################################################################################
# Create Block Timing Abstracts
# This will:
#   load internal constraints via the mapping file: report_mapping_file
#   Run estimate_timing on the block and create an optimized abstract used for top level optimized
################################################################################

if {$DP_FLOW == "hier"} {
   # Setup host options if running distributed


   if {$DISTRIBUTED} {
     set HOST_OPTIONS "-host_options block_script"
   } else {
     set HOST_OPTIONS ""
   }

   if {$DP_BLOCK_REFS != ""} {
      if {$BOTTOM_BLOCK_VIEW == "abstract"} {
         ####################################
         # Check Design: Pre-Pre Timing
         ####################################
         if {$CHECK_DESIGN} { 
            redirect -file ${REPORTS_DIR_PRE_TIMING}/check_design.pre_create_timing_abstract \
             {check_design -ems_database check_design.pre_create_timing_abstract.ems -checks dp_pre_create_timing_abstract}
         }
         # crete_abstract supports designs with both design and abstract view.  
         # It will create an abstract for the abstract blocks, and load the block constraints for design blocks.
         set CMD_OPTIONS "-estimate_timing $HOST_OPTIONS -all_blocks"
         puts "RM-info : Running create_abstract $CMD_OPTIONS"
         eval create_abstract $CMD_OPTIONS

         # Load constraints into designs
         if {$DP_INTERMEDIATE_LEVEL_BLOCK_REFS != "" && $INTERMEDIATE_BLOCK_VIEW != "abstract" } {
            set CMD_OPTIONS "-blocks [list $DP_INTERMEDIATE_LEVEL_BLOCK_REFS] -type SDC $HOST_OPTIONS"
            puts "RM-info : Running load_block_constraints $CMD_OPTIONS"
            eval load_block_constraints $CMD_OPTIONS
         }

      } else {
           # If it is a full netlist design, then load the constraints
           set CMD_OPTIONS "-type SDC $HOST_OPTIONS -all_blocks"
           puts "RM-info : Running load_block_constraints $CMD_OPTIONS"
           eval load_block_constraints $CMD_OPTIONS
      }
   }
} else {
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

####################################
## Post-pre_timing customizations
####################################
if {[file exists [which $TCL_USER_PRE_TIMING_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PRE_TIMING_POST_SCRIPT]"
   source $TCL_USER_PRE_TIMING_POST_SCRIPT
} elseif {$TCL_USER_PRE_TIMING_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PRE_TIMING_POST_SCRIPT($TCL_USER_PRE_TIMING_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

print_message_info -ids * -summary
echo [date] > pre_timing

exit 
