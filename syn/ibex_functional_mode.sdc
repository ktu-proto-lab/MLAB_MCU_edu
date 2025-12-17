set_case_analysis 0 [get_ports test_mode_Pad]

# PASTE synOutData/post_syn.sdcBELOW
# ####################################################################

#  Created by Genus(TM) Synthesis Solution 23.13-s073_1 on Thu Oct 23 23:10:48 EEST 2025

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design ibex_simple_system

create_clock -name "clk_sys" -period 12.5 -waveform {0.0 6.25} [get_ports clk_sys_Pad]
set_clock_transition 0.2 [get_clocks clk_sys]
set_load -pin_load 0.05 [get_ports SDA_Pad]
set_load -pin_load 0.05 [get_ports SCL_Pad]
set_load -pin_load 0.05 [get_ports {ext_pad[9]}]
set_load -pin_load 0.05 [get_ports {ext_pad[8]}]
set_load -pin_load 0.05 [get_ports {ext_pad[7]}]
set_load -pin_load 0.05 [get_ports {ext_pad[6]}]
set_load -pin_load 0.05 [get_ports {ext_pad[5]}]
set_load -pin_load 0.05 [get_ports {ext_pad[4]}]
set_load -pin_load 0.05 [get_ports {ext_pad[3]}]
set_load -pin_load 0.05 [get_ports {ext_pad[2]}]
set_load -pin_load 0.05 [get_ports {ext_pad[1]}]
set_load -pin_load 0.05 [get_ports {ext_pad[0]}]
set_false_path -to [list \
  [get_ports SCL_Pad]  \
  [get_ports SDA_Pad]  \
  [get_ports {ext_pad[0]}]  \
  [get_ports {ext_pad[1]}]  \
  [get_ports {ext_pad[2]}]  \
  [get_ports {ext_pad[3]}]  \
  [get_ports {ext_pad[4]}]  \
  [get_ports {ext_pad[5]}]  \
  [get_ports {ext_pad[6]}]  \
  [get_ports {ext_pad[7]}]  \
  [get_ports {ext_pad[8]}]  \
  [get_ports {ext_pad[9]}] ]
set_false_path -from [list \
  [get_ports test_mode_Pad]  \
  [get_ports SCL_Pad]  \
  [get_ports SDA_Pad]  \
  [get_ports {ext_pad[0]}]  \
  [get_ports {ext_pad[1]}]  \
  [get_ports {ext_pad[2]}]  \
  [get_ports {ext_pad[3]}]  \
  [get_ports {ext_pad[4]}]  \
  [get_ports {ext_pad[5]}]  \
  [get_ports {ext_pad[6]}]  \
  [get_ports {ext_pad[7]}]  \
  [get_ports {ext_pad[8]}]  \
  [get_ports {ext_pad[9]}] ]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports rst_sys_n_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[9]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[9]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[8]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[8]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[7]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[7]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[6]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[6]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[5]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[5]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[4]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[4]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[3]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[3]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[2]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[2]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[1]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[1]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[0]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[0]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports SCL_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports SCL_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports SDA_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports SDA_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports test_mode_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports rst_sys_n_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports test_mode_Pad]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[9]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[9]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[8]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[8]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[7]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[7]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[6]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[6]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[5]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[5]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[4]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[4]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[3]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[3]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[2]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[2]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[1]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[1]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[0]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports {ext_pad[0]}]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports SCL_Pad]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports SCL_Pad]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports SDA_Pad]
set_output_delay -clock [get_clocks clk_sys] -add_delay -max 6.25 [get_ports SDA_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[9]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[9]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[8]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[8]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[7]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[7]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[6]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[6]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[5]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[5]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[4]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[4]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[3]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[3]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[2]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[2]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[1]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[1]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[0]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports {ext_pad[0]}]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports SCL_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports SCL_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports SDA_Pad]
set_input_delay -clock [get_clocks clk_sys] -add_delay -min 0.0 [get_ports SDA_Pad]
set_disable_timing [get_ports rst_sys_n_Pad]
set_input_transition 0.5 [get_ports clk_sys_Pad]
set_input_transition 0.5 [get_ports rst_sys_n_Pad]
set_input_transition 0.5 [get_ports test_mode_Pad]
set_input_transition 0.5 [get_ports SDA_Pad]
set_input_transition 0.5 [get_ports SCL_Pad]
set_input_transition 0.5 [get_ports {ext_pad[9]}]
set_input_transition 0.5 [get_ports {ext_pad[8]}]
set_input_transition 0.5 [get_ports {ext_pad[7]}]
set_input_transition 0.5 [get_ports {ext_pad[6]}]
set_input_transition 0.5 [get_ports {ext_pad[5]}]
set_input_transition 0.5 [get_ports {ext_pad[4]}]
set_input_transition 0.5 [get_ports {ext_pad[3]}]
set_input_transition 0.5 [get_ports {ext_pad[2]}]
set_input_transition 0.5 [get_ports {ext_pad[1]}]
set_input_transition 0.5 [get_ports {ext_pad[0]}]
set_dont_touch [get_cells pad_rst_sys]
set_dont_touch [get_cells pad_test_mode]
set_clock_uncertainty -setup 1.0 [get_clocks clk_sys]
set_clock_uncertainty -hold 0.05 [get_clocks clk_sys]
