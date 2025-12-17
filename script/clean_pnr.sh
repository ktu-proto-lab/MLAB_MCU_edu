#!/bin/bash
#
# cleanup.sh — Clean up pnr directory
#

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/pnr" || exit

rm -r Reports/
rm -r dbs/
rm -r log/
rm -r LEC/
rm pvsUI_ipvs.log 


