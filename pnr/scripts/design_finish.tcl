##########################
# Sign-Off optimization and timing
##########################
set_db extract_rc_effort_level signoff
set_multi_cpu_usage -remote_host 1
set_db opt_signoff_verbose true


opt_signoff -all \
			-report_prefix signoff_opt \
			-report_dir Reports/SignOff_OPT

time_design_signoff -report_dir Reports/SignOff_STA

write_db dbs/signoff_opt.enc
#########################
# CHECKS
#########################
# Remove blockages so check_drc doesn't throw violations on supply connections to memories
delete_obj [get_db route_blockages]

check_drc           -out_file Reports/check_drc.rpt

check_connectivity -type all \
					-ignore_dangling_wires \
					-geometry_connect \
					-error 1000 \
					-warning 50 \
					-out_file Reports/check_connectivity.rpt

# Antenna check (can add -detailed to see all checked nets and areas)
check_antenna 	-out_file Reports/ibex_simple_system.antenna.rpt \
				-error 1000

##########################
# ADD FILLER CELLS
##########################

add_fillers -base_cells DECAP25JI DECAP10JI DECAP5JI DECAP3JI FEED25JI FEED10JI FEED5JI FEED3JI FEED2JI FEED1JI -prefix FILLER
# No DECAPS to test influence on power
# add_fillers -base_cells FEED25JI FEED10JI FEED5JI FEED3JI FEED2JI FEED1JI -prefix FILLER

########################
# Save verilog netlist
########################
write_netlist pnrOutData/pnr_netlist.v

# Netlist for lvs
write_netlist pnrOutData/pnr_netlist_LVS.v \
-flat \
-include_phys_cells {DECAP3JI DECAP5JI DECAP10JI DECAP25JI vddcore gndcore vddpad gndpad filler1u filler2u filler4u filler10u} \

# WRite SDF for netlist annotation noedge writes single path between comb non-unate timing arcs
write_sdf pnrOutData/simple_system.sdf -edges noedge -recompute_delay_calc

##############################################
# GENERATE FILES FOR EQUIVALENCE CHECKING    
##############################################
#  Set LEC write directory
set_db write_lec_directory_naming_style LEC/%s
# Write LEC script
write_do_lec PnRvsSYN.tcl \
			-golden_design /mlab_shares/Skaitmena/IbexD/syn/synOutData/post_syn_netlist.v \
			-revised_design pnrOutData/pnr_netlist.v \
			-flat \
			-log_file log/postroute_vs_syn.log

# Write final dbs
write_db dbs/final.enc

#########################
# GENERATE GDS		
#########################
write_stream pnrOutData/simple_system.gds \
	-map_file /eda/cad_run/sg13g2/digital/ixc013g2ng_stdcell/lef/map/SG13G2_streamout.map \
	-lib_name DesignLib \
	-output_macros \
	-unit 1000 \
	-mode all

# Report scan chain
report_scan_chain -out_file pnrOutData/postpnr-DFTchains -verbose
