#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sim/rtl" || exit

mkdir -p ../../tb/out_images

verilator       -Mdir ../../verilator_sim/ \
                ../../tb/sobel_acc_tb.sv \
                +incdir+../../rtl/include/ \
                ../../rtl/wb/wb_pkg.sv \
                ../../rtl/wb/wb_if.sv \
                ../../rtl/peripherals/sobel_acc.sv \
                ../../rtl/peripherals/bram.sv \
                -DNO_MODPORT_EXPRESSIONS \
                -DFUNCTIONAL \
                -DDUMPVCD \
                --Wno-MULTIDRIVEN \
                --Wno-CASEINCOMPLETE \
                --Wno-INITIALDLY \
                --Wno-WIDTHEXPAND \
                --Wno-WIDTHTRUNC \
                --Wno-MULTITOP \
                --Wno-PINMISSING \
                --Wno-MODDUP \
                --Wno-IMPLICIT \
                --Wno-WIDTHCONCAT \
                --Wno-UNOPTFLAT \
                --binary \
                -j 0 \
                --timescale-override 1ns/10ps \
                --trace


../../verilator_sim/Vsobel_acc_tb
