#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sim/rtl" || exit

mkdir -p ../../tb/out1_images

access="-access +rw "

while getopts "t:g gui h l" opt
do
        case "$opt" in
                g       ) access+="+gui";;
                gui     ) access+="+gui";;
        esac
done

xrun    -sv "$access" +rw -timescale 1ns/1ns -clean \
        +incdir+../../rtl/include/ \
        ../../rtl/wb/wb_pkg.sv \
        ../../rtl/wb/wb_if.sv \
        ../../rtl/wb/wb_sobel.sv \
        ../../rtl/peripherals/sobel_synth.v \
        ../../rtl/peripherals/bram.sv \
        /eda/cad_run/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v \
        ../../tb/sobel_acc_tb.sv 