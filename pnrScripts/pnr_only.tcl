set_host_options -max_cores 8
remove_corners [get_corners estimated_corner]
set_app_options -name place.coarse.continue_on_missing_scandef -value true
place_opt
clock_opt
route_auto -max_detail_route_iterations 5
set FILLER_CELLS [get_object_name [sort_collection -descending [get_lib_cells NangateOpenCellLibrary/FILL*] area]]
create_stdcell_fillers -lib_cells $FILLER_CELLS
save_lib -all
write_def raven_wrapper.pnr.def
write_verilog raven_wrapper.pnr.v
