##########################################################################################
# Tool: IC Compiler II 
# Script: split_constraints.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

################################################################################
# Create and read the design	
################################################################################

set SUFFIX "_split" 

if {[file exists ${WORK_DIR}/${DESIGN_LIBRARY}${SUFFIX}]} {
   file delete -force ${WORK_DIR}/${DESIGN_LIBRARY}${SUFFIX}
}

set create_lib_cmd "create_lib ${WORK_DIR}/${DESIGN_LIBRARY}${SUFFIX}" ;

if {[file exists [which $TECH_FILE]]} {
   lappend create_lib_cmd -tech $TECH_FILE ;# recommended
} elseif {$TECH_LIB != ""} {
   lappend create_lib_cmd -use_technology_lib $TECH_LIB ;# optional
}
lappend create_lib_cmd -ref_libs $REFERENCE_LIBRARY
puts "RM-info : $create_lib_cmd"
eval $create_lib_cmd

   puts "RM-info : Reading verilog file(s) $VERILOG_NETLIST_FILES" 
   read_verilog -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES} 

# Load UPF file
if {[file exists [which $UPF_FILE]]} {
   puts "RM-info : Loading UPF file $UPF_FILE"
   load_upf $UPF_FILE
   if {[file exists [which $UPF_UPDATE_SUPPLY_SET_FILE]]} {
      puts "RM-info : Loading UPF update supply set file $UPF_UPDATE_SUPPLY_SET_FILE"
      load_upf $UPF_UPDATE_SUPPLY_SET_FILE
   }
} else {
   puts "RM-warning : UPF file not found"
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

if {[file exists [which $TCL_MCMM_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_MCMM_SETUP_FILE]"
   source -echo $TCL_MCMM_SETUP_FILE
} else {
   puts "RM-error : TCL_MCMM_SETUP_FILE not found or not specified."
}

# Adjust commit_upf after mcmm setup preventing iso rename. Refer to mv.cells.rename_isolation_cell_with_formal_name for details.
if {[file exists [which $UPF_FILE]]} {
   commit_upf
}

file delete -force split

# Derive block instances from block references if not already defined.
set DP_BLOCK_INSTS ""
foreach ref "$DP_BLOCK_REFS" {
   set DP_BLOCK_INSTS "$DP_BLOCK_INSTS [get_object_name [get_cells -hier -filter ref_name==$ref]]"
}

set_budget_options -add_blocks $DP_BLOCK_INSTS

if {$DP_INTERMEDIATE_LEVEL_BLOCK_REFS != ""} {
   if {$INTERMEDIATE_BLOCK_VIEW == "abstract"} {
     puts "RM-info : splitting constraints with -hier_abstract_subblocks"
     split_constraints -force -hier_abstract_subblocks $DP_INTERMEDIATE_LEVEL_BLOCK_REFS -nosplit
   } else {
     puts "RM-info : splitting constraints using -design_subblocks"
     split_constraints -design_subblocks $DP_INTERMEDIATE_LEVEL_BLOCK_REFS -nosplit
   }
} else {
   puts "RM-info : splitting constraints"
   split_constraints -nosplit
}

if {[info exists DP_BB_BLOCK_REFS] && $DP_BB_BLOCK_REFS != ""} {
   set DP_BB_BLOCK_INSTS ""
   foreach ref $DP_BB_BLOCK_REFS {
     set DP_BB_BLOCK_INSTS "$DP_BB_BLOCK_INSTS [get_object_name [get_cells -hier -filter ref_name==$ref]]"
   }
   set cb [current_block]
   foreach bb $DP_BB_BLOCK_INSTS { create_blackbox $bb }
   foreach bb $DP_BB_BLOCK_REFS {
      # If BB UPF provided, load it
      if {[info exists DP_BB_BLOCKS(${bb},upf)] && [file exists $DP_BB_BLOCKS(${bb},upf)]} {
         current_block ${bb}.design
         load_upf $DP_BB_BLOCKS(${bb},upf)
         commit_upf
         save_upf -for_empty_blackbox ./split/$bb/top.upf
         current_block $DESIGN_NAME
      }
      # if BB timing exists put it in split directory as well
      if {[info exists DP_BB_BLOCKS(${bb},timing)] && [file exists $DP_BB_BLOCKS(${bb},timing)]} {
         exec cat $DP_BB_BLOCKS(${bb},timing) >> ./split/$bb/top.tcl
      }
   }
}


close_lib 
file delete -force ${DESIGN_LIBRARY} 

print_message_info -ids * -summary
echo [date] > split_constraints

exit 
