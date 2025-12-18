
# To facilitate reordering of the scan nets, uniquify the incoming netlist and make sure that it does not 
# contain Verilog assignment statements involving scan nets
# Kiekviena cele turi buti atskiras modulis, negalim buti keli to pacio modulio instance jei norim kad optimizatorius veiktu efektyviai
set_db init_design_uniquify 1
# Nustatomas technologijos dydis nm reikalingas RC isgavimui veliau
set_db design_process_node 130
# On Chip Variation - matuojant velinimus varijuoja tarp didziausiu ir maziausiu velinimu
set_db timing_analysis_type ocv
# Don't add assigns for LVS
set_db init_no_new_assigns 1

#Ignore scan chain checks TODO: keep this commented or not?
# set_db place_global_ignore_scan false
#####################################
# FILE IMPORT
#####################################
# MMMC failas - lusto funkciniu rezimu ir PVT (Process, Voltage, Temperature) variacijos kampai
read_mmmc ibex_mmmc.view

# Nuskaitom technologijos (metalai, via), std celiu, fiziniu parametru, io celiu .lef bibliotekas
read_physical -lef { \
/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef \
/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef \
/eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/lef/RM_IHPSG13_1P_1024x32_c2_bm_bist.lef}

# Verilog netlist'as su pridetais IO padukais
read_netlist ../syn/synOutData/post_syn_netlist.v

# Pagal biblioteka nurodom kaip vadinasi maitinimo ir zemes mazgai (gali buti ir daugiau nei po viena sudetingesniame projekte)
set_db init_power_nets {VDD}
set_db init_ground_nets {VSS} 

# Inicializuojame projekta
init_design

# read the scan chain
# read_def ../syn/synOutData/ibex_simple_system-scanDEF

# Remove assigns incoming from syn
delete_assigns -add_buffer -report

# read the scan chain
#read_def ../syn/synOutData/final.scan.def 

write_db dbs/init_design.enc

if {![file exists Reports/CTS]} {
  file mkdir Reports/CTS
  puts "Creating directory Reports/CTS"
}
if {![file exists Reports/CTS_OPT]} {
  file mkdir Reports/CTS_OPT
  puts "Creating directory Reports/CTS_OPT"
}
if {![file exists Reports/Place]} {
  file mkdir Reports/Place
  puts "Creating directory Reports/Place"
}
if {![file exists Reports/Route]} {
  file mkdir Reports/Route
  puts "Creating directory Reports/Route"
}
if {![file exists Reports/SignOff_OPT]} {
  file mkdir Reports/SignOff_OPT
  puts "Creating directory Reports/SignOff_OPT"
}
if {![file exists Reports/SignOff_STA]} {
  file mkdir Reports/SignOff_STA
  puts "Creating directory Reports/SignOff_STA"
}
if {![file exists Reports/STA]} {
  file mkdir Reports/STA
  puts "Creating directory Reports/STA"
}
if {![file exists LEC]} {
  file mkdir LEC
  puts "Creating directory LEC/"
}


