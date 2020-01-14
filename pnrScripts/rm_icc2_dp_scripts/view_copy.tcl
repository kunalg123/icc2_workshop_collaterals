##########################################################################################
# Tool: IC Compiler II 
# Script: view.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl > /dev/null 

echo ""

open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit > /dev/null

set SPLIT_CONSTRAINTS_VALUE ""            
set INIT_DP_VALUE ""            
set PRE_SHAPING_VALUE ""        
set PLACE_IO_VALUE ""           
set SHAPING_VALUE ""            
set PLACEMENT_VALUE ""          
set CREATE_POWER_VALUE ""       
set CLOCK_TRUNK_PLANNING_VALUE ""
set PLACE_PINS_VALUE ""         
set PRE_TIMING_VALUE ""         
set TIMING_ESTIMATION_VALUE ""  
set BUDGETING_VALUE ""          

set stage_list ""
set i 0
foreach stage "$SPLIT_CONSTRAINTS_LABEL_NAME $INIT_DP_LABEL_NAME $PRE_SHAPING_LABEL_NAME $PLACE_IO_LABEL_NAME $SHAPING_LABEL_NAME $PLACEMENT_LABEL_NAME $CREATE_POWER_LABEL_NAME $CLOCK_TRUNK_PLANNING_LABEL_NAME $PLACE_PINS_LABEL_NAME $PRE_TIMING_LABEL_NAME $TIMING_ESTIMATION_LABEL_NAME $BUDGETING_LABEL_NAME" { 
   if {[sizeof_collection [get_blocks -quiet -all $DESIGN_LIBRARY:$DESIGN_NAME/$stage.*]]} {
      incr i
      switch $stage \
         $SPLIT_CONSTRAINTS_LABEL_NAME    {echo "   $i. $SPLIT_CONSTRAINTS_LABEL_NAME";    set stage_list [lappend stage_list  $i]; set SPLIT_CONSTRAINTS_VALUE $i}    \
         $INIT_DP_LABEL_NAME              {echo "   $i. $INIT_DP_LABEL_NAME";              set stage_list [lappend stage_list  $i]; set INIT_DP_VALUE $i}              \
         $PRE_SHAPING_LABEL_NAME          {echo "   $i. $PRE_SHAPING_LABEL_NAME";          set stage_list [lappend stage_list  $i]; set PRE_SHAPING_VALUE $i}          \
         $PLACE_IO_LABEL_NAME             {echo "   $i. $PLACE_IO_LABEL_NAME";             set stage_list [lappend stage_list  $i]; set PLACE_IO_VALUE $i}             \
         $SHAPING_LABEL_NAME              {echo "   $i. $SHAPING_LABEL_NAME";              set stage_list [lappend stage_list  $i]; set SHAPING_VALUE $i}              \
         $PLACEMENT_LABEL_NAME            {echo "   $i. $PLACEMENT_LABEL_NAME";            set stage_list [lappend stage_list  $i]; set PLACEMENT_VALUE $i}            \
         $CREATE_POWER_LABEL_NAME         {echo "   $i. $CREATE_POWER_LABEL_NAME";         set stage_list [lappend stage_list  $i]; set CREATE_POWER_VALUE $i}         \
         $CLOCK_TRUNK_PLANNING_LABEL_NAME {echo "   $i. $CLOCK_TRUNK_PLANNING_LABEL_NAME"; set stage_list [lappend stage_list  $i]; set CLOCK_TRUNK_PLANNING_VALUE $i} \
         $PLACE_PINS_LABEL_NAME           {echo "   $i. $PLACE_PINS_LABEL_NAME";           set stage_list [lappend stage_list  $i]; set PLACE_PINS_VALUE $i}           \
         $PRE_TIMING_LABEL_NAME           {echo "   $i. $PRE_TIMING_LABEL_NAME";           set stage_list [lappend stage_list  $i]; set PRE_TIMING_VALUE $i}           \
         $TIMING_ESTIMATION_LABEL_NAME    {echo "   $i. $TIMING_ESTIMATION_LABEL_NAME";    set stage_list [lappend stage_list  $i]; set TIMING_ESTIMATION_VALUE $i}    \
         $BUDGETING_LABEL_NAME            {echo "   $i. $BUDGETING_LABEL_NAME";            set stage_list [lappend stage_list  $i]; set BUDGETING_VALUE $i}
   }
}

echo "\n   0. exit\n"; set stage_list [lappend stage_list 0]

while 1 {
   echo -n "Please enter a number to select an exisiting design library: "
   set answer [gets stdin]
   if {[lsearch -all $stage_list $answer] >= 0} {
      break
   } else {
      echo "The number you extered does not exisit."
   }
}

if {$answer == 0}                            {exit} 
if {$answer == $SPLIT_CONSTRAINTS_VALUE}     {set LABEL_NAME $SPLIT_CONSTRAINTS_LABEL_NAME}
if {$answer == $INIT_DP_VALUE}               {set LABEL_NAME $INIT_DP_LABEL_NAME}
if {$answer == $PRE_SHAPING_VALUE}           {set LABEL_NAME $PRE_SHAPING_LABEL_NAME}
if {$answer == $PLACE_IO_VALUE}              {set LABEL_NAME $PLACE_IO_LABEL_NAME}
if {$answer == $SHAPING_VALUE}               {set LABEL_NAME $SHAPING_LABEL_NAME}
if {$answer == $PLACEMENT_VALUE}             {set LABEL_NAME $PLACEMENT_LABEL_NAME}
if {$answer == $CREATE_POWER_VALUE}          {set LABEL_NAME $CREATE_POWER_LABEL_NAME}
if {$answer == $CLOCK_TRUNK_PLANNING_VALUE}  {set LABEL_NAME $CLOCK_TRUNK_PLANNING_LABEL_NAME}
if {$answer == $PLACE_PINS_VALUE}            {set LABEL_NAME $PLACE_PINS_LABEL_NAME}
if {$answer == $PRE_TIMING_VALUE}            {set LABEL_NAME $PRE_TIMING_LABEL_NAME}
if {$answer == $TIMING_ESTIMATION_VALUE}     {set LABEL_NAME $TIMING_ESTIMATION_LABEL_NAME}
if {$answer == $BUDGETING_VALUE}             {set LABEL_NAME $BUDGETING_LABEL_NAME}

if {[sizeof_collection [get_blocks -quiet ${DESIGN_NAME}/${LABEL_NAME}.design -all]]} {
   puts "RM-info : Opening block ${DESIGN_NAME}/${LABEL_NAME}.design"
   open_block ${DESIGN_NAME}/${LABEL_NAME}
   save_block -hier -force \
      -label copy
   close_lib -purge -force -all
   open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/copy -ref_libs_for_edit
} else {
   puts "RM-info : Opening block ${DESIGN_NAME}/${LABEL_NAME}.outline"
   open_block ${DESIGN_NAME}/${LABEL_NAME}.outline
   save_block -hier -force \
      -label copy
   close_lib -purge -force -all
   open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/copy.outline
}

# execute a couple commands to make the GUI work without delay
puts "RM-info : Running link_block"
link_block

