
#####################################
# GLOBALUS MAZGAI
#####################################
# Susiejame maitinimo mazgus (nes jie nera aprasyt Verilog'e)
connect_global_net VDD -type pg_pin -pin_base_name VDD -inst_base_name *
connect_global_net VSS -type pg_pin -pin_base_name VSS -inst_base_name *
connect_global_net VDD -type tie_hi -inst_base_name *
connect_global_net VSS -type tie_lo -inst_base_name *
connect_global_net VDD -type pg_pin -pin_base_name VDDARRAY -inst_base_name *
connect_global_net VDD -type pg_pin -pin_base_name VDD! -inst_base_name *
connect_global_net VSS -type pg_pin -pin_base_name VSS! -inst_base_name *
connect_global_net VDD -type pg_pin -pin_base_name VDDARRAY! -inst_base_name *
connect_global_net VSS -type pg_pin -pin_base_name VSSCORE -inst_base_name *
connect_global_net VDD -type pg_pin -pin_base_name VDDCORE -inst_base_name *
connect_global_net VSSPAD -type pg_pin -pin_base_name VSSPAD -inst_base_name *
connect_global_net VDDPAD -type pg_pin -pin_base_name VDDPAD -inst_base_name *
#####################################
# Power Ring (Maitinimo ziedas)
#####################################
set_db add_rings_target default
set_db add_rings_extend_over_row 0
set_db add_rings_ignore_rows 0
set_db add_rings_avoid_short 0
set_db add_rings_skip_shared_inner_ring none
set_db add_rings_stacked_via_top_layer TopMetal2
set_db add_rings_stacked_via_bottom_layer Metal1
set_db add_rings_via_using_exact_crossover_size 1
set_db add_rings_orthogonal_only true
set_db add_rings_skip_via_on_pin {  standardcell }
set_db add_rings_skip_via_on_wire_shape {  noshape }
add_rings \
    -nets {VDD VSS} \
    -type core_rings \
    -follow core \
    -layer {top TopMetal2 bottom TopMetal2 left TopMetal1 right TopMetal1} \
    -width {top 2 bottom 2 left 2 right 2} \
    -spacing {top 2 bottom 2 left 2 right 2} \
    -offset {top 1.8 bottom 1.8 left 1.8 right 1.8} \
    -center 1 \
    -threshold 0 \
    -jog_distance 0 \
    -snap_wire_center_to_grid none \
    -use_wire_group 1 \
    -use_wire_group_bits 4 \
    -use_interleaving_wire_group 1

# Power Ring prijungimas prie paduku
set_db route_special_via_connect_to_shape { ring }
route_special \
    -connect pad_pin \
    -layer_change_range { Metal1(1) TopMetal2(7) } \
    -block_pin_target nearest_target \
    -pad_pin_port_connect {all_port all_geom} \
    -pad_pin_target nearest_target \
    -allow_jogging 0 \
    -crossover_via_layer_range { Metal1(1) TopMetal2(7) } \
    -nets { VDD VSS } \
    -allow_layer_change 0 \
    -target_via_layer_range { Metal1(1) TopMetal2(7) }

#####################################
# Stripes
#####################################
#####################################
# Metal5 (Over SRAMs)
#####################################
set_db add_stripes_ignore_block_check false
set_db add_stripes_break_at none
set_db add_stripes_route_over_rows_only false
set_db add_stripes_rows_without_stripes_only false
set_db add_stripes_extend_to_closest_target ring
set_db add_stripes_stop_at_last_wire_for_area false
set_db add_stripes_partial_set_through_domain false
set_db add_stripes_ignore_non_default_domains false
set_db add_stripes_trim_antenna_back_to_shape none
set_db add_stripes_spacing_type edge_to_edge
set_db add_stripes_spacing_from_block 0
set_db add_stripes_stripe_min_length stripe_width
set_db add_stripes_stacked_via_top_layer TopMetal2
set_db add_stripes_stacked_via_bottom_layer Metal1
set_db add_stripes_via_using_exact_crossover_size false
set_db add_stripes_split_vias false
set_db add_stripes_orthogonal_only true
set_db add_stripes_allow_jog { block_ring }
set_db add_stripes_skip_via_on_pin {  pad  cover  standardcell }
set_db add_stripes_skip_via_on_wire_shape {  blockring  blockwire  corewire   followpin  fillwire   iowire     padring    stripe     noshape   }
add_stripes \
    -nets {VDD VSS} \
    -layer Metal5 \
    -direction horizontal \
    -width 2 \
    -spacing 4 \
    -set_to_set_distance 12 \
    -start_from top \
    -stop_offset 632.9 \
    -switch_layer_over_obs false \
    -max_same_layer_jog_length 2 \
    -pad_core_ring_top_layer_limit TopMetal2 \
    -pad_core_ring_bottom_layer_limit Metal1 \
    -block_ring_top_layer_limit TopMetal2 \
    -block_ring_bottom_layer_limit Metal1 \
    -use_wire_group 0 \
    -snap_wire_center_to_grid none


