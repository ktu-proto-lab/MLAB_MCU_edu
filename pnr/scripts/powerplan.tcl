
#####################################
# Global nets
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

#####################################
# Power Ring 
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

#####################################
# Block ring around dmem
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
    -around user_defined \
    -user_defined_region {2.52 3.5 2.52 371.74 451.68 371.74 451.68 3.5 2.52 3.5} \
    -type block_rings \
    -layer {top Metal5 bottom Metal5 left TopMetal1 right TopMetal1} \
    -width {top 2 bottom 2 left 2 right 2} \
    -spacing {top 2 bottom 2 left 2 right 2} \
    -offset {top 1.8 bottom 1.8 left 1.8 right 1.8} \
    -center 0 \
    -skip_side {bottom left } \
    -threshold 0 \
    -jog_distance 0 \
    -snap_wire_center_to_grid none

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
    -stop_offset 680 \
    -switch_layer_over_obs false \
    -max_same_layer_jog_length 2 \
    -pad_core_ring_top_layer_limit TopMetal2 \
    -pad_core_ring_bottom_layer_limit Metal1 \
    -block_ring_top_layer_limit TopMetal2 \
    -block_ring_bottom_layer_limit Metal1 \
    -use_wire_group 0 \
    -snap_wire_center_to_grid none

# Metal5 for DMEM
gui_select -point {217.29200 204.49300}
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

#prevent placement of stdcells to reduce congestion also cuts followpins
create_place_halo -halo_deltas {0.96 0.96 0.96 0.96} -all_blocks

#reduce wiring close to pinsf
create_route_halo -all_blocks -space 0.18 -bottom_layer Metal1 -top_layer TopMetal2

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

# delete_obj [get_db route_blockages]

# Routing blockages over SRAMS to make sure no routing on M1-M5
# dmem/sram
create_route_blockage -area 35.04 35.28 451.68 371.74 -layer {Metal1 Metal2 Metal3 Metal4 Metal5}
# imem/sram1
create_route_blockage -area 35.04 708.08 451.68 1044.54 -layer {Metal1 Metal2 Metal3 Metal4 Metal5}
# imem/sram2
create_route_blockage -area 630.24 708.08 1046.88 1044.54 -layer {Metal1 Metal2 Metal3 Metal4 Metal5}

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