puts "RM-info : Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II 
# Script: tech_setup.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################
## Set routing_direction and track_offset
if {$ROUTING_LAYER_DIRECTION_OFFSET_LIST != ""} {
	foreach direction_offset_pair $ROUTING_LAYER_DIRECTION_OFFSET_LIST {
		set layer [lindex $direction_offset_pair 0]
		set direction [lindex $direction_offset_pair 1]
		set offset [lindex $direction_offset_pair 2]
		set_attribute [get_layers $layer] routing_direction $direction
		if {$offset != ""} {
			set_attribute [get_layers $layer] track_offset $offset
		}
	}
} else {
	puts "RM-error : ROUTING_LAYER_DIRECTION_OFFSET_LIST is not specified. You must manually set routing layer directions and offsets!"
}

## Set site default
if {$SITE_DEFAULT != ""} {
	set_attribute [get_site_defs] is_default false
	set_attribute [get_site_defs $SITE_DEFAULT] is_default true
}

## Set site symmetry
if {$SITE_SYMMETRY_LIST != ""} {
	foreach sym_pair $SITE_SYMMETRY_LIST {
		set site_name [lindex $sym_pair 0]
		set site_sym [lindex $sym_pair 1]
		set_attribute [get_site_defs $site_name] symmetry $site_sym
	}   	
}


puts "RM-info : Completed script [info script]\n"
