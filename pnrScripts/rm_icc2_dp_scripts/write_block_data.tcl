set start_cpu [cputime]
set sh_continue_on_error true
set monitor_cpu_memory true

set top 0
# Check to see if the top level block is running
if {![info exists block_libfilename]} {
   set block_refname_no_label [get_attribute [get_blocks] name]
   set block_refname [lindex [split [lindex [split [get_attribute [get_blocks] full_name] :] 1] .] 0]
   set top 1
} else {
   open_block $block_libfilename:$block_refname
}

if {[llength [get_corners estimated_corner -quiet]] != 0} {remove_corners estimated_corner}

# Remove constraint mapping file
set_constraint_mapping_file -reset

set path_dir $path_dir/[get_attribute -name name -objects [current_block]]

if {![file exists $path_dir]} { exec mkdir $path_dir }

# Write full UPF
save_upf $path_dir/${block_refname_no_label}.icc2.out.upf
# Write supplimental UPF
set_app_options -name mv.upf.enable_golden_upf -value true
save_upf -format supplemental $path_dir/${block_refname_no_label}.sup.icc2.out.upf

## write_verilog for LVS (with pg, and with physical only cells)
write_verilog -compress gzip -exclude {scalar_wire_declarations leaf_module_declarations empty_modules} -hierarchy all $path_dir/$block_refname_no_label.icc2.lvs.v

## write_verilog for Formality (with pg, no physical only cells, and no supply statements)
write_verilog -compress gzip -exclude {scalar_wire_declarations leaf_module_declarations end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells supply_statements} -hierarchy all ${path_dir}/${block_refname_no_label}.fm.v

## write_verilog for VC LP (with pg, yes physical_only cells, no diodes, and no supply statements)
write_verilog -compress gzip -exclude {scalar_wire_declarations leaf_module_declarations end_cap_cells well_tap_cells filler_cells pad_spacer_cells cover_cells diode_cells supply_statements} -hierarchy all ${path_dir}/${block_refname_no_label}.vc_lp.v

## write_verilog for PrimeTime (no pg, no physical only cells, and no supply statments)
write_verilog -compress gzip -exclude {scalar_wire_declarations leaf_module_declarations end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells supply_statements pg_netlist} -hierarchy all ${path_dir}/${block_refname_no_label}.pt.v

write_lef $path_dir/${block_refname_no_label}.lef

write_floorplan -compress gzip \
                -output $path_dir/${block_refname_no_label}.icc2.floorplan \
                -force \
                -nosplit \
                -format icc2

write_script -compress gzip \
             -output $path_dir/${block_refname_no_label}.icc2.ws \
             -force \
             -nosplit \
             -format icc2

if {![file exists $path_dir/${block_refname_no_label}.sdc]} { exec mkdir $path_dir/${block_refname_no_label}.sdc }
   foreach_in_collection sce [get_scenarios] {
       write_sdc -compress gzip \
                 -output $path_dir/${block_refname_no_label}.sdc/[get_object_name $sce].sdc \
                 -scenario $sce \
                 -nosplit 
}

write_floorplan -compress gzip \
                -output $path_dir/${block_refname_no_label}.icc.floorplan \
                -force \
                -nosplit \
                -format icc

write_script -compress gzip \
             -output $path_dir/${block_refname_no_label}.icc.ws \
             -force \
             -nosplit \
             -format icc

# The block is opened as read_only because it has an abstract.  The tool auto merges the abstract, 
# but the block is still read_only and cannot be saved.  So upgrade to writeable.
reopen_block $block_refname

save_lib -all

if { !$top } {
   close_lib
}