# Block ring around dmem
set_db add_rings_target default
set_db add_rings_extend_over_row 0
set_db add_rings_ignore_rows 0
set_db add_rings_avoid_short 0
set_db add_rings_skip_shared_inner_ring none
set_db add_rings_stacked_via_top_layer TopMetal2
set_db add_rings_stacked_via_bottom_layer Metal1
set_db add_rings_via_using_exact_crossover_size 1
set_db add_rings_orthogonal_only true
set_db add_rings_skip_via_on_pin {  standardcell }
set_db add_rings_skip_via_on_wire_shape {  noshape }
add_rings \
    -nets {VDD VSS} \
    -around user_defined \
    -user_defined_region {319 319 319 681.28 761.46 681.28 761.46 319 319 319} \
    -type block_rings \
    -layer {top Metal5 bottom Metal5 left TopMetal1 right TopMetal1} \
    -width {top 2 bottom 2 left 2 right 2} \
    -spacing {top 2 bottom 2 left 2 right 2} \
    -offset {top 1.8 bottom 1.8 left 1.8 right 1.8} \
    -center 0 \
    -extend_corners {tl rb } \
    -skip_side {bottom left } \
    -threshold 0 \
    -jog_distance 0 \
    -snap_wire_center_to_grid none

# Metal5 for DMEM
gui_select -point {751.20500 660.19400}
set_db add_stripes_ignore_block_check false
set_db add_stripes_break_at none
set_db add_stripes_route_over_rows_only false
set_db add_stripes_rows_without_stripes_only false
set_db add_stripes_extend_to_closest_target ring
set_db add_stripes_stop_at_last_wire_for_area false
set_db add_stripes_partial_set_through_domain false
set_db add_stripes_ignore_non_default_domains false
set_db add_stripes_trim_antenna_back_to_shape none
set_db add_stripes_spacing_type edge_to_edge
set_db add_stripes_spacing_from_block 0
set_db add_stripes_stripe_min_length stripe_width
set_db add_stripes_stacked_via_top_layer TopMetal2
set_db add_stripes_stacked_via_bottom_layer Metal1
set_db add_stripes_via_using_exact_crossover_size false
set_db add_stripes_split_vias false
set_db add_stripes_orthogonal_only true
set_db add_stripes_allow_jog { block_ring }
set_db add_stripes_skip_via_on_pin {  pad  cover  standardcell }
set_db add_stripes_skip_via_on_wire_shape {  blockwire  corewire   followpin  fillwire   iowire     padring    stripe     noshape   }
add_stripes -nets {VDD VSS} -layer Metal5 -direction horizontal -width 2 -spacing 4 -set_to_set_distance 12 -over_power_domain 1 -start_from bottom -stop_offset 0 -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit TopMetal2 -pad_core_ring_bottom_layer_limit Metal1 -block_ring_top_layer_limit TopMetal2 -block_ring_bottom_layer_limit Metal1 -use_wire_group 0 -snap_wire_center_to_grid none

