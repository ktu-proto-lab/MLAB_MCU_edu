
# New floorplan to put memories together also moving IO
# create_floorplan -site CoreSite -box_size 0.0 0.0 1533 1659 310.0 310.0 1223 1349 345 345 1188 1314
create_floorplan -site CoreSite -box_size 0.0 0.0 1520 1520 180 180 1320 1320 225 225 1275 1275

# Nuskaitome IO celiu isdeliojimo konfiguracijos faila 
read_io_file IO_configs/chip_top_librelane_match.io -no_die_size_adjust 
#read_io_file pad_configs/ibex_simple_system_V1.save.io -no_die_size_adjust 
# create_floorplan -site CoreSite -core_density_size 1 0.7 35 35 35 35

# Tikriname ar teisingai apibreztas floorplan
check_floorplan -out_file Reports/floorplan_check

# Nustatom koordinaciu pradzios taska
update_origin -lower_left

#####################################
# IO filler'iai
#####################################
# Move ESDCLAMP away from IO pads to avoid TM2_b1R DRC
# add_io_fillers -cells vddpad -prefix IOFILLER_ESDCLAMP -side w
# move_obj -direction up -distance 20 {IOFILLER_ESDCLAMP_W_0 IOFILLER_ESDCLAMP_W_1 \
#  IOFILLER_ESDCLAMP_W_2 IOFILLER_ESDCLAMP_W_3 IOFILLER_ESDCLAMP_W_4 IOFILLER_ESDCLAMP_W_5}

# add_io_fillers -cells vddpad -prefix IOFILLER_ESDCLAMP -side n
# move_obj -direction right -distance 20 {IOFILLER_ESDCLAMP_N_0 IOFILLER_ESDCLAMP_N_1 \
#  IOFILLER_ESDCLAMP_N_2 IOFILLER_ESDCLAMP_N_3 IOFILLER_ESDCLAMP_N_4}

# add_io_fillers -cells vddpad -prefix IOFILLER_ESDCLAMP -side e
# move_obj -direction up -distance 20 {IOFILLER_ESDCLAMP_E_0 IOFILLER_ESDCLAMP_E_1 \
#  IOFILLER_ESDCLAMP_E_2 IOFILLER_ESDCLAMP_E_3 IOFILLER_ESDCLAMP_E_4 IOFILLER_ESDCLAMP_E_5}

# add_io_fillers -cells vddpad -prefix IOFILLER_ESDCLAMP -side s
# move_obj -direction right -distance 20 {IOFILLER_ESDCLAMP_S_0 IOFILLER_ESDCLAMP_S_1 \
#  IOFILLER_ESDCLAMP_S_2 IOFILLER_ESDCLAMP_S_3 IOFILLER_ESDCLAMP_S_4}

# # Uzpildome tarpustarp paduku kad apjungtume paduku maitinimus
# add_io_fillers -cells filler10u -prefix IOFILLER
# add_io_fillers -cells filler4u -prefix IOFILLER
# add_io_fillers -cells filler2u -prefix IOFILLER
# add_io_fillers -cells filler1u -prefix IOFILLER 
# #add_io_fillers -cells filler1u -prefix IOFILLER -fill_any_gap

# # Uzfiksuojame paduku ir filler'iu pozicijas kad optimizavimo irankiai ju nejudintu
# set_db [get_db insts -if {.name == CornerCell*}] .place_status fixed -verbose
# set_db [get_db insts -if {.name == IOFILLER*}] .place_status fixed -verbose
# set_db [get_db insts -if {.name == VDD*}] .place_status fixed -verbose 
# set_db [get_db insts -if {.name == VSS*}] .place_status fixed -verbose 
# set_db [get_db insts -if {.name == pad_*}] .place_status fixed -verbose 
# set_db [get_db insts -if {.name == GPIO*}] .place_status fixed -verbose

# Relative floorplan place macros
# create_relative_floorplan \
#     -ref_type core_boundary \
#     -ref ibex_simple_system \
#     -place imem/sram1 \
#     -horizontal_edge_separate {2 0 2} \
#     -vertical_edge_separate {0 0 0}

# create_relative_floorplan \
#     -ref_type core_boundary \
#     -ref ibex_simple_system \
#     -place imem/sram2 \
#     -horizontal_edge_separate {2 0 2} \
#     -vertical_edge_separate {2 0 2}

# create_relative_floorplan \
#     -ref_type core_boundary \
#     -ref ibex_simple_system \
#     -place dmem/sram \
#     -horizontal_edge_separate {0 0 0} \
#     -vertical_edge_separate {0 0 0}

set_db inst:chip_top/i_ibex_simple_system/dmem.sram .location {250 250}
set_db inst:chip_top/i_ibex_simple_system/dmem.sram .orient mx

set_db inst:chip_top/i_ibex_simple_system/imem.sram1 .location {820 250}
set_db inst:chip_top/i_ibex_simple_system/imem.sram1 .orient mx

set_db inst:chip_top/i_ibex_simple_system/imem.sram2 .location {820 920}
# set_db inst:chip_top/i_ibex_simple_system/imem.sram2 .orient mx



# Rotate dmem 180 degrees
# set_db inst:chip_top/i_ibex_simple_system/dmem.sram .orient mx

#set_macro_place_constraint -pg_resource_model golden_mimic_power_mesh.tcl 
#set_macro_place_constraint -min_space_to_core {6 6} 
#set_macro_place_constraint -min_space_to_macro {8 8}

#place_design -concurrent_macros 
#place_macro_detail 

set_instance_placement_status -all_hard_macros -status fixed

# delete_relative_floorplan -all

#####################################
# Pin placement
#####################################
# Ext pads
# create_pin_group -spread_pins -pins ext_pad* -name ext_pads

# create_pin_guide -edge 2 -offset_start 35 -offset_end 455 -pin_group ext_pads

# # All other pins
# create_pin_group -spread_pins -pins * -name all

# create_pin_guide -edge 3 -offset_start 470 -offset_end 35 -pin_group all 

# # Isdelioja pin'us pagal paplace'inta dizaina
# assign_io_pins    

# # Check if placement was legal
# check_pin_assignment -out_file Reports/check_pin_assign.rpt

# Issaugome floorplan'a
write_db dbs/floorplan.enc

