###############################################################################
# Created by write_sdc
###############################################################################
current_design ibex_simple_system
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk_sys -period 40.0000 [get_ports {clk_sys}]
set_clock_transition 0.1500 [get_clocks {clk_sys}]
set_clock_uncertainty 0.2500 clk_sys
# set_propagated_clock [get_clocks {clk_sys}]
set_input_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {rst_async_n}]

set_input_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {i_qspi_dat[0]}]
set_input_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {i_qspi_dat[1]}]
set_input_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {i_qspi_dat[2]}]
set_input_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {i_qspi_dat[3]}]

set_output_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {o_qspi_dat[0]}]
set_output_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {o_qspi_dat[1]}]
set_output_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {o_qspi_dat[2]}]
set_output_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {o_qspi_dat[3]}]

set_output_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {o_qspi_sck}]
set_output_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {o_qspi_cs_n}]
set_output_delay 8.0000 -clock [get_clocks {clk_sys}] -add_delay [get_ports {o_qspi_mod}]
###############################################################################
# Environment
###############################################################################

set_load -pin_load 0.0334 [get_ports {o_qspi_dat[3]}]
set_load -pin_load 0.0334 [get_ports {o_qspi_dat[2]}]
set_load -pin_load 0.0334 [get_ports {o_qspi_dat[1]}]
set_load -pin_load 0.0334 [get_ports {o_qspi_dat[0]}]

set_load -pin_load 0.0334 [get_ports {o_qspi_mod}]
set_load -pin_load 0.0334 [get_ports {o_qspi_cs_n}]
set_load -pin_load 0.0334 [get_ports {o_qspi_sck}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {clk_sys}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rst_async_n}]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {i_qspi_dat[3]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {i_qspi_dat[2]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {i_qspi_dat[1]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {i_qspi_dat[0]}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 0.7500 [current_design]
set_max_capacitance 0.2000 [current_design]
set_max_fanout 10.0000 [current_design]
