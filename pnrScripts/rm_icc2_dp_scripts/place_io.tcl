##########################################################################################
# Tool: IC Compiler II 
# Script: place_io.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Open design
####################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

open_block ${DESIGN_NAME}/${PRE_SHAPING_LABEL_NAME} 


save_block -hier -force \
  -label ${PLACE_IO_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PLACE_IO_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${PLACE_IO_LABEL_NAME} -ref_libs_for_edit

####################################
## Pre-place_io customizations
####################################
if {[file exists [which $TCL_USER_PLACE_IO_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PLACE_IO_PRE_SCRIPT]"
   source $TCL_USER_PLACE_IO_PRE_SCRIPT
} elseif {$TCL_USER_PLACE_IO_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PLACE_IO_PRE_SCRIPT($TCL_USER_PLACE_IO_PRE_SCRIPT) is invalid. Please correct it."
}

##################################################
# load IO placement constraints
# at the very minimum you have to create IO guides
##################################################
if {[file exists [which $TCL_PAD_CONSTRAINTS_FILE]]} {
   puts "RM-info : Loading TCL_PAD_CONSTRAINTS_FILE file ($TCL_PAD_CONSTRAINTS_FILE)"
   source -echo $TCL_PAD_CONSTRAINTS_FILE

   puts "RM-info : running place_io"
   place_io
}

if {[file exists [which $TCL_RDL_FILE]]} {
   puts "RM-info : Loading TCL_RDL_FILE file ($TCL_RDL_FILE)"
   source -echo $TCL_RDL_FILE
}

set_attribute -objects [get_cells -quiet -filter is_io==true -hier]    -name status -value fixed
set_attribute -objects [get_cells -quiet -filter pad_cell==true -hier] -name status -value fixed

####################################
## Post-place_io customizations
####################################
if {[file exists [which $TCL_USER_PLACE_IO_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_PLACE_IO_POST_SCRIPT]"
   source $TCL_USER_PLACE_IO_POST_SCRIPT
} elseif {$TCL_USER_PLACE_IO_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_PLACE_IO_POST_SCRIPT($TCL_USER_PLACE_IO_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

print_message_info -ids * -summary
echo [date] > place_io

exit 
