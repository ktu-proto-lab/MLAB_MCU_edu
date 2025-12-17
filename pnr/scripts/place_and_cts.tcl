
# No scan chain so ignore scan DFFS
set_db place_global_ignore_scan true

set_db opt_fix_fanout_load true
set_db opt_detail_drv_failure_reason true

#two attributes to limit local density
set_db place_global_max_density 0.85

# Route with Metals 1 - 5
set_db design_top_routing_layer 5

#set_db opt_max_density 0.80
place_opt_design -report_dir Reports/Place

# Isdelioja pin'us pagal paplace'inta dizaina
#assign_io_pins    

# to make sure that the pins are legalized 
#check_pin_assignment

# Pridedame tielow celes kurios palaikys 0 verte to reikalaujanciuose prievaduose
add_tieoffs -lib_cell {LOGIC1JI LOGIC0JI} -prefix LTIE

write_db dbs/place.enc

#################################################
# Clock Tree Synthesis (Clock medzio generavimas)
#################################################

# Set buffers and inverters for clock tree (aktualu jei yra atskiros celes butent clockui!)
#set_db cts_inverter_cells {INJIX1 INJIX0 INJIX2 INJIX12 INJIX16 INJIX20 INJIX4 INJIX8 INVJIX1 INVJIX0 INVJIX2 INVJIX12 INVJIX16 INVJIX20 INVJIX4 INVJIX8}
#set_db cts_buffer_cells {BUFJIX1 BUFJIX2 BUFJIX12 BUFJIX16 BUFJIX20 BUFJIX4 BUFJIX8 BUJIX1 BUJIX2 BUJIX12 BUJIX16 BUJIX20 BUJIX4 BUJIX8}
#set_db cts_update_clock_latency false

# Max fanout of 30 for JIX8 approximating fanout as 8*4=32
set_db cts_max_fanout 30

# Use JIX8 and larger buffers/inverters
set_db cts_buffer_cells {BUFJIX8 BUFJIX12 BUFJIX16 BUFJIX20}
set_db cts_inverter_cells {INVJIX8 INVJIX12 INVJIX16 INVJIX20} 

# Clock concurrent optimization - optimizes clock tree and datapath based on timing constraints
#ccopt_design
clock_opt_design -report_dir Reports/CTS_OPT

set_db place_global_max_density 0.90 

report_clock_trees -summary -out_file Reports/CTS/report_clock_trees.rpt
report_skew_groups  -summary -out_file Reports/CTS/report_ccopt_skew_groups.rpt

time_design -post_cts -report_dir Reports/STA -report_prefix cts -num_paths 20 -timing_debug_report
time_design -post_cts -report_dir Reports/STA -report_prefix cts -num_paths 20 -timing_debug_report -hold


# Commands to switch to propogated clock mode (before it was in ideal mode - all seq elements triggered at the same time)
# set_interactive_constraint_modes  [all_constraint_modes -active]
# reset_clock_tree_latency          [all_clocks]
# set_propagated_clock              [all_clocks]
# set_interactive_constraint_modes  {}

# Optimizacija ir taimingas

opt_design  -post_cts        -report_dir Reports/CTS -report_prefix opt_cts
time_design -post_cts        -report_dir Reports/STA -report_prefix opt_cts

opt_design  -post_cts -hold  -report_dir Reports/CTS -report_prefix opt_cts
time_design -post_cts -hold  -report_dir Reports/STA -report_prefix opt_cts

# Issaugome projekta
write_db dbs/cts.enc
