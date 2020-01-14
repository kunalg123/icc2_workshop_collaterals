##########################################################################################
# Tool: Fusion Compiler
# Script: rebuild_design.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/fc_dp_setup.tcl 

################################################################################
# Create and read the design	
################################################################################

puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

open_block ${DESIGN_NAME}/${INIT_DP_LABEL_NAME}
save_block -hier -force \
   -label ${REBUILD_DESIGN_LABEL_NAME}
close_lib -purge -force -all
puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${REBUILD_DESIGN_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${REBUILD_DESIGN_LABEL_NAME} -ref_libs_for_edit



##########################################################################################
# Restore feedthroughs
##########################################################################################
suppress_message [list SEL-004 SEL-005 CMD-013]
set sh_continue_on_error true
source -e ./${DESIGN_NAME}_ft.tcl
set sh_continue_on_error false
unsuppress_message [list SEL-004 SEL-005 CMD-013]

##########################################################################################
# Load top/block constraints
##########################################################################################
if {$DP_FLOW == "hier"} {

   if {$DISTRIBUTED} {
      set HOST_OPTIONS "-host_options block_script"
   } else {
      set HOST_OPTIONS ""
   }

      
   #load split constraints and budget results
   if {$CONSTRAINT_MAPPING_FILE != ""} {
      set_constraint_mapping_file $CONSTRAINT_MAPPING_FILE
   } else {
      if {![file exists "./split/mapfile"]} {
         puts "RM-error : Cannot find default mapping file ./split/mapfile. Please create or specify the mapping file using the CONSTRAINT_MAPPING_FILE variable in setup.tcl "
         error
      } elseif {![file exists "./block_budgets/mapfile"]} {
         puts "RM-error : Cannot find default mapping file ./block_budgets/mapfile. Please complete budget flow to generate ./block_budgets."
         error
      } else {
         puts "RM-warning : No CONSTRAINT_MAPPING_FILE set, merging ./split/mapfile and ./block_budgets/mapfile to ./mapfile"
         set files [list ./split/mapfile ./block_budgets/mapfile]
         set fout [open "./mapfile" w]
         foreach file $files {
            set fin [open $file r]
            set dirname [file dirname $file]
            while {[gets $fin line] != -1} {
               puts $fout "[lrange $line 0 1] ${dirname}/[lindex $line end]"
            }
            close $fin
         }
         close $fout
         set_constraint_mapping_file ./mapfile
         report_constraint_mapping_file
      }
   }

   eval load_block_constraints -type SDC -type UPF -type BUDGET -all_blocks ${HOST_OPTIONS}

} else {
   # Load UPF file
   if {[file exists [which $UPF_FILE]]} {
      puts "RM-info : Loading UPF file $UPF_FILE"
      load_upf $UPF_FILE
      if {[file exists [which $UPF_UPDATE_SUPPLY_SET_FILE]]} {
         puts "RM-info : Loading UPF update supply set file $UPF_UPDATE_SUPPLY_SET_FILE"
         load_upf $UPF_UPDATE_SUPPLY_SET_FILE
      }
   } else {
      puts "RM-warning : UPF file not found."
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

   if {[file exists $TCL_MCMM_SETUP_FILE]} {
      puts "RM-info : Loading TCL_MCMM_SETUP_FILE ($TCL_MCMM_SETUP_FILE)"
      source -echo $TCL_MCMM_SETUP_FILE
   } else {
      puts "RM-error : Cannot find TCL_MCMM_SETUP_FILE ($TCL_MCMM_SETUP_FILE)"
      error
   }

   # Adjust commit_upf after mcmm setup preventing iso rename. Refer to mv.cells.rename_isolation_cell_with_formal_name for details.
   if {[file exists [which $UPF_FILE]]} { 
      commit_upf
   }
}

##########################################################################################
# Restore floorplan
##########################################################################################
source -e ./${DESIGN_NAME}_fp/floorplan.tcl

change_names -rules verilog -hierarchy

save_lib -all
close_lib -all

################################################################################
## Write out NLIB
################################################################################
set WORK_DIR_REBUILD_DESIGN "${REBUILD_DESIGN_LABEL_NAME}_dir"

exec rm -rf ${WORK_DIR_REBUILD_DESIGN}
exec cp -pr ${WORK_DIR} ${WORK_DIR_REBUILD_DESIGN}

puts "RM-info : Opening library ${WORK_DIR_REBUILD_DESIGN}/${DESIGN_LIBRARY}"	
open_lib ${WORK_DIR_REBUILD_DESIGN}/${DESIGN_LIBRARY} -ref_libs_for_edit
open_block ${DESIGN_NAME}/${REBUILD_DESIGN_LABEL_NAME} -ref_libs_for_edit

# Save as release label name for the start of place & route
save_block -hierarchical -label ${RELEASE_LABEL_NAME_DP}

close_lib -all
open_lib ${WORK_DIR_REBUILD_DESIGN}/${DESIGN_LIBRARY} -ref_libs_for_edit 

# removed DP related block labels
set blocks_to_be_removed [get_blocks *:*/*.* -all -filter label_name!=${RELEASE_LABEL_NAME_DP}]
remove_blocks -force $blocks_to_be_removed


print_message_info -ids * -summary
echo [date] > rebuild_design

exit
