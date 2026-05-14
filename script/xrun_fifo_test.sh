#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sim/rtl" || exit

mkdir -p ../../tb/out_images

xrun    -gui -sv -access +rw -timescale 1ns/1ns -clean \
        -input restore_fifo.tcl \
        ../../deps/camera_fifo/rtl/verilog/simple_dpram_sclk.v \
        ../../deps/camera_fifo/rtl/verilog/fifo.v \
        ../../deps/camera_fifo/rtl/verilog/fifo_fwft_adapter.v \
        ../../deps/camera_fifo/rtl/verilog/fifo_fwft.v \
        ../../tb/camera_fifo_tb.sv