
set DESIGN "ibex_simple_system"

# Default is medium for syn_gen and high for syn_opt/syn_map
set GEN_EFF medium
set MAP_OPT_EFF high
set _LOG_PATH log
set _OUTPUTS_PATH synOutData
set _REPORTS_PATH Reports
# set _MODUS_WORKDIR /mlab_shares/Skaitmena/IbexD/MLAB_riscv_mcu/syn/modus

# UNCOMMENT this for more info (default is 1)
# set_db information_level 7 

# Don't use assigns (for LVS to work) This is set during syn_opt incremental as in template
# set_db remove_assigns 1   

# Clock gates not available for use in SG13G2 YET(2025-10-17)[this is addressed in revision.txt]
set_db lp_insert_clock_gating 0

# Retain hierarchy during synthesis
# Easier to debug but try to COMMENT and see usage difference
set_db auto_ungroup none

###############################################################
## Library setup
###############################################################

#set_db init_lib_search_path "/eda/cad_run/sg13g2/digital/"
set_db init_hdl_search_path "../rtl/core ../rtl/include ../rtl/pdk ../rtl/peripherals ../rtl/primitives ../rtl/wb"

# Use slow libs, because we are interested in setup time during synthesis

read_libs "/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_slow_1p08V_125C.lib \
/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/lib/RM_IHPSG13_1P_1024x32_c2_bm_bist_slow_1p08V_125C.lib"

read_physical -lef "/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef \
/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef \
/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/lef/RM_IHPSG13_1P_1024x32_c2_bm_bist.lef"

####################################################################
## Load Design
####################################################################
read_hdl -define SYNTHESIS  -language sv -f file_list.f

elaborate $DESIGN

set_top_module $DESIGN


check_design -unresolved

# Write post elaborate netlist
write_hdl > $_OUTPUTS_PATH/post_elab_netlist.v

# Create directories

if {![file exists ${_LOG_PATH}]} {
  file mkdir ${_LOG_PATH}
  puts "Creating directory ${_LOG_PATH}"
}

if {![file exists ${_OUTPUTS_PATH}]} {
  file mkdir ${_OUTPUTS_PATH}
  puts "Creating directory ${_OUTPUTS_PATH}"
}

if {![file exists ${_REPORTS_PATH}]} {
  file mkdir ${_REPORTS_PATH}
  puts "Creating directory ${_REPORTS_PATH}"
}

if {![file exists ${_MODUS_WORKDIR}]} {
  file mkdir ${_MODUS_WORKDIR}
  puts "Creating directory ${_MODUS_WORKDIR}"
}

####################################################################
## Constraints Setup
####################################################################

read_sdc ibex.sdc
# TODO: What are these exceptions??
puts "The number of exceptions is [llength [vfind "design:$DESIGN" -exception *]]"

# Check SDC quality and give warnings
check_timing_intent -verbose > $_REPORTS_PATH/check_timing_intent.rpt

check_design > $_REPORTS_PATH/check_design.rpt

# ##################################################################################################
# ## DFT Setup
# ##################################################################################################

# # Specify scan style
# set_db / .dft_scan_style muxed_scan 

# # Set prefixes added for scan nets
# set_db / .dft_prefix DFT_ 

# # For VDIO customers, it is recommended to set the value of the next two attributes to false.
# # Auto identification of DFT test clocks
# set_db / .dft_identify_top_level_test_clocks true 
# # Auto identification of async set and reset signals which control async set and reset pins of flip-flops 
# set_db / .dft_identify_test_signals true 
# set_db / .dft_identify_internal_test_clocks false 
# # NON-DEFAULT Set to false to prevent registers from being mapped to scan flip-flops for functional use [p.349 Genus Design for Test Guide]
# set_db / .use_scan_seqs_for_non_dft false 

# set_db "design:$DESIGN" .dft_scan_map_mode tdrc_pass 
# set_db "design:$DESIGN" .dft_connect_shift_enable_during_mapping tie_off 
# set_db "design:$DESIGN" .dft_connect_scan_data_pins_during_mapping loopback 
# set_db "design:$DESIGN" .dft_scan_output_preference auto 
# set_db "design:$DESIGN" .dft_lockup_element_type preferred_level_sensitive 
# #set_db "design:$DESIGN" .dft_mix_clock_edges_in_scan_chains true 

# # Remove all synchronizers from scan chains (Darius sake nereikia sito)
# # set_db [vfind inst:ibex_simple_system/u_i2c/u_wb_i2c/byte_controller/bit_controller/cSCL_reg*] .dft_dont_scan true
# # # GPIO sync regs
# # set_db [vfind inst:ibex_simple_system/u_gpio/u_wb_gpio/sync_reg*] .dft_dont_scan true
# # # Reset sync logic 
# # set_db [vfind inst:ibex_simple_system/u_areset_sync/synch_regs_q_reg*] .dft_dont_scan true

