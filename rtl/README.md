## Directory structure 

### `core/`
Contains RTL source files from the [Ibex](https://github.com/lowRISC/ibex) repository.

### `fpga/`
- `clk_div.sv` : RTL clock divider to lower frequency when using the BASYS3 FPGA.
- `fpga_top.sv` : Top module for fpga which includes clk_div.sv.

### `include/`
Contains include files for the [Ibex](https://github.com/lowRISC/ibex) core. Also a header for the bootloader (boot_defs.svh) and global setup header (project_defs.svh)

### `pdk/`
PDK file directory. ADD THESE FILES MANUALLY. 
> **Note (2025-11-27):**  
> This section is now outdated. We now work directly from the server, where all PDK paths are defined using **absolute paths**.  
> The only exception is the RTL simulation flow, which still uses relative paths.  
> **TODO:** Update RTL simulation to absolute paths.
- `RM_IHPSG13_1P_1024x32_c2_bm.v`: SRAM top module.
- `RM_IHPSG13_1P_core_behavioral_bm.v`: Behavioral model of the SRAM.
- `ixc013g2_iocell.v` : I/O cell behavioral verilog.
  
### `peripherals/`
Contains memory-mapped peripheral modules.
- `gpio_top.v` : [GPIO top](https://github.com/klyone/opencores-ip/tree/communication_controller_general-purpose_i-o_gpio_core) from opencores.
- `i2c_master-top.v` : [I2C top](https://github.com/klyone/opencores-ip/tree/communication_controller_i2c_controller_core) from opencores.
- `pit_top.v` : [PIT top](https://github.com/klyone/opencores-ip/tree/other_programmable_interval_timer) from opencores.
- `wb_uart.sv` : [UART top](https://github.com/ZipCPU/wbuart32) from ZipCPU. This module was highly customized by us.

Reset synchronizer module - `areset_sync.sv.`

Three layer FSM based bootloader - `bootloader_top.sv; i2c_access_fsm.sv; wb_access_fsm.sv`. Custom modules written by us.
### `wb/`
Contains wishbone wrappers, interfaces, shared interconnect and crossbar interconnect. We use shared interconnect.
- `addrdecode.v; skidbuffer.v; wbxbar.v; wb_interconnect_xbar.sv` : Components for wishbone crossbar interconnect. From [ibex_wb](https://github.com/pbing/ibex_wb/tree/master).
- `wb_interconnect_sharedbus.sv` : Wishbone shared interconnect. From [ibex_wb](https://github.com/pbing/ibex_wb/tree/master).
- `core_if.sv; wb_if.sv; wb_pkg.sv` : Interface definitions. From [ibex_wb](https://github.com/pbing/ibex_wb/tree/master).
- `core2wb.sv` : Core to wishbone protocol bridge. From [ibex_wb](https://github.com/pbing/ibex_wb/tree/master).
- `wb_gpio.sv; wb_i2c.sv; wb_pit.sv; wb_sram_1024x32.sv; wb_sram_2048x32.sv; wb_uart.sv` : Custom wrappers connecting opencore standalone wishbone signals to the unified interface. For the memory wishbone handling is implemented in this wrapper. wb_sram_2048x32 is two 1024 word memories multiplexed to form a bigger memory (used as IMEM). Wrappers also contain glue logic. These modules have been written by us.
- `wb_ibex_top.sv` : Ibex core with wishbone B4 interface. From [ibex_wb](https://github.com/pbing/ibex_wb/tree/master).


### `ibex_simple_system.sv`
Contains two modules.
- `ibex_simple_system_int` : Top level of the system.
- `ibex_simple_system` : Wrapper for the top level which includes IO pads and logic for multiplexing scan signals to GPIOs. This is required due to the way Cadence Genus allows to specify scan signals - must specify pins or ports, can not use internal nets.

