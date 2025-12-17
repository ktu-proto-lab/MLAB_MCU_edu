
# XM-Sim Command File
# TOOL:	xmsim(64)	24.03-s004
#
#
# You can restore this configuration with:
#
#      xrun -f files.f -timescale 1ns/10ps -access +rw +gui -nospecify -input restore.tcl
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
set vcd_compact_mode 0
set vhdl_forgen_loopindex_enum_pos 0
set xmreplay_dc_debug 0
set tcl_runcmd_interrupt next_command
set tcl_sigval_prefix {#}
alias . run
alias indago verisium
alias quit exit
database -open -shm -into waves.shm waves -default
probe -create -database waves simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.u_ibex_core.rst_ni simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.u_ibex_core.pc_if simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.u_ibex_core.pc_id simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.u_ibex_core.instr_rdata_id simple_system_tb.dut.u_gpio.u_gpio.rgpio_ctrl simple_system_tb.dut.u_gpio.u_gpio.rgpio_aux simple_system_tb.dut.u_gpio.u_gpio.rgpio_in simple_system_tb.dut.u_gpio.u_gpio.rgpio_inte simple_system_tb.dut.u_gpio.u_gpio.rgpio_ints simple_system_tb.dut.u_gpio.u_gpio.rgpio_out simple_system_tb.dut.u_gpio.u_gpio.rgpio_ptrig simple_system_tb.eeprom.AddressPointer simple_system_tb.dut.dmem.wb_ack simple_system_tb.dut.dmem.wb_we simple_system_tb.dut.dmem.wb_adr simple_system_tb.dut.dmem.wb_clk simple_system_tb.SCL simple_system_tb.SDA simple_system_tb.clk_sys simple_system_tb.rst_sys_n simple_system_tb.dut.ext_pad simple_system_tb.dut.imem.sram1_me simple_system_tb.dut.imem.sram2_me simple_system_tb.dut.imem.sram1.i_SRAM_1P_behavioral_bm.memory simple_system_tb.dut.imem.sram2.i_SRAM_1P_behavioral_bm.memory simple_system_tb.dut.imem.wb_ack simple_system_tb.dut.imem.wb_adr simple_system_tb.dut.imem.wb_clk simple_system_tb.dut.imem.wb_cyc simple_system_tb.dut.imem.wb_dat_i simple_system_tb.dut.imem.wb_dat_o simple_system_tb.dut.imem.wb_err simple_system_tb.dut.imem.wb_rst simple_system_tb.dut.imem.wb_sel simple_system_tb.dut.imem.wb_stall simple_system_tb.dut.imem.wb_stb simple_system_tb.dut.imem.wb_we simple_system_tb.dut.dmem.sram.i_SRAM_1P_behavioral_bm.memory simple_system_tb.dut.dmem.sram.A_ADDR simple_system_tb.dut.dmem.sram.A_BM simple_system_tb.dut.dmem.sram.A_CLK simple_system_tb.dut.dmem.sram.A_DIN simple_system_tb.dut.dmem.sram.A_DLY simple_system_tb.dut.dmem.sram.A_DOUT simple_system_tb.dut.dmem.sram.A_MEN simple_system_tb.dut.dmem.sram.A_REN simple_system_tb.dut.dmem.sram.A_WEN simple_system_tb.dut.dmem.wb_cyc simple_system_tb.dut.dmem.wb_dat_i simple_system_tb.dut.dmem.wb_dat_o simple_system_tb.dut.dmem.wb_err simple_system_tb.dut.dmem.wb_rst simple_system_tb.dut.dmem.wb_sel simple_system_tb.dut.dmem.wb_stall simple_system_tb.dut.dmem.wb_stb simple_system_tb.dut.u_bootloader.clk simple_system_tb.dut.u_bootloader.state simple_system_tb.dut.u_bootloader.data_word simple_system_tb.dut.u_bootloader.busy simple_system_tb.dut.u_bootloader.done simple_system_tb.dut.u_bootloader.mem_index simple_system_tb.dut.u_bootloader.rdata simple_system_tb.dut.u_bootloader.rst_core_n simple_system_tb.dut.u_bootloader.i_i2c_fsm.state simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_done simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_we simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_rdata simple_system_tb.dut.u_bootloader.i_i2c_fsm.w_data simple_system_tb.dut.u_bootloader.i_i2c_fsm.sram_access simple_system_tb.dut.u_bootloader.i_i2c_fsm.r_data simple_system_tb.dut.u_bootloader.i_i2c_fsm.mem_addr simple_system_tb.dut.u_bootloader.i_i2c_fsm.last_read simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.state simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.we simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.wdata simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.addr simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.start simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.rdata simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.done simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.clk simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.busy simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_rvalid_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_gnt_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_err_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_rdata_intg_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_rdata_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_addr_o simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_req_o simple_system_tb.dut.SCL_Pad simple_system_tb.dut.SDA_Pad simple_system_tb.dut.u_i2c.u_i2c.scl_pad_i simple_system_tb.dut.u_i2c.u_i2c.scl_pad_o simple_system_tb.dut.u_i2c.u_i2c.scl_padoen_o simple_system_tb.dut.u_i2c.u_i2c.sda_pad_i simple_system_tb.dut.u_i2c.u_i2c.sda_pad_o simple_system_tb.dut.u_i2c.u_i2c.sda_padoen_o simple_system_tb.dut.u_i2c.u_i2c.byte_controller.i2c_al simple_system_tb.dut.u_i2c.u_i2c.cr simple_system_tb.dut.u_i2c.u_i2c.prer simple_system_tb.dut.u_i2c.u_i2c.txr simple_system_tb.dut.u_i2c.u_i2c.rxr simple_system_tb.dut.u_i2c.u_i2c.ctr simple_system_tb.dut.u_i2c.int_o simple_system_tb.dut.u_i2c.wb_we simple_system_tb.dut.u_i2c.wb_stb simple_system_tb.dut.u_i2c.wb_stall simple_system_tb.dut.u_i2c.wb_sel simple_system_tb.dut.u_i2c.wb_rst simple_system_tb.dut.u_i2c.wb_err simple_system_tb.dut.u_i2c.wb_dat_o simple_system_tb.dut.u_i2c.wb_dat_i simple_system_tb.dut.u_i2c.wb_cyc simple_system_tb.dut.u_i2c.wb_clk simple_system_tb.dut.u_i2c.wb_adr simple_system_tb.dut.u_i2c.wb_ack simple_system_tb.dut.u_pit.pit_irq_o simple_system_tb.dut.u_pit.delayed_pit_ack simple_system_tb.dut.u_pit.u_pit.pit_irq_o simple_system_tb.dut.u_pit.u_pit.cnt_n simple_system_tb.dut.u_pit.u_pit.mod_value simple_system_tb.dut.u_pit.u_pit.pit_pre_scl simple_system_tb.eeprom.PageBuffer_00 simple_system_tb.eeprom.PageBuffer_01 simple_system_tb.eeprom.PageBuffer_02 simple_system_tb.eeprom.PageBuffer_03 simple_system_tb.eeprom.PageBuffer_04 simple_system_tb.eeprom.PageBuffer_05 simple_system_tb.eeprom.PageBuffer_06 simple_system_tb.eeprom.PageBuffer_07 simple_system_tb.eeprom.PageBuffer_08 simple_system_tb.eeprom.PageBuffer_09 simple_system_tb.eeprom.PageBuffer_10
probe -create -database waves

simvision -input restore.tcl.svcf
