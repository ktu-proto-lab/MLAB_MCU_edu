set_case_analysis 1 [get_ports test_mode_Pad]
# ext_pad[4] is scan_enable under test_mode=1
set_case_analysis 1 [get_ports ext_pad[4]]
# 10 MHz clock as in run_scan.tcl define_test_clock, waveform as default for define_test_clock
create_clock \
    -name clk_test \
    -period 100 \
    -waveform {50 90} [get_ports clk_sys_Pad]

# --------------------------------------------
# PASTE synOutData/post_syn.sdc BELOW
#
# 1. Make sure conflicting definitions are removed below (mainly clock definition BUT CHECK!!)
# 2. Rename clk_sys to clk_test where necessary (DONT RENAME PAD)
# --------------------------------------------
# ####################################################################

#  Created by Genus(TM) Synthesis Solution 23.13-s073_1 on Thu Oct 23 23:10:48 EEST 2025

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design ibex_simple_system

set_clock_transition 0.2 [get_clocks clk_test]
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
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports rst_sys_n_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[9]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[9]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[8]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[8]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[7]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[7]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[6]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[6]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[5]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[5]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[4]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[4]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[3]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[3]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[2]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[2]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[1]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[1]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[0]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[0]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports SCL_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports SCL_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports SDA_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports SDA_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports test_mode_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports rst_sys_n_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports test_mode_Pad]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[9]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[9]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[8]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[8]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[7]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[7]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[6]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[6]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[5]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[5]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[4]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[4]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[3]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[3]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[2]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[2]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[1]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[1]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[0]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports {ext_pad[0]}]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports SCL_Pad]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports SCL_Pad]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports SDA_Pad]
set_output_delay -clock [get_clocks clk_test] -add_delay -max 6.25 [get_ports SDA_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[9]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[9]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[8]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[8]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[7]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[7]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[6]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[6]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[5]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[5]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[4]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[4]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[3]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[3]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[2]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[2]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[1]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[1]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[0]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports {ext_pad[0]}]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports SCL_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports SCL_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports SDA_Pad]
set_input_delay -clock [get_clocks clk_test] -add_delay -min 0.0 [get_ports SDA_Pad]
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
set_clock_uncertainty -setup 1.0 [get_clocks clk_test]
set_clock_uncertainty -hold 0.05 [get_clocks clk_test]