# #set_db <instance or subdesign> .dft_dont_scan true 
# #set_db "<from pin> <inverting|non_inverting>" .dft_controllable <to pin>

# # Rise and fall times as default because the source clock is not a primary net
# # define_test_clock -name clk_test -period 10000 ibex_simple_system/u_ibex_simple_system_int/clk_sys
# define_test_clock -name clk_test -period 10000 clk_sys_Pad 

# # Connect to scan_en pin because it is multiplexed in rtl
# # define_shift_enable -name scan_en -active high ibex_simple_system/u_ibex_simple_system_int/scan_en -hookup_pin ibex_simple_system/GPIO[4].pad_io/PAD

# define_shift_enable \
#     -name scan_en \
#     -active high \
#     -lec_value 0 \
#     -hookup_pin ibex_simple_system/u_ibex_simple_system_int/scan_en \
#     ext_pad[4]

# define_test_mode -name test_mode -active high -lec_value 0 test_mode 

# # Must do shared_input and shared_output otherwise it errors out because ext_pads already have connections
# define_scan_chain \
#     -name scan_chain \
#     -sdi ext_pad[2] \
#     -sdo ext_pad[3] \
#     -hookup_pin_sdi ibex_simple_system/u_ibex_simple_system_int/scan_in \
#     -hookup_pin_sdo ibex_simple_system/u_ibex_simple_system_int/scan_out \
#     -shared_input \
#     -shared_output \
#     -shift_enable scan_en 
    
# # Specifies whether an existing functional output port can be used as scan data output port. If the functional port can be used for scan data purposes, a mux is inserted in the scan data path by the connect_scan_chains command.

# ## Run the DFT rule checks
# check_dft_rules > $_REPORTS_PATH/${DESIGN}-tdrcs
# report_scan_registers > $_REPORTS_PATH/${DESIGN}-DFTregs
# report_scan_setup > $_REPORTS_PATH/${DESIGN}-DFTsetup_tdrc

# ## Fix the DFT Violations
# ## Uncomment to fix dft violations (IMPORTANT - must recheck dft rules)
# set numDFTviolations [check_dft_rules]
# if {$numDFTviolations > "0"} {
#   report_dft_violations > $_REPORTS_PATH/${DESIGN}-DFTviols  
#   # TODO might need to add clock to the following
#   fix_dft_violations -async_set -async_reset -test_control test_mode
#   check_dft_rules > $_REPORTS_PATH/${DESIGN}-tdrcs_post_fixing
# }

# ##  Run the Advanced DFT rule checks to identify:
# ## ...  x-source generators, internal tristate nets, and clock and data race violations
# ## Note:  tristate nets are reported for busses in which the enables are driven by
# ## tristate devices.  Use 'check_design' to report other types of multidriven nets.

# check_design -multiple_driver
# check_dft_rules -advanced  > $_REPORTS_PATH/${DESIGN}-Advancedtdrcs
# # report_dft_violations [-tristate] [-xsource] [-xsource_by_instance] > $_REPORTS_PATH/${DESIGN}-AdvancedDFTViols

####################################################################################################
## Synthesizing to generic 
####################################################################################################
set_db / .syn_generic_effort $GEN_EFF
syn_generic

write_hdl > $_OUTPUTS_PATH/post_syn_generic_netlist.v
# Reports datapath??
report_dp > $_REPORTS_PATH/generic/${DESIGN}_datapath.rpt
write_snapshot -outdir $_REPORTS_PATH/generic -tag generic
report_summary -directory $_REPORTS_PATH

# report_scan_setup > $_REPORTS_PATH/${DESIGN}-DFTsetup_tdrc_post_gen

# ######################################################################################################
# ## Optional DFT commands (section 1)
# ######################################################################################################
# #############
# ## Add testability logic as required
# #############
# add_shadow_logic \
#     -around ibex_simple_system/u_ibex_simple_system_int/imem/sram1 \
#     -mode bypass \
#     -balance \
#     -test_control test_mode

# add_shadow_logic \
#     -around ibex_simple_system/u_ibex_simple_system_int/imem/sram2 \
#     -mode bypass \
#     -balance \
#     -test_control test_mode

# add_shadow_logic \
#     -around ibex_simple_system/u_ibex_simple_system_int/dmem/sram \
#     -mode bypass \
#     -balance \
#     -test_control test_mode
# #add_test_point -location <port|pin> -test_control <test_signal> -type <string>


####################################################################################################
## Synthesizing to gates
####################################################################################################

# Synthesize to technology mapped components
set_db / .syn_map_effort $MAP_OPT_EFF
syn_map


write_hdl > $_OUTPUTS_PATH/post_syn_map_netlist.v

