#------------------------------------------------------
# Rail analysis is Innovus LEGACY!!!
#------------------------------------------------------
set outDir "power"
set topModule "ibex_simple_system"
set qrc_techfile "/eda/cad_run/sg13g2/SG13G2_618_rev1.3.1/PVS_SG13/qrc/qrcTechFile"

set_power_output_dir $outDir

set_pg_nets -net VDD -voltage 1.2 -threshold 1.08
set_pg_nets -net VSS -voltage 0 -threshold 0.12

set_default_switching_activity -input_activity 0.2 -period 12.5

# CHANGE analysis_view to func_powermax once it has been added in mmmmc
set_power_analysis_mode -method static \
                              -write_static_currents true \
                              -analysis_view func_min \
                              -generate_fsdb_from_logicpropagation true \
                              -corner max \
                              -honor_negative_energy true \
                              -ignore_control_signals true \
                              -create_binary_db true

report_power  -rail_analysis_format VS -outfile $outDir/${topModule}_power.rpt

set_rail_analysis_mode  -method era_static \
                              -power_switch_eco false \
                              -generate_movies false \
                              -save_voltage_waveforms false \
                              -generate_decap_eco true \
                              -accuracy xd \
                              -process_techgen_em_rules false \
                              -enable_rlrp_analysis false \
                              -extraction_tech_file $qrc_techfile \
                              -vsrc_search_distance 2500 \
                              -ignore_shorts true \
                              -enable_manufacturing_effects false \
                              -report_via_current_direction false 

set_rail_analysis_domain -name PD -pwrnets VDD -gndnets VSS 

set_power_data -reset

set pgLibs [list $outDir/static_VDD.ptiavg $outDir/static_VSS.ptiavg]

set_power_data -format current -scale 1 $pgLibs

set_power_pads -reset

# The following files have to be edited by hand to specifiy where core VDD and VSS are
set_power_pads -net VDD -format xy -file power/ibex_simple_system_VDD.pp 
set_power_pads -net VSS -format xy -file power/ibex_simple_system_VSS.pp 
 
set_net_group -reset
set_advanced_rail_options -reset

analyze_rail -type domain -output $outDir PD

# Read results into INNOVUS then through GUI Power->Report->Power Rail Results
# LOOK AT WHAT RESULTS ARE BEING READ analyze_rail creates a new report with an incremented number if old already exists
read_power_rail_results -rail_directory power/PD_25C_avg_1

read_power_rail_results -power_db power/power.db

