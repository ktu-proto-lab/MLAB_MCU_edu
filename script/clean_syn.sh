#!/bin/bash
#
# cleanup.sh — Clean up synthesis directory
#

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/syn" || exit

rm -r fv
rm -r fv_map_post_syn_netlistv_db
rm -r rtl_fv_map_db
rm hier_tmp2.lec.do 
rm fv_map_post_syn_netlistv_1.map.do 

rm -r log/
rm -r synOutData/
rm -r Reports/
rm -r modus/

# Remove hidden files and directories
# rm -rf .[!.]* ..?*


