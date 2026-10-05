#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sim/rtl" || exit

mkdir -p ../../tb/interpol_images

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
        ../../rtl/peripherals/interpol_acc.sv \
        ../../rtl/peripherals/bram.sv \
        ../../tb/interpol_acc_tb.sv 