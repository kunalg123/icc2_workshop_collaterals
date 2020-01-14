##########################################################################################
# Tool: IC Compiler II 
# Script: init_dp.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Create and read the design   
####################################
if {[file exists ${WORK_DIR}/$DESIGN_LIBRARY]} {
   file delete -force ${WORK_DIR}/${DESIGN_LIBRARY}
}

# NOTE: The library will not appear on disk until you save
set create_lib_cmd "create_lib ${WORK_DIR}/$DESIGN_LIBRARY"
if {[file exists [which $TECH_FILE]]} {
   lappend create_lib_cmd -tech $TECH_FILE ;# recommended
} elseif {$TECH_LIB != ""} {
   lappend create_lib_cmd -use_technology_lib $TECH_LIB ;# optional
}
lappend create_lib_cmd -ref_libs $REFERENCE_LIBRARY
puts "RM-info : $create_lib_cmd"
eval ${create_lib_cmd}

if {$DP_FLOW == "hier" && $BOTTOM_BLOCK_VIEW == "abstract"} {
   # Read in the DESIGN_NAME outline.  This will create the outline 
   puts "RM-info : Reading verilog outline (${VERILOG_NETLIST_FILES})"
   read_verilog_outline -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
} else {
   # Read in the full DESIGN_NAME.  This will create the DESIGN_NAME view in the database
   puts "RM-info : Reading full chip verilog (${VERILOG_NETLIST_FILES})"
   read_verilog -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
}


