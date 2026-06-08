#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sim/rtl" || exit

mkdir -p ../../tb/out2_images

xrun    -sv -access +rw -timescale 1ns/1ns -clean \
        +incdir+../../rtl/include/ \
        ../../rtl/wb/wb_pkg.sv \
        ../../rtl/wb/wb_if.sv \
        ../../rtl/peripherals/compress_acc.sv \
        ../../tb/compress_acc_tb.sv
