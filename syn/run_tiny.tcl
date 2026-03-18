
set DESIGN "ibex_simple_system"

###############################################################
## Synthesis options
###############################################################
# Default effort is medium for syn_gen and high for syn_opt/syn_map
set GEN_EFF medium
set MAP_OPT_EFF high
set _LOG_PATH log
set _OUTPUTS_PATH synOutData
set _REPORTS_PATH Reports

# UNCOMMENT this for more info (default is 1)
set_db information_level 7  

# Clock gates not available for use in SG13G2 YET(2025-10-17)[this is addressed in revision.txt]
set_db lp_insert_clock_gating 0

# Retain hierarchy during synthesis 
set_db auto_ungroup none

# IHP Open PDK has no preset flops need the following option to replace preset with reset flop
set_db lbr_seq_in_out_phase_opto true

###############################################################
## Library setup
###############################################################

# Tell Genus where to find include files
# set_db init_hdl_search_path "../rtl/include"

# Use slow libs for synthesis because we are interested in setup time
# read_libs "/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_slow_1p08V_125C.lib \
# /eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/lib/RM_IHPSG13_1P_1024x32_c2_bm_bist_slow_1p08V_125C.lib"

# Specifying lef libraries is optional, it enables physical synthesis - the tool makes more precise estimations on wire loads
# this results in the synthesis result being more accurate and more similar to the result after pnr 
# read_physical -lef "/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef \
# /eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef \
# /eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/lef/RM_IHPSG13_1P_1024x32_c2_bm_bist.lef"


read_libs "sky130_fd_sc_hd__ss_100C_1v60.lib"


####################################################################
## Load Design
####################################################################
set_db init_hdl_search_path "../rtl/include"

# read_hdl -define SYNTHESIS -language sv ../sv2v/generated/ibex_simple_system.v
read_hdl -define SYNTHESIS  -language sv -f file_list.f

elaborate $DESIGN

set_top_module $DESIGN

# Check for unre$GEN_EFFsolved modules
check_design -unresolved

# Write post elaborate netlist
write_hdl > $_OUTPUTS_PATH/post_elab_netlist.v

# Create output directories
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

####################################################################
## Constraints Setup
####################################################################

# Read constraints
# read_sdc ibex.sdc
read_sdc tt_um_MLAB_MCU.sdc

puts "The number of exceptions is [llength [vfind "design:$DESIGN" -exception *]]"

# Check SDC quality and give warnings
check_timing_intent -verbose > $_REPORTS_PATH/check_timing_intent.rpt

check_design > $_REPORTS_PATH/check_design.rpt

####################################################################
## Synthesizing to generic gates
####################################################################

# Set effort from macros (at the beginning of the file)
set_db / .syn_generic_effort $GEN_EFF
syn_generic

# Write post syn_gen netlist
write_hdl > $_OUTPUTS_PATH/post_syn_generic_netlist.v

# Reports
report_dp > $_REPORTS_PATH/generic/${DESIGN}_datapath.rpt
write_snapshot -outdir $_REPORTS_PATH/generic -tag generic
report_summary -directory $_REPORTS_PATH

#
# ####################################################################
# ## Map to standard cells from the PDK
# ####################################################################
#
# # Set effort and synthesize to technology components
# set_db / .syn_map_effort $MAP_OPT_EFF
# syn_map
#
# # Write post syn_map netlist
# write_hdl > $_OUTPUTS_PATH/post_syn_map_netlist.v
#
# # Reports
# write_snapshot -outdir $_REPORTS_PATH/map -tag map
# report_summary -directory $_REPORTS_PATH
# report_dp > $_REPORTS_PATH/map/${DESIGN}_datapath.rpt
#
# # Create the intermediate data set for running logic equivalence checking (using Conformal LEC)
# write_do_lec \
#     -revised fv_map \
#     -log ${_LOG_PATH}/rtl2intermediate.lec.log > ${_OUTPUTS_PATH}/rtl2intermediate.lec.do

####################################################################
## Optimize Netlist
####################################################################
# set_db / .syn_opt_effort $MAP_OPT_EFF
# syn_opt
#
# # Reports
# write_snapshot -outdir $_REPORTS_PATH/opt -tag syn_opt
# report_summary -directory $_REPORTS_PATH

####################################################################
## Write files for P&R (verilog, SDC) and Reports
####################################################################

# Write post synthesis netlist
write_hdl > $_OUTPUTS_PATH/post_syn_netlist.v

# Write post synthesis constraints
write_sdc > $_OUTPUTS_PATH/post_syn.sdc

# Reports
report_messages > $_REPORTS_PATH/${DESIGN}_messages.rpt
write_snapshot -outdir $_REPORTS_PATH/final -tag final

#  Extra reports that are not in the snapshot
report_design > $_REPORTS_PATH/$DESIGN\.design
# report_power > $_REPORTS_PATH/$DESIGN\.power
report_clocks > $_REPORTS_PATH/$DESIGN\.clock
report_timing -max_paths 20 > $_REPORTS_PATH/$DESIGN\.timing
#Flags for timing: -fields, -from -to -through -through_rising for specific path (not necessarily WNS)

####################################################################
## Write LEC
####################################################################
# Write LEC to check intermediate versus final netlist
# write_do_lec \
#     -golden fv_map \
#     -revised $_OUTPUTS_PATH/post_syn_netlist.v \
#     -log ${_LOG_PATH}/intermediate2final.lec.log > ${_OUTPUTS_PATH}/intermediate2final.lec.do


puts "Final Runtime & Memory."
time_info FINAL
puts "============================"
puts "Synthesis Finished ........."
puts "============================"

