
set_db opt_verbose true

# First NanoRoute for timing-driven and SI-driven routing
set_db route_design_with_timing_driven true 
set_db route_design_with_si_driven true
check_design -type route -out_file Reports/route_check
route_design -global_detail

# Detailed route wire optimization. Basically - DFM routing
set_db route_design_with_timing_driven false 
set_db route_design_detail_post_route_spread_wire true 
set_db route_design_detail_use_multi_cut_via_effort high
set_db route_design_concurrent_minimize_via_count_effort high

check_design -type route -out_file Reports/dfm_route_check

route_design -wire_opt     
set_db route_design_with_timing_driven true

# Fix setup and hold
opt_design -post_route -hold -setup -report_dir Reports/Route -report_prefix opt_route

time_design -post_route -hold -report_dir Reports/STA -report_prefix opt_route
time_design -post_route -report_dir Reports/STA -report_prefix opt_route

# Check if no route violations present at this moment, if present maybe route_eco
# write_db dbs/intermediate_route.enc

#eco route to fix shorts cause by min metalarea
# route_eco

write_db dbs/route.enc


# ecoRoute multiple times (goes into violations and tries to selectively reroute)