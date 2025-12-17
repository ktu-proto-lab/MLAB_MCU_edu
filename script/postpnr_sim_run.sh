#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sim/postpnr" || exit

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

# Post P&R functional simulation (in postpnr_sim dir)
xrun    -f files.f \
        "$randomNumber"\
        "$logOutput" \
        -timescale 1ns/1ns \
        "$access" \
        -define SDF \
        -tfile post_pnr.tfile \
        ../../tb/"$testbench"_tb.sv
        
        
