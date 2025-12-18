set CYCLE 12.5
# I2C 1MHz SCL
# set I2C_CYCLE 1000
set INPUT_DLY [expr 0.5*$CYCLE]
set OUTPUT_DLY [expr 0.5*$CYCLE]

# Default INPUT / OUTPUT delay - half cycle
set INPUT_DLY [expr 0.5*$CYCLE]
set OUTPUT_DLY [expr 0.5*$CYCLE]

# -------------------------------------
# CLOCK CONSTRAINTS
# -------------------------------------
# System clock
create_clock -name clk_sys -period $CYCLE -waveform [list 0 [expr 0.5*$CYCLE]] [get_ports clk_sys]

# Virtual I2C SCL
# create_clock -name scl_virtual -period $I2C_CYCLE -waveform [list 0 [expr 0.5*$I2C_CYCLE]] [get_ports SCL_Pad]

# Rising clock edge for each DFF will be 0.2ns
set_clock_transition 0.2  [get_clocks clk_sys]

# Clock skew
set_clock_uncertainty 1 [get_clocks clk_sys] -setup
set_clock_uncertainty 0.05 [get_clocks clk_sys] -hold

# ------------------------------------
# IO CONSTRAINTS
# ------------------------------------
# Delays outside the chip

# Set any input/output delays so genus doesn't show unconstrained inputs/outputs
set_input_delay -max $INPUT_DLY -clock clk_sys [get_ports {rst_async_n scl_pad_i sda_pad_i ext_pad*}]
set_input_delay -min 0 -clock clk_sys [get_ports {rst_async_n scl_pad_i sda_pad_i ext_pad*}]

set_output_delay -max $OUTPUT_DLY -clock clk_sys [get_ports {scl_pad_o scl_padoen_o sda_pad_o sda_padoen_o gpio_o* gpio_oe*}]
set_output_delay -min 0 -clock clk_sys [get_ports {scl_pad_o scl_padoen_o sda_pad_o sda_padoen_o gpio_o* gpio_oe*}]

# I2C input delays (from 24CS512)W

# Datasheet: EEPROM Output Valid from Clock
#set_input_delay -max 400 [get_ports SDA_Pad] -clock_fall scl_virtual
#set_input_delay -min 0 [get_ports SDA_Pad] -clock_fall scl_virtual

# I2C output delays (from 24CS512)
#set_output_delay -max 250 [get_ports SDA_Pad] -clock_fall scl_virtual
#set_output_delay -min 0 [get_ports SDA_Pad] -clock_fall scl_virtual

# set_max_delay -from [get_ports SCL_Pad] 50
# set_min_delay -from [get_ports SCL_Pad] 0
# set_max_delay -from [get_ports SDA_Pad] 50
# set_min_delay -from [get_ports SDA_Pad] 0



# Set a cell that will drive chip input can also set input transition instead
# set_driving_cell -cell [get_lib_cells MYLIB/INV4] -pin Z [remove_from_collection [all_inputs] [get_ports clk_100m]]
# Alternatively set transition manually
set_input_transition 0.5 [all_inputs]
# And set the capacitance on chip outputs
set_load 0.05 [all_outputs]

# ------------------------------------
# FALSE PATHS
# ------------------------------------
# set_dont_touch [get_cells {u_i2c/u_i2c/byte_controller/bit_controller/cSCL_reg[0] \
#                            u_i2c/u_i2c/byte_controller/bit_controller/cSCL_reg[1]}]

# set_false_path -from [get_ports test_mode_Pad]
# False paths for I2C lines because synchronizers on inputs
# set_false_path -to [get_ports SCL_Pad*]
# set_false_path -from [get_ports SCL_Pad*] 
# # -to [get_pins u_i2c/u_i2c/byte_controller/bit_controller/cSCL_reg[1]/D]
# set_false_path -to [get_ports SDA_Pad*]
# set_false_path -from [get_ports SDA_Pad*]

# # False path for Reset synchronizer (Does this also exclude check between stablization DFFs?)
# # set_false_path -from [get_ports {rst_sys_n_Pad}] -to [all_registers]
# set_disable_timing [get_ports rst_sys_n_Pad]

# # False path for GPIOs
# set_false_path -to [get_ports ext_pad*]
# set_false_path -from [get_ports ext_pad*]


set_false_path -from [get_ports scl_pad_i] 
set_false_path -from [get_ports sda_pad_i] 

set_disable_timing [get_ports rst_async_n]

set_false_path -from [get_ports ext_pad*]
