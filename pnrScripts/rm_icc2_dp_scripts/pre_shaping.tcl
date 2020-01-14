##########################################################################################
# Tool: IC Compiler II 
# Script: pre_shaping.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Open design
####################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

if {$DP_FLOW == "hier" && $BOTTOM_BLOCK_VIEW == "abstract"} {
   open_block ${DESIGN_NAME}/${INIT_DP_LABEL_NAME}.outline
   save_block -hier -force \
      -label ${PRE_SHAPING_LABEL_NAME}
   close_lib -purge -force -all
   puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PRE_SHAPING_LABEL_NAME}.outline"
   open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PRE_SHAPING_LABEL_NAME}.outline -ref_libs_for_edit
} else {
   open_block ${DESIGN_NAME}/${INIT_DP_LABEL_NAME}
   save_block -force \
      -label ${PRE_SHAPING_LABEL_NAME}
   close_lib -purge -force -all
   puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PRE_SHAPING_LABEL_NAME}"
   open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PRE_SHAPING_LABEL_NAME} -ref_libs_for_edit
}

####################################
## PRE-pre_shaping customizations
####################################
if {[file exists [which $TCL_USER_PRE_SHAPING_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PRE_SHAPING_PRE_SCRIPT]"
   source $TCL_USER_PRE_SHAPING_PRE_SCRIPT
} elseif {$TCL_USER_PRE_SHAPING_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PRE_SHAPING_PRE_SCRIPT($TCL_USER_PRE_SHAPING_PRE_SCRIPT) is invalid. Please correct it."
}

if {$DP_FLOW == "hier"} {
   if {$CONSTRAINT_MAPPING_FILE != ""} {
      set_constraint_mapping_file $CONSTRAINT_MAPPING_FILE
   } else {
      if {![file exists "./split/mapfile"]} {
         puts "RM-error : Cannot find default mapping file ./split/mapfile. Please create or specify the mapping file using the CONSTRAINT_MAPPING_FILE variable in setup.tcl "
         error
    } else {
         puts "RM-warning : No CONSTRAINT_MAPPING_FILE set, setting the constraint mapping file to the default ./split/mapfile"
         set_constraint_mapping_file ./split/mapfile
         report_constraint_mapping_file
      }
   }

   if {$BOTTOM_BLOCK_VIEW == "abstract"} {
      ################################################################################
      # read in full verilog for the current DESIGN_NAME
      # only the top level will be read in, as we have already committed the blocks
      # This will create a top level DESIGN_NAME with black boxes for the blocks
      ################################################################################
      puts "RM-info : Expanding top level outline"
      expand_outline
  
      
      ####################################
      # Check Design: Pre-Placement Abstract
      ####################################
      if {$CHECK_DESIGN} { 
         redirect -file ${REPORTS_DIR_PRE_SHAPING}/check_design.pre_create_placement_abstract \
          {check_design -ems_database check_design.pre_create_placement_abstract.ems -checks dp_pre_create_placement_abstract}
      }

      # Create block placement abstracts in preparation for shaping
      #  load and commit the block UPF (based upon the UPF specified in the mapfile)
      #  load and commit the top UPF (based upon the UPF specified in the mapfile)
      if {$DISTRIBUTED} {
         puts "RM-info : Creating Placement Abstracts (distributed) for all blocks"
         create_abstract -force_recreate -placement -host_options block_script -all_blocks
      } else {
         puts "RM-info : Creating Placement Abstracts (non-distributed) for all blocks"
         create_abstract -force_recreate -placement -all_blocks
      }
   } else {
        if {$DISTRIBUTED} {
           puts "RM-info : Loading block constraints (distributed) for all blocks"
           load_block_constraints -type UPF -host_options block_script -all_blocks
        } else {
           puts "RM-info : Loading block constraints (non-distributed) for all blocks"
           load_block_constraints -type UPF -all_blocks
        }
   }
   # For hier designs load top TCL_UPF_FILE
   if {[file exists [which $TCL_UPF_FILE]]} {
      puts "RM-info : Loading tcl UPF file $TCL_UPF_FILE"
      source -echo $TCL_UPF_FILE
      commit_upf
   }
} else {
   ####################################
   # If flat flow, load UPF
   ####################################
   if {[file exists $UPF_FILE]} {
      puts "RM-info : Loading UPF file $UPF_FILE"
      load_upf $UPF_FILE
      if {[file exists [which $UPF_UPDATE_SUPPLY_SET_FILE]]} {
         puts "RM-info : Loading UPF update supply set file $UPF_UPDATE_SUPPLY_SET_FILE"
         load_upf $UPF_UPDATE_SUPPLY_SET_FILE
      }
   } else {
      puts "RM-warning : UPF file not found or not specified."
   }
 
   if {[file exists $TCL_UPF_FILE]} {
      puts "RM-info : Loading tcl UPF file $TCL_UPF_FILE"
      source -echo $TCL_UPF_FILE
   }
 
   commit_upf  
}

puts "RM-info : Running connect_pg_net -automatic on all blocks"
connect_pg_net -automatic -all_blocks

# It is expected that check_mv_design will complain about two items:
# ---------- Power domain rule ----------
# Error: Power domain '<domain name>' does not have any primary voltage area. (MV-019)
# This is because at this point in the flow the VA has not been created.  It will be created
# during block shaping.
#
# ---------- PG net rule ----------
# Error: PG net '<switched PG Net name>' has no valid PG source(s) or driver(s). (MV-007)
# At this point in the flow the PG switch has not been implemented so the switched power supplies
# do not have a driver.  This will be fixed during PG creation.

# check_mv_design -erc_mode and -power_connectivity
redirect -file $REPORTS_DIR_PRE_SHAPING/check_mv_design.erc_mode {check_mv_design -erc_mode}
redirect -file $REPORTS_DIR_PRE_SHAPING/check_mv_design.power_connectivity {check_mv_design -power_connectivity}

if {[file exists [which $TCL_TIMING_RULER_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_TIMING_RULER_SETUP_FILE]"
   source -echo $TCL_TIMING_RULER_SETUP_FILE
} else {
   puts "RM-warning : TCL_TIMING_RULER_SETUP_FILE not found or not specified. Timing ruler will not work accurately if it is not defined"
}

####################################
## Post-pre_shaping customizations
####################################
if {[file exists [which $TCL_USER_PRE_SHAPING_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PRE_SHAPING_POST_SCRIPT]"
   source $TCL_USER_PRE_SHAPING_POST_SCRIPT
} elseif {$TCL_USER_PRE_SHAPING_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PRE_SHAPING_POST_SCRIPT($TCL_USER_PRE_SHAPING_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

print_message_info -ids * -summary
echo [date] > pre_shaping

exit 
