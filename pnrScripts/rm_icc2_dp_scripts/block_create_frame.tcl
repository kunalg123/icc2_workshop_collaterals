##########################################################################################
# Tool: IC Compiler II 
# Script: block_create_frame.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

#Send jobID back to parent for tracking purposes
if {[info exist env(JOB_ID)]} {
   puts "Block: $block_refname JobID: $env(JOB_ID) - START"
}

open_block -read $block_libfilename:$block_refname

# The tool creates a zero-spacing routing blockage only on the specified layer and the layers below it
# By default all layers below $MIN_ROUTING_LAYER are blocked
create_frame -block_all $MIN_ROUTING_LAYER

close_lib
puts "Block: $block_refname - FINISHED"
