read_lib -lef { \
/eda/cad_run/sg13g2/digital/ixc013g2ng_stdcell/lef/ixc013g2ng_tech.lef \
/eda/cad_run/sg13g2/digital/ixc013g2ng_stdcell/lef/ixc013g2ng_stdcell_v5p7.lef \
/eda/cad_run/sg13g2/digital/ixc013g2ng_stdcell/lef/ixc013g2ng_phys.lef \
/eda/cad_run/sg13g2/digital/ixc013g2_iocell_rev1_2_2/lef/ixc013g2_iocell_v5p8.lef \
/eda/cad_run/sg13g2/digital/RM_IHPSG13_1P_1024x32_c2_bm/lef/RM_IHPSG13_1P_1024x32_c2_bm.lef}

set_pg_library_mode -celltype techonly \
                    -power_pins {VDD 1.2 VDDARRAY 1.2 VDD! 1.2 VDDARRAY! 1.2 VDDCORE 1.2 VDDPAD 3.3} \
                    -ground_pins {VSS VSSCORE VSSPAD VSS!} \
                    -extraction_tech_file /eda/cad_run/sg13g2/SG13G2_618_rev1.3.1/PVS_SG13/qrc/qrcTechFile \
                    -temperature -40 

generate_pg_library
