#-------------------------------------------------------------------------
# Perform power rail analysis
#-------------------------------------------------------------------------
proc proc_analyze_power_rail {mainClkPeriod pgnetVDD pgnetVSS pgAnalysisView qrc_techfile voltageSourceMetal outDir} {
      global topModule
      global cellIsBlock

      set_pg_nets -net [lindex $pgnetVDD 0] -voltage [lindex $pgnetVDD 1] -threshold [lindex $pgnetVDD 2]
      set_pg_nets -net [lindex $pgnetVSS 0] -voltage [lindex $pgnetVSS 1] -threshold [lindex $pgnetVSS 2] 

      set_default_switching_activity -input_activity 0.2 -period $mainClkPeriod

      set_power_analysis_mode -method static \
                              -write_static_currents true \
                              -analysis_view func_min \
                              -generate_fsdb_from_logicpropagation true \
                              -corner max \
                              -honor_negative_energy true \
                              -ignore_control_signals true \
                              -create_binary_db true

      set_power_output_dir $outDir

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

      ## if cell is top level with bumps, get the bumps as voltage sources. If no bumps exist in submodules, get the power pins 
      if {!($cellIsBlock)} {
            create_power_pads -net [lindex $pgnetVDD 0] -auto_fetch -layer $voltageSourceMetal -vsrc_file $outDir/${topModule}_[lindex $pgnetVDD 0].pp
            create_power_pads -net [lindex $pgnetVSS 0] -auto_fetch -layer $voltageSourceMetal -vsrc_file $outDir/${topModule}_[lindex $pgnetVSS 0].pp
            set_power_pads -net [lindex $pgnetVDD 0] -format xy -file $outDir/${topModule}_[lindex $pgnetVDD 0].pp
            set_power_pads -net [lindex $pgnetVSS 0] -format xy -file $outDir/${topModule}_[lindex $pgnetVSS 0].pp
      } else {
            set_power_pads -net [lindex $pgnetVDD 0] -format defpin
            set_power_pads -net [lindex $pgnetVSS 0] -format defpin
      }
      set_rail_analysis_domain -name PD -pwrnets [lindex $pgnetVDD 0] -gndnets [lindex $pgnetVSS 0]
      set_power_data -reset

      set pgLibs [list $outDir/static_[lindex $pgnetVDD 0].ptiavg $outDir/static_[lindex $pgnetVSS 0].ptiavg]

      set_power_data -format current -scale 1 $pgLibs

      analyze_rail -type domain -results_directory $outDir PD
}

#-------------------------------------------------------------------------
# Perform ESD analysis using VOLTUS (only woked for innovus15.20)
#-------------------------------------------------------------------------
proc proc_analyze_esd {pgnetVDD pgnetVSS outDir $qrc_techfile} {
  global clampCell
  global bumpCell
  

set clampCell [list PVDD1DGZ_V_G PVSS1DGZ_V_G]

set bumpCell PAD80APB_EU

set_pg_nets -net VDD -voltage 0.9 -threshold 0.8
set_pg_nets -net VSS -voltage 0.0 -threshold 0.1

create_power_pads -net VDD -auto_fetch -layer AP -vsrc_file ESD_analysis/${topModule}_VDD.pp
create_power_pads -net VSS -auto_fetch -layer AP -vsrc_file ESD_analysis/${topModule}_VSS.pp

set_power_pads -net VDD -format xy -file ESD_analysis/${topModule}_VDD.pp
set_power_pads -net VSS -format xy -file ESD_analysis/${topModule}_VSS.pp


generate_pg_library -output ESD_analysis/pglibs

set_rail_analysis_mode  -method static \
                        -accuracy hd \
                        -extraction_tech_file $qrc_techfile \
                        -power_grid_library ESD_analysis/pglibs/techonly.cl \
                        -ignore_shorts true


set_rail_analysis_domain -name PD -pwrnets VDD -gndnets VSS


analyze_esd_network PD -output ESD_analysis -type domain -use_power_pad true -config_file voltus_rules.txt

}
