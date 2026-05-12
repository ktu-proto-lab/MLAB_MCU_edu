
# XM-Sim Command File
# TOOL:	xmsim(64)	25.03-s006
#
#
# You can restore this configuration with:
#
#      xrun -sv -access +rw +gui -timescale 1ns/1ns -clean +define+RANDOM_NUMBER=248 -define FUNCTIONAL -f files.f ../../tb/sobel_full_tb.sv -s -input restore.tcl
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
set gate_loop_warn_size 1
alias . run
alias indago verisium
alias quit exit
database -open -shm -into waves.shm waves -default
probe -create -database waves simple_system_tb.dut.u_gpio.u_wb_gpio.aux_i simple_system_tb.dut.u_gpio.u_wb_gpio.rgpio_eclk simple_system_tb.dut.u_gpio.u_wb_gpio.rgpio_in simple_system_tb.dut.u_gpio.u_wb_gpio.rgpio_inte simple_system_tb.dut.u_gpio.u_wb_gpio.rgpio_oe simple_system_tb.dut.u_gpio.u_wb_gpio.rgpio_out simple_system_tb.dut.u_gpio.u_wb_gpio.rgpio_ptrig simple_system_tb.clk_sys simple_system_tb.rst_sys_n simple_system_tb.dut.imem.sram1_me simple_system_tb.dut.imem.sram2_me simple_system_tb.dut.wbs[0].slave.rst simple_system_tb.dut.wbs[0].slave.clk simple_system_tb.dut.wbs[0].slave.cyc simple_system_tb.dut.wbs[0].slave.stb simple_system_tb.dut.wbs[0].slave.adr simple_system_tb.dut.wbs[0].slave.sel simple_system_tb.dut.wbs[0].slave.we simple_system_tb.dut.wbs[0].slave.stall simple_system_tb.dut.wbs[0].slave.ack simple_system_tb.dut.wbs[0].slave.err simple_system_tb.dut.dmem.sram.A_ADDR simple_system_tb.dut.dmem.sram.A_BM simple_system_tb.dut.dmem.sram.A_CLK simple_system_tb.dut.dmem.sram.A_DIN simple_system_tb.dut.dmem.sram.A_DLY simple_system_tb.dut.dmem.sram.A_DOUT simple_system_tb.dut.dmem.sram.A_MEN simple_system_tb.dut.dmem.sram.A_REN simple_system_tb.dut.dmem.sram.A_WEN simple_system_tb.dut.wbs[1].slave.rst simple_system_tb.dut.wbs[1].slave.clk simple_system_tb.dut.wbs[1].slave.cyc simple_system_tb.dut.wbs[1].slave.stb simple_system_tb.dut.wbs[1].slave.adr simple_system_tb.dut.wbs[1].slave.sel simple_system_tb.dut.wbs[1].slave.we simple_system_tb.dut.wbs[1].slave.stall simple_system_tb.dut.wbs[1].slave.ack simple_system_tb.dut.wbs[1].slave.err simple_system_tb.dut.u_bootloader.clk simple_system_tb.dut.u_bootloader.state simple_system_tb.dut.u_bootloader.mem_addr simple_system_tb.dut.u_bootloader.data_word simple_system_tb.dut.u_bootloader.busy simple_system_tb.dut.u_bootloader.done simple_system_tb.dut.u_bootloader.start simple_system_tb.dut.u_bootloader.we simple_system_tb.dut.u_bootloader.wdata simple_system_tb.dut.u_bootloader.next_state simple_system_tb.dut.u_bootloader.last_read simple_system_tb.dut.u_bootloader.mem_index simple_system_tb.dut.u_bootloader.next_mem_index simple_system_tb.dut.u_bootloader.next_rst_core_n simple_system_tb.dut.u_bootloader.rdata simple_system_tb.dut.u_bootloader.rst_core_n simple_system_tb.dut.u_bootloader.sram_access simple_system_tb.dut.u_bootloader.addr_pointer simple_system_tb.dut.u_bootloader.i_i2c_fsm.state simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_done simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_busy simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_addr simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_wdata simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_we simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_start simple_system_tb.dut.u_bootloader.i_i2c_fsm.wb_rdata simple_system_tb.dut.u_bootloader.i_i2c_fsm.w_data simple_system_tb.dut.u_bootloader.i_i2c_fsm.sram_access simple_system_tb.dut.u_bootloader.i_i2c_fsm.r_data simple_system_tb.dut.u_bootloader.i_i2c_fsm.mem_addr simple_system_tb.dut.u_bootloader.i_i2c_fsm.last_read simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.state simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.we simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.wdata simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.addr simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.start simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.rdata simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.done simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.clk simple_system_tb.dut.u_bootloader.i_i2c_fsm.i_wb_access.busy simple_system_tb.dut.wbm[0].master.clk simple_system_tb.dut.wbm[0].master.we simple_system_tb.dut.wbm[0].master.cyc simple_system_tb.dut.wbm[0].master.stb simple_system_tb.dut.wbm[0].master.adr simple_system_tb.dut.wbm[0].master.stall simple_system_tb.dut.wbm[0].master.sel simple_system_tb.dut.wbm[0].master.rst simple_system_tb.dut.wbm[0].master.err simple_system_tb.dut.wbm[0].master.ack simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.u_ibex_core.rst_ni simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.u_ibex_core.pc_if simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.u_ibex_core.pc_id simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.u_ibex_core.instr_rdata_id simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_rvalid_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_gnt_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_err_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_rdata_intg_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_rdata_core simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_rdata_i simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_addr_o simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.instr_req_o simple_system_tb.dut.imem.sram1.A_ADDR simple_system_tb.dut.imem.sram1.A_BM simple_system_tb.dut.imem.sram1.A_CLK simple_system_tb.dut.imem.sram1.A_DIN simple_system_tb.dut.imem.sram1.A_DLY simple_system_tb.dut.imem.sram1.A_DOUT simple_system_tb.dut.imem.sram1.A_MEN simple_system_tb.dut.imem.sram1.A_REN simple_system_tb.dut.imem.sram1.A_WEN simple_system_tb.dut.imem.sram2.A_ADDR simple_system_tb.dut.imem.sram2.A_BM simple_system_tb.dut.imem.sram2.A_CLK simple_system_tb.dut.imem.sram2.A_DIN simple_system_tb.dut.imem.sram2.A_DLY simple_system_tb.dut.imem.sram2.A_DOUT simple_system_tb.dut.imem.sram2.A_MEN simple_system_tb.dut.imem.sram2.A_REN simple_system_tb.dut.imem.sram2.A_WEN simple_system_tb.dut.u_wb_ibex_top.data_core.slave.addr simple_system_tb.dut.u_wb_ibex_top.data_core.slave.be simple_system_tb.dut.u_wb_ibex_top.data_core.slave.clk simple_system_tb.dut.u_wb_ibex_top.data_core.slave.err simple_system_tb.dut.u_wb_ibex_top.data_core.slave.gnt simple_system_tb.dut.u_wb_ibex_top.data_core.slave.rdata simple_system_tb.dut.u_wb_ibex_top.data_core.slave.req simple_system_tb.dut.u_wb_ibex_top.data_core.slave.rst_n simple_system_tb.dut.u_wb_ibex_top.data_core.slave.rvalid simple_system_tb.dut.u_wb_ibex_top.data_core.slave.wdata simple_system_tb.dut.u_wb_ibex_top.data_core.slave.we simple_system_tb.dut.wbm[1].master.rst simple_system_tb.dut.wbm[1].master.clk simple_system_tb.dut.wbm[1].master.cyc simple_system_tb.dut.wbm[1].master.stb simple_system_tb.dut.wbm[1].master.adr simple_system_tb.dut.wbm[1].master.sel simple_system_tb.dut.wbm[1].master.we simple_system_tb.dut.wbm[1].master.stall simple_system_tb.dut.wbm[1].master.ack simple_system_tb.dut.wbm[1].master.err simple_system_tb.dut.u_pit.pit_irq_o simple_system_tb.dut.u_pit.u_wb_pit.cnt_n simple_system_tb.dut.u_pit.u_wb_pit.mod_value simple_system_tb.dut.u_pit.u_wb_pit.pit_pre_scl simple_system_tb.dut.wbs[4].slave.err simple_system_tb.dut.wbs[4].slave.ack simple_system_tb.dut.wbs[4].slave.stall simple_system_tb.dut.wbs[4].slave.sel simple_system_tb.dut.wbs[4].slave.adr simple_system_tb.dut.wbs[4].slave.stb simple_system_tb.dut.wbs[4].slave.cyc simple_system_tb.dut.wbs[4].slave.clk simple_system_tb.dut.wbs[4].slave.rst simple_system_tb.dut.wbs[4].slave.we simple_system_tb.dut.u_pit.sel_to_pit simple_system_tb.dut.u_pit.data_to_pit simple_system_tb.dut.u_pit.data_from_pit simple_system_tb.dut.u_pit.delayed_pit_ack simple_system_tb.dut.wbs[2].slave.err simple_system_tb.dut.wbs[2].slave.ack simple_system_tb.dut.wbs[2].slave.stall simple_system_tb.dut.wbs[2].slave.we simple_system_tb.dut.wbs[2].slave.sel simple_system_tb.dut.wbs[2].slave.adr simple_system_tb.dut.wbs[2].slave.stb simple_system_tb.dut.wbs[2].slave.cyc simple_system_tb.dut.wbs[2].slave.clk simple_system_tb.dut.wbs[2].slave.rst simple_system_tb.dut.u_i2c.scl_pad_i simple_system_tb.dut.u_i2c.scl_pad_o simple_system_tb.dut.u_i2c.scl_padoen_o simple_system_tb.dut.u_i2c.sda_pad_i simple_system_tb.dut.u_i2c.sda_pad_o simple_system_tb.dut.u_i2c.sda_padoen_o simple_system_tb.dut.u_i2c.u_wb_i2c.i2c_al simple_system_tb.dut.u_i2c.u_wb_i2c.cr simple_system_tb.dut.u_i2c.u_wb_i2c.prer simple_system_tb.dut.u_i2c.u_wb_i2c.txr simple_system_tb.dut.u_i2c.u_wb_i2c.rxr simple_system_tb.dut.u_i2c.u_wb_i2c.sr simple_system_tb.dut.u_i2c.u_wb_i2c.ctr simple_system_tb.dut.u_i2c.int_o simple_system_tb.dut.u_i2c.u_wb_i2c.arst_i simple_system_tb.dut.wbs[3].slave.ack simple_system_tb.dut.wbs[3].slave.adr simple_system_tb.dut.wbs[3].slave.clk simple_system_tb.dut.wbs[3].slave.cyc simple_system_tb.dut.wbs[3].slave.err simple_system_tb.dut.wbs[3].slave.rst simple_system_tb.dut.wbs[3].slave.sel simple_system_tb.dut.wbs[3].slave.stall simple_system_tb.dut.wbs[3].slave.stb simple_system_tb.dut.wbs[3].slave.we simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.gen_regfile_ff.register_file_i.rf_reg
probe -create -database waves simple_system_tb.dut.u_sobel_acc.wr_ptr simple_system_tb.dut.u_sobel_acc.wb_wr simple_system_tb.dut.u_sobel_acc.wb_wdata simple_system_tb.dut.u_sobel_acc.wb_rdata simple_system_tb.dut.u_sobel_acc.state simple_system_tb.dut.u_sobel_acc.frame_ready_i simple_system_tb.dut.u_sobel_acc.fifo_rd_en simple_system_tb.dut.u_sobel_acc.fifo_empty simple_system_tb.dut.u_sobel_acc.fifo_dout simple_system_tb.dut.u_sobel_acc.dst_we simple_system_tb.dut.u_sobel_acc.dst_wdata simple_system_tb.dut.u_sobel_acc.dst_rdata simple_system_tb.dut.u_sobel_acc.dst_addr simple_system_tb.dut.u_sobel_acc.do_start simple_system_tb.dut.u_sobel_acc.ctrl_auto_start simple_system_tb.dut.u_sobel_acc.ctrl_algo_sel simple_system_tb.dut.u_sobel_acc.csr_frame_ready simple_system_tb.dut.u_sobel_acc.csr_frame_count simple_system_tb.dut.u_sobel_acc.csr_error simple_system_tb.dut.u_sobel_acc.csr_done simple_system_tb.dut.u_sobel_acc.csr_busy simple_system_tb.dut.wbs[6].slave.we simple_system_tb.dut.wbs[6].slave.stb simple_system_tb.dut.wbs[6].slave.stall simple_system_tb.dut.wbs[6].slave.sel simple_system_tb.dut.wbs[6].slave.rst simple_system_tb.dut.wbs[6].slave.err simple_system_tb.dut.wbs[6].slave.dat_o simple_system_tb.dut.wbs[6].slave.dat_i simple_system_tb.dut.wbs[6].slave.cyc simple_system_tb.dut.wbs[6].slave.clk simple_system_tb.dut.wbs[6].slave.adr simple_system_tb.dut.wbs[6].slave.ack simple_system_tb.dut.u_sobel_acc.dst_en
probe -create -database waves simple_system_tb.dut.u_frame_bram_b.we simple_system_tb.dut.u_frame_bram_b.wdata simple_system_tb.dut.u_frame_bram_b.rdata simple_system_tb.dut.u_frame_bram_b.en simple_system_tb.dut.u_frame_bram_b.clk simple_system_tb.dut.u_frame_bram_b.addr

simvision -input restore.tcl.svcf