#####################################
# TopMetal1
#####################################
set_db add_stripes_ignore_block_check false
set_db add_stripes_break_at none
set_db add_stripes_route_over_rows_only false
set_db add_stripes_rows_without_stripes_only false
set_db add_stripes_extend_to_closest_target ring
set_db add_stripes_stop_at_last_wire_for_area false
set_db add_stripes_partial_set_through_domain false
set_db add_stripes_ignore_non_default_domains false
set_db add_stripes_trim_antenna_back_to_shape none
set_db add_stripes_spacing_type edge_to_edge
set_db add_stripes_spacing_from_block 0
set_db add_stripes_stripe_min_length stripe_width
set_db add_stripes_stacked_via_top_layer TopMetal2
set_db add_stripes_stacked_via_bottom_layer Metal1
set_db add_stripes_via_using_exact_crossover_size false
set_db add_stripes_split_vias false
set_db add_stripes_orthogonal_only true
set_db add_stripes_allow_jog { block_ring }
set_db add_stripes_skip_via_on_pin {  pad  block  cover  standardcell }
set_db add_stripes_skip_via_on_wire_shape {  blockwire  corewire   followpin  fillwire   iowire     padring    noshape   }
add_stripes -nets {VDD VSS} -layer TopMetal1 -direction vertical -width 2 -spacing 22 -set_to_set_distance 48 -start_from left -start_offset 1 -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit TopMetal2 -pad_core_ring_bottom_layer_limit TopMetal1 -block_ring_top_layer_limit TopMetal2 -block_ring_bottom_layer_limit Metal5 -use_wire_group 0 -snap_wire_center_to_grid none

#####################################
# TopMetal2
#####################################
# Individual stripes from VDDCORE and VSS CORE
#metal 7
# To VSS pads
set_db add_stripes_ignore_block_check false
set_db add_stripes_break_at none
set_db add_stripes_route_over_rows_only false
set_db add_stripes_rows_without_stripes_only false
set_db add_stripes_extend_to_closest_target ring
set_db add_stripes_stop_at_last_wire_for_area false
set_db add_stripes_partial_set_through_domain false
set_db add_stripes_ignore_non_default_domains false
set_db add_stripes_trim_antenna_back_to_shape none
set_db add_stripes_spacing_type edge_to_edge
set_db add_stripes_spacing_from_block 0
set_db add_stripes_stripe_min_length stripe_width
set_db add_stripes_stacked_via_top_layer TopMetal2
set_db add_stripes_stacked_via_bottom_layer Metal1
set_db add_stripes_via_using_exact_crossover_size false
set_db add_stripes_split_vias false
set_db add_stripes_orthogonal_only true
set_db add_stripes_allow_jog { block_ring }
set_db add_stripes_skip_via_on_pin {  pad  cover  standardcell block}
set_db add_stripes_skip_via_on_wire_shape {  blockwire  corewire   followpin  fillwire   iowire     padring    noshape   }
add_stripes \
    -nets {VDD VSS VSS VDD} \
    -layer TopMetal2 \
    -direction horizontal \
    -width 10 \
    -spacing 5 \
    -start_from bottom \
    -start 952.5 \
    -stop 1007.5 \
    -number_of_sets 1 \
    -switch_layer_over_obs false \
    -max_same_layer_jog_length 2 \
    -pad_core_ring_top_layer_limit TopMetal2 \
    -pad_core_ring_bottom_layer_limit Metal1 \
    -block_ring_top_layer_limit TopMetal2 \
    -block_ring_bottom_layer_limit Metal1 \
    -use_wire_group 0 \
    -snap_wire_center_to_grid none

add_stripes -nets {VDD VSS VSS VDD} \
            -layer TopMetal2 \
            -direction horizontal \
            -width 10 \
            -spacing 5 \
            -start_from bottom \
            -start 472.5 \
            -stop 527.5 \
            -number_of_sets 1

#To VDD pads
add_stripes -nets {VSS VDD VDD VSS} \
            -layer TopMetal2 \
            -direction horizontal \
            -width 10 \
            -spacing 5 \
            -start_from bottom \
            -start 1112.5 \
            -stop 1167.5 \
            -number_of_sets 1

add_stripes -nets {VSS VDD VDD VSS} \
            -layer TopMetal2 \
            -direction horizontal \
            -width 10 \
            -spacing 5 \
            -start_from bottom \
            -start 792.5 \
            -stop 847.5 \
            -number_of_sets 1

#prevent placement of stdcells to reduce congestion also cuts followpins
create_place_halo -halo_deltas {0.96 0.96 0.96 0.96} -all_blocks

