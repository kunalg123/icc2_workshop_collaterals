##########################################################################################
# Tool: IC Compiler II 
# Script: load_block_budgets.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

#Send jobID back to parent for tracking purposes
if {[info exist env(JOB_ID)]} {
   puts "Block: $block_refname JobID: $env(JOB_ID) - START"
}

open_block $block_libfilename:$block_refname
reopen_block -edit
# This is necessary to protect against unexpected closing of the block prior to saving
save_block

if {[file exists ./block_budgets/$block_refname_no_label/top.tcl]} {
   puts "Block: $block_refname_no_label - Loading budgets"
   source -echo ./block_budgets/$block_refname_no_label/top.tcl
} else {
   puts "RM-error: No budgets loaded for block: $block_refname_no_label"
}

save_lib
close_lib
puts "Block: $block_refname - FINISHED"
