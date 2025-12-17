#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sw/ibex_sw/common/" || exit

# sudo apt-get install -y make gcc-riscv64-unknown-elf
mkdir -p lib
rm -r lib/*
cd lib
apt-get source newlib-source
# wget ftp://sourceware.org/pub/newlib/newlib-4.4.0.20231231.tar.gz
tar -xzvf newlib-*.tar.gz
mkdir newlib_build
cd newlib_build
../newlib-*/configure --target=riscv64-unknown-elf \
            --prefix="$PROJECT_ROOT/sw/ibex_sw/common/lib/newlib_build" \
            CFLAGS_FOR_TARGET="-O2 -Os -ffunction-sections -fdata-sections -march=rv32imc_zicsr -mabi=ilp32" \
            --with-newlib \
            --disable-newlib-supplied-syscalls \
            --disable-libm \
            --disable-shared \
            --disable-threads \
            --disable-multilib \
            --disable-newlib-io-long-long \
            --disable-newlib-io-float \
            --disable-newlib-io-pos-args \
            --disable-newlib-multithread \
            --disable-newlib-reent-small \
            --disable-newlib-io-c99-formats \
            --disable-newlib-fvwrite-in-streamio \
            --disable-newlib-fseek-optimization \
            --disable-newlib-wide-orient \
            --disable-newlib-unbuf-stream-opt \
            --disable-newlib-supplied-syscalls \
            --disable-nls \
            --enable-newlib-reent-small \
            --enable-newlib-nano-malloc \
            --enable-newlib-nano-formatted-io \
            --enable-lite-exit \
            --enable-newlib-global-atexit
            


#             --disable-multilib \
#             --disable-newlib-supplied-syscalls \
#             --disable-newlib-fvwrite-in-streamio \
#             --disable-newlib-fseek-optimization \
#             --disable-newlib-wide-orient \
#             --disable-newlib-unbuf-stream-opt \
#             --disable-newlib-io-c99-formats \
#             --disable-newlib-io-long-long \
#             --disable-newlib-io-float \
#             --disable-newlib-io-pos-args \
#             --disable-newlib-multithread \
#             --disable-newlib-reent-small \
#             --disable-nls \
#             --enable-newlib-nano-malloc \
#             --enable-newlib-nano \
#             --enable-newlib-nano-formatted-io \
#             --enable-lite-exit \
#             --with-newlib-nano





make all -j4
make install

rm -r ../newlib-*
rm -r ../newlib_build/riscv64-unknown-elf/newlib
rm -r ../newlib_build/riscv64-unknown-elf/libgloss