## Technology setup for routing layer direction, offset, site default, and site symmetry.
#  If TECH_FILE is specified, they should be properly set.
#  If TECH_LIB is used and it does not contain such information, then they should be set here as well.
if {$TECH_FILE != "" || ($TECH_LIB != "" && !$TECH_LIB_INCLUDES_TECH_SETUP_INFO)} {
   if {[file exists [which $TCL_TECH_SETUP_FILE]]} {
      puts "RM-info : Sourcing [which $TCL_TECH_SETUP_FILE]"
      source -echo $TCL_TECH_SETUP_FILE
   } elseif {$TCL_TECH_SETUP_FILE != ""} {
      puts "RM-error : TCL_TECH_SETUP_FILE($TCL_TECH_SETUP_FILE) is invalid. Please correct it."
   }
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

if {[file exists [which $TCL_TIMING_RULER_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_TIMING_RULER_SETUP_FILE]"
   source -echo $TCL_TIMING_RULER_SETUP_FILE
} else {
   puts "RM-warning : TCL_TIMING_RULER_SETUP_FILE not found or not specified. Timing ruler will not work accurately if it is not defined"
}

##################################################################################################
## 				Routing settings						##
##################################################################################################
## Set max routing layer
if {$MAX_ROUTING_LAYER != ""} {set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER}
## Set min routing layer
if {$MIN_ROUTING_LAYER != ""} {set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER}

####################################
# Check Design: Pre-Floorplanning
####################################
if {$CHECK_DESIGN} { 
   redirect -file ${REPORTS_DIR_INIT_DP}/check_design.pre_floorplan \
    {check_design -ems_database check_design.pre_floorplan.ems -checks dp_pre_floorplan}
}

####################################
# Floorplanning
####################################
## Floorplanning by reading $DEF_FLOORPLAN_FILES (supports multiple DEF files)
#  Script firstly checks if all the specified DEF files are valid, if not, read_def is skipped
if {$DEF_FLOORPLAN_FILES != ""} {
   set RM_DEF_FLOORPLAN_FILE_is_not_found FALSE
   foreach def_file $DEF_FLOORPLAN_FILES {
      if {![file exists [which $def_file]]} {
         puts "RM-error : DEF floorplan file ($def_file) is invalid."
         set RM_DEF_FLOORPLAN_FILE_is_not_found TRUE
      }
   }

   if {!$RM_DEF_FLOORPLAN_FILE_is_not_found} {
      if {[file exists [which $TCL_PHYSICAL_CONSTRAINTS_FILE]]} {
         puts "RM-info : Creating floorplan from TCL file TCL_PHYSICAL_CONSTRAINTS_FILE ($TCL_PHYSICAL_CONSTRAINTS_FILE)"
         source -echo -verbose $TCL_PHYSICAL_CONSTRAINTS_FILE
      }
      set read_def_cmd "read_def [list $DEF_FLOORPLAN_FILES]"
      if {$DEF_SITE_NAME_PAIRS != ""} {lappend read_def_cmd -convert $DEF_SITE_NAME_PAIRS}
      puts "RM-info : Creating floorplan from DEF file DEF_FLOORPLAN_FILES ($DEF_FLOORPLAN_FILES)"
      puts "RM-info: $read_def_cmd"
      eval ${read_def_cmd}
   } else {
      puts "RM-error : At least one of the DEF_FLOORPLAN_FILES specified is invalid. Pls correct it."
      puts "RM-info: Skipped reading of DEF_FLOORPLAN_FILES"
   }

} elseif {[file exists [which $TCL_PHYSICAL_CONSTRAINTS_FILE]]} {
   puts "RM-info : Creating floorplan from TCL file TCL_PHYSICAL_CONSTRAINTS_FILE ($TCL_PHYSICAL_CONSTRAINTS_FILE)"
   source -echo -verbose $TCL_PHYSICAL_CONSTRAINTS_FILE
} else {
   #######################################
   ## Floorplanning : initialize_floorplan
   #######################################
   ## Perform initialize_floorplan if neither DEF_FLOORPLAN_FILES nor TCL_PHYSICAL_CONSTRAINTS_FILE were specified. 
   ## If user still needs to generate rows, tracks, core area, etc... not included in DEF, pls modify the script 
   ## and run initial_floorplan with additional -keep* options. 
   ## Usage: initialize_floorplan    # Perform initializing floorplan in design planning
   ##        [-keep_boundary]       (keep existing boundary)
   ##        [-keep_pg_route]       (keep pg routes)
   ##        [-keep_all]            (keep all routes, placement except boundary)
   ##        [-keep_detail_route]   (keep routes of all nets except pg net)
   ##        [-keep_placement design type list]
   ##                               (specify which type should be kept: 
   ##                                Values: all, block, io, macro, 
   puts "RM-info: creating floorplan using initialize_floorplan"
   initialize_floorplan -core_utilization 0.6
}

###########################################
## General process node specific settings
###########################################
puts "RM-info: Sourcing [which settings.init_dp.tcl]"
source -echo ./rm_icc2_dp_scripts/settings.init_dp.tcl

############################################################################
# Commit each block to its own library and add the block library as 
# a reference library
############################################################################
if {[file exists [which $TCL_PRE_COMMIT_FILE]]} {
   puts "RM-info : Loading TCL_PRE_COMMIT_FILE file ($TCL_PRE_COMMIT_FILE)"
   source -echo $TCL_PRE_COMMIT_FILE
} elseif {$TCL_PRE_COMMIT_FILE != ""} {
   puts "RM-error: TCL_PRE_COMMIT_FILE file ($TCL_PRE_COMMIT_FILE) is invalid. Please correct it."
}

if {$DP_FLOW == "hier"} {
   set cd [current_design]

   # Derive block instances from block references if not already defined.
   set DP_BLOCK_INSTS ""
   foreach ref "$DP_BLOCK_REFS" {
      set DP_BLOCK_INSTS "$DP_BLOCK_INSTS [get_object_name [get_cells -hier -filter ref_name==$ref]]"
   }

   # copy_lib -from_lib -to_lib does not support paths to the libraries
   set pwd [pwd]
   cd ${WORK_DIR}
   foreach ref ${DP_BLOCK_REFS} {
      puts "RM-info : Creating ${ref}${LIBRARY_SUFFIX}"
      file delete -force -- ${ref}${LIBRARY_SUFFIX}
      copy_lib -to_lib ${ref}${LIBRARY_SUFFIX} -no_designs
      set_attribute -object ${ref}${LIBRARY_SUFFIX} -name use_hier_ref_libs -value true
   }
   cd $pwd

   save_lib -all

   # Create blackboxes
   foreach ref ${DP_BB_BLOCK_REFS} {
      # Create the black boxes, and set the area if defined, otherwise
      set inst [index_collection [filter_collection [get_cells $DP_BLOCK_INSTS] ref_name==$ref] 0]
      puts "RM-info : Creating blackbox $ref into library ${ref}${LIBRARY_SUFFIX}"
      if {[info exists DP_BB_BLOCKS($ref,area)]} {
        create_blackbox -library ${ref}${LIBRARY_SUFFIX} -target_boundary_area $DP_BB_BLOCKS($ref,area) $inst
      } elseif {[info exists DP_BB_BLOCKS($ref,boundary)]} {
        create_blackbox -library ${ref}${LIBRARY_SUFFIX} -boundary $DP_BB_BLOCKS($ref,boundary) $inst
      } else {
        puts "RM-error : Black boxes are defined as $DP_BB_BLOCK_REFS, but have no area or boundary, assign an area in setup.tcl"
        error "Stopped due to above RM-error"
      }
   }

   # Commit all non-black box blocks
   foreach ref ${DP_BLOCK_REFS} {
     if {[lsearch $DP_BB_BLOCK_REFS $ref] < 0} {
       puts "RM-info : Committing block $ref into library ${ref}${LIBRARY_SUFFIX}"
       commit_block -library ${ref}${LIBRARY_SUFFIX} $ref
     }
   }

   # Add child block reference to parent block
   foreach inst ${DP_BLOCK_INSTS} {
      # Add a reference to any child blocks
      set ref_lib_name [get_attribute [get_cells $inst] ref_lib_name]
      set parent_ref_lib_name [get_attribute [get_cells $inst] parent_block.lib_name]
      # Check to see if ref lib already exists in the case of MIB
      if {[lsearch [get_attribute [get_libs $parent_ref_lib_name] ref_libs] "./${ref_lib_name}"] < 0} {
         puts "RM-info : Adding ./${ref_lib_name} as a reference of ${parent_ref_lib_name}"
         set_ref_libs -library ${parent_ref_lib_name} -add ./${ref_lib_name}
      }
   }
}

# Setup distributed host options for blocks
if {[file exist $BLOCK_DIST_JOB_FILE]} {
   source -echo $BLOCK_DIST_JOB_FILE
}

################################
## Post-init_dp customizations
################################
if {[file exists [which $TCL_USER_INIT_DP_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_INIT_DP_POST_SCRIPT]"
   source $TCL_USER_INIT_DP_POST_SCRIPT
} elseif {$TCL_USER_INIT_DP_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_INIT_DP_POST_SCRIPT($TCL_USER_INIT_DP_POST_SCRIPT) is invalid. Please correct it."
}

if {$COMPRESS_LIBS} {
  save_lib -all -compress
} else {
  save_lib -all
}


print_message_info -ids * -summary
echo [date] > init_dp

exit 
