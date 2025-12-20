
# System frequency 20MHz
set CYCLE 50

# Default INPUT / OUTPUT delay - half cycle
set INPUT_DLY [expr 0.5*$CYCLE]
set OUTPUT_DLY [expr 0.5*$CYCLE]

# -------------------------------------
# CLOCK CONSTRAINTS
# -------------------------------------
# System clock
create_clock -name clk_sys -period $CYCLE -waveform [list 0 [expr 0.5*$CYCLE]] [get_ports clk_sys]

# Rising clock edge for each DFF will be 0.2ns
set_clock_transition 0.2  [get_clocks clk_sys]

# Clock skew
set_clock_uncertainty 1 [get_clocks clk_sys] -setup
set_clock_uncertainty 0.05 [get_clocks clk_sys] -hold

# ------------------------------------
# IO CONSTRAINTS
# ------------------------------------

set_input_delay -max $INPUT_DLY -clock clk_sys [get_ports {rst_async_n scl_pad_i sda_pad_i ext_pad*}]
set_input_delay -min 0 -clock clk_sys [get_ports {rst_async_n scl_pad_i sda_pad_i ext_pad*}]

set_output_delay -max $OUTPUT_DLY -clock clk_sys [get_ports {scl_pad_o scl_padoen_o sda_pad_o sda_padoen_o gpio_o* gpio_oe*}]
set_output_delay -min 0 -clock clk_sys [get_ports {scl_pad_o scl_padoen_o sda_pad_o sda_padoen_o gpio_o* gpio_oe*}]

# Set transition at input
set_input_transition 0.5 [all_inputs]
# Alternatively a more accurate approach is to set a driving cell (cell that will drive the primary input)
# set_driving_cell -cell [get_lib_cells MYLIB/INV4] -pin Z [remove_from_collection [all_inputs] [get_ports clk_100m]]

# Set the capacitance on chip outputs
set_load 0.05 [all_outputs]
# Can also use a stdcell for output loading

# ------------------------------------
# FALSE PATHS
# ------------------------------------

# Set false paths from asynchronous inputs as we use 2DFF synchronizers which need to be ignored by STA
set_false_path -from [get_ports scl_pad_i] 
set_false_path -from [get_ports sda_pad_i] 

set_disable_timing [get_ports rst_async_n]

set_false_path -from [get_ports ext_pad*]