write_snapshot -outdir $_REPORTS_PATH/map -tag map
report_summary -directory $_REPORTS_PATH
report_dp > $_REPORTS_PATH/map/${DESIGN}_datapath.rpt

# Create the intermediate data set for running logic equivalence checking using Conformal LEC
write_do_lec \
    -revised fv_map \
    -log ${_LOG_PATH}/rtl2intermediate.lec.log > ${_OUTPUTS_PATH}/rtl2intermediate.lec.do

#######################################################################################################
## Optimize Netlist
#######################################################################################################
set_db / .syn_opt_effort $MAP_OPT_EFF
syn_opt

write_snapshot -outdir $_REPORTS_PATH/opt -tag syn_opt
report_summary -directory $_REPORTS_PATH

# ######################################################################################################
# ## Optional additional DFT commands. (section 2)
# ######################################################################################################

# ## Re-run DFT rule checks
# check_dft_rules -advanced
# ## Build the full scan chanins
# connect_scan_chains
# report_scan_chains > $_REPORTS_PATH/${DESIGN}-DFTchains

# ## Inserting Compression logic
# ## add_test_compression -ratio <integer>  -mask <string> [-auto_create] [-preview]
# ##report_scan_chains > $_REPORTS_PATH/${DESIGN}-DFTchains_compression
# ## Reapply CPF rules
# #commit_cpf

# #######################################################################################################
# ## Optimize Netlist
# #######################################################################################################
 
# ## remove assigns & insert tiehilo cells during Incremental synthesis
# set_db / .remove_assigns true 
# ##set_remove_assign_options -buffer_or_inverter <libcell> -design <design|subdesign>
# ##set_db / .use_tiehilo_for_const <none|duplicate|unique> 
 
# ## An effort of low was selected to minimize runtime of incremental opto.
# ## If your timing is not met, rerun incremental opto with a different effort level
# set_db / .syn_opt_effort high
# syn_opt -incremental
# write_snapshot -outdir $_REPORTS_PATH/opt_incr -tag syn_opt_incr 
# report_summary -directory $_REPORTS_PATH
# puts "Runtime & Memory after 'syn_opt'"
# time_info INCREMENTAL_POST_SCAN_CHAINS

#############################################
## DFT Reports
#############################################

report_scan_setup > $_REPORTS_PATH/${DESIGN}-DFTsetup_final
write_scandef > $_OUTPUTS_PATH/${DESIGN}-scanDEF

## check_atpg_rules -library <Verilog simulation library files> -compression -directory $MODUS_WORKDIR
## write_dft_jtag_boundary_verification -library <Verilog structural library files> -directory $MODUS_WORKDIR 
write_dft_atpg \
    -library { /eda/cad_run/sg13g2/digital/ixc013g2ng_stdcell/verilog/ixc013g2ng_stdcell.v \
        /eda/cad_run/sg13g2/digital/ixc013g2_iocell/verilog/ixc013g2_iocell.v \
        /eda/cad_run/sg13g2/digital/ixc013g2ng_stdcell/verilog/ixc013g2ng_primitives.v \
        /eda/cad_run/sg13g2/digital/ixc013g2_iocell/verilog/ixc013g2_primitives.v \
        }\
    -directory $_MODUS_WORKDIR  
  
######################################################################################################
## write backend file set (verilog, SDC, config, etc.)
######################################################################################################

report_messages > $_REPORTS_PATH/${DESIGN}_messages.rpt
write_snapshot -outdir $_REPORTS_PATH/final -tag final

# Write post synthesis netlist
write_hdl > $_OUTPUTS_PATH/post_syn_netlist.v
write_sdc > $_OUTPUTS_PATH/post_syn.sdc

# Reports that are not in the snapshot
report_design > $_REPORTS_PATH/$DESIGN\.design
report_timing -max_paths 20 > $_REPORTS_PATH/$DESIGN\.timing
#Flags for timing: -fields, -from -to -through -through_rising for specific path (not necessarily WNS)

report_power > $_REPORTS_PATH/$DESIGN\.power
report_clocks > $_REPORTS_PATH/$DESIGN\.clock

# write the scripts for the ATPG (Modus)
#write_dft_atpg -tcl \
#-delay \
#-library "../ixc013g2ng_stdcell/verilog/ixc013g2ng_stdcell.v" \
#-directory ./atpg_scripts \
#$DESIGN 

#################################
### write_do_lec
#################################
# Write LEC to check intermediate versus final netlist
write_do_lec \
    -golden fv_map \
    -revised $_OUTPUTS_PATH/post_syn_netlist.v \
    -log ${_LOG_PATH}/intermediate2final.lec.log > ${_OUTPUTS_PATH}/intermediate2final.lec.do


puts "Final Runtime & Memory."
time_info FINAL
puts "============================"
puts "Synthesis Finished ........."
puts "============================"

