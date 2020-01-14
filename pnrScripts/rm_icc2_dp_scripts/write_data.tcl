##########################################################################################
# Tool: IC Compiler II 
# Script: write_data.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

################################################################################
## Open Design
################################################################################
exec rm -rf ${WORK_DIR_WRITE_DATA}

exec cp -pr ${WORK_DIR} ${WORK_DIR_WRITE_DATA}

puts "RM-info : Opening library ${WORK_DIR_WRITE_DATA}/${DESIGN_LIBRARY}"	
open_lib ${WORK_DIR_WRITE_DATA}/${DESIGN_LIBRARY} -ref_libs_for_edit
open_block ${DESIGN_NAME}/${WRITE_DATA_LABEL_NAME} -ref_libs_for_edit

if {$DP_FLOW == "hier"} {
   if {$DISTRIBUTED} {
      set HOST_OPTIONS "-host_options block_script"
   } else {
      set HOST_OPTIONS ""
   }
eval merge_abstract -all_blocks ${HOST_OPTIONS}
}

# Save as release label name for the start of place & route
save_block -hierarchical -label ${RELEASE_LABEL_NAME_DP}

close_lib -all
open_lib ${WORK_DIR_WRITE_DATA}/${DESIGN_LIBRARY} -ref_libs_for_edit 

# removed DP related block labels
set blocks_to_be_removed [get_blocks *:*/*.* -all -filter label_name!=${RELEASE_LABEL_NAME_DP}]
remove_blocks -force $blocks_to_be_removed

open_block ${DESIGN_NAME}/${RELEASE_LABEL_NAME_DP} -ref_libs_for_edit

if {[info exists DP_BLOCK_REFS]} {
   # Add top level to blocks
   set DP_BLOCK_REFS "$DP_BLOCK_REFS $DESIGN_NAME"
} else {
   set DP_BLOCK_REFS $DESIGN_NAME
}
    
# Dump top
set path_dir [file normalize ${WORK_DIR_WRITE_DATA}]
set write_block_data_script ./rm_icc2_dp_scripts/write_block_data.tcl 
source ${write_block_data_script}


if {$DP_FLOW == "hier"} {
   if {$DISTRIBUTED} {
      run_block_script -script ${write_block_data_script} \
         -blocks ${DP_BLOCK_REFS} \
         -work_dir ./work_dir/write_data \
         -var_list "path_dir [file normalize ${WORK_DIR_WRITE_DATA}]" \
         -host_options block_script
   } else {
      run_block_script -script ${write_block_data_script} \
         -blocks ${DP_BLOCK_REFS} \
         -work_dir ./work_dir/write_data \
         -var_list "path_dir [file normalize ${WORK_DIR_WRITE_DATA}]"
   }

   # Write out hierarchy configuration file that can be used by unpack script to setup block directories
   set all_blocks [get_cells -hier -physical -filter hierarchy_type==block]

   set blocks($DESIGN_NAME) [get_attribute [get_cells -physical -filter hierarchy_type==block] ref_name]

   set top_block [current_block]
   foreach_in_collection block $all_blocks {
      current_block [get_attribute [get_cells -physical_context $block] ref_full_name]
      set idx [get_attribute [get_cells -physical_context $block] ref_name]
      set blocks($idx) [get_attribute [get_cells -quiet -physical -filter hierarchy_type==block] ref_name]
   }
   current_block $top_block

   proc print_hier {child_blocks depth} {
      incr depth
      if {[llength $child_blocks] != 0} {
         foreach child_block $child_blocks {
            # Indent line
            for { set i 1 } { $i <= $depth } { incr i } {
               puts -nonewline $::fout " "
            }
            puts $::fout $child_block
            print_hier $::blocks($child_block) $depth
        }
     } else {
        return
     }
   }
   set fout [open ${WORK_DIR_WRITE_DATA}/design_hier.cfg w]
   print_hier $DESIGN_NAME -1
   close $fout
}

print_message_info -ids * -summary
echo [date] > write_data

exit 