#reduce wiring close to pinsf
create_route_halo -all_blocks -space 0.18 -bottom_layer Metal1 -top_layer TopMetal2


# Blockages for auto stripe generation for the rest of the design
create_route_blockage -area 310 947.5 1500 1012.5 -layer TopMetal2
create_route_blockage -area 310 467.5 1500 532.5 -layer TopMetal2
create_route_blockage -area 310 1107.5 1500 1172.5 -layer TopMetal2
create_route_blockage -area 310 787.5 1500 852.5 -layer TopMetal2

# blockage for block ringf
# create_route_blockage -area 310 683.08 1500 689.08 -layer TopMetal2

#Stripes for rest of the design
set_db add_stripes_ignore_block_check false
set_db add_stripes_break_at none
set_db add_stripes_route_over_rows_only false
set_db add_stripes_rows_without_stripes_only false
set_db add_stripes_extend_to_closest_target ring
set_db add_stripes_stop_at_last_wire_for_area false
set_db add_stripes_partial_set_through_domain false
set_db add_stripes_ignore_non_default_domains false
set_db add_stripes_trim_antenna_back_to_shape none
set_db add_stripes_spacing_type edge_to_edge
set_db add_stripes_spacing_from_block 0
set_db add_stripes_stripe_min_length stripe_width
set_db add_stripes_stacked_via_top_layer TopMetal2
set_db add_stripes_stacked_via_bottom_layer Metal4
set_db add_stripes_via_using_exact_crossover_size false
set_db add_stripes_split_vias false
set_db add_stripes_orthogonal_only true
set_db add_stripes_allow_jog { block_ring }
set_db add_stripes_skip_via_on_pin {  pad  standardcell block}
set_db add_stripes_skip_via_on_wire_shape {  noshape   }
add_stripes -nets {VDD VSS} \
            -layer TopMetal2 \
            -direction horizontal \
            -width 10 \
            -spacing 10 \
            -set_to_set_distance 40 \
            -start_from bottom \
            -start_offset 5 \
            -switch_layer_over_obs false \
            -max_same_layer_jog_length 2 \
            -pad_core_ring_top_layer_limit TopMetal2 \
            -pad_core_ring_bottom_layer_limit TopMetal1 \
            -block_ring_top_layer_limit TopMetal2 \
            -block_ring_bottom_layer_limit TopMetal1 \
            -use_wire_group 0 \
            -snap_wire_center_to_grid none
            # -stop_offset 10

delete_obj [get_db route_blockages]

# Routing blockages over SRAMS to make sure no routing on M1-M5
# dmem/sram
create_route_blockage -area 344.82 344.82 761.46 681.28 -layer {Metal1 Metal2 Metal3 Metal4 Metal5}
# imem/sram1
create_route_blockage -area 344.82 977.72 761.46 1314.18 -layer {Metal1 Metal2 Metal3 Metal4 Metal5}
# imem/sram2
create_route_blockage -area 771.54 977.72 1188.18 1314.18 -layer {Metal1 Metal2 Metal3 Metal4 Metal5}

# Place blockage between SRAMS
create_place_blockage -type hard -rects { { 761.46 977.71 771.54 1315.00 } } -name hardBlockage1

# Place blockage on the right of lower SRAM to remove NBL.c rule
create_place_blockage -type hard -rects { { 761.46 344.82 763.46 684.0 } } -name hardBlockage2

#PG model for concurrent macro place
# create_pg_model_for_macro_place -file golden_mimic_power_mesh.tcl


#####################################
# Rails
#####################################
set_db route_special_via_connect_to_shape { ring stripe blockring }
route_special   -connect core_pin \
                -layer_change_range { Metal1(1) TopMetal1(6) } \
                -block_pin_target nearest_target \
                -core_pin_target {block_ring ring stripe} \
                -allow_jogging 0 \
                -crossover_via_layer_range { Metal1(1) TopMetal1(6) } \
                -nets { VDD VSS } \
                -allow_layer_change 0 \
                -target_via_layer_range { Metal1(1) TopMetal1(6) }

# Issaugome projekta 
write_db dbs/powerplan.enc