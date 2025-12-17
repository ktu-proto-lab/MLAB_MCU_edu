#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sim/rtl" || exit

testbench="simple_system"
access="-access +rw "
randomNumber="+define+RANDOM_NUMBER="$((1+$RANDOM % 255))
logOutput=""


helpFunction (){
        echo ""
        echo "Usage: xrun_sim_run.sh -t uart -g"
        echo -e "\t -t \t \t Specifies testbench, which will be used"
        echo -e "\t \t \t for simulation. Default - simple_system"
        echo -e "\t -g, -gui \t Starts with graphical user interface"
        echo -e "\t -h \t \t This help"
        exit 1
}


while getopts "t:g gui h l" opt
do
        case "$opt" in
                t       ) testbench="$OPTARG";;
                g       ) access+="+gui";;
                gui     ) access+="+gui";;
                h       ) helpFunction ;;
                l       ) logOutput="+define+LOG_OUTPUT";;
        esac
done

# Increase the biggest array that can be probed to EEPROM size
export SHM_UNPACKED_LIMIT=65536

# FUNCTIONAL - definition for SRAM behavioral model
xrun    -sv "$access" -timescale 1ns/1ns -clean \
        "$randomNumber"\
        "$logOutput" \
        -define FUNCTIONAL \
        -f files.f \
        ../../tb/"$testbench"_tb.sv

