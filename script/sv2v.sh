#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/sv2v" || exit


export DESIGN="ibex_simple_system"
file_list="file_list.f"

mkdir -p "generated"
mkdir -p "log"

# reads file list
files=""
while read file; do
  module=$(basename -s .sv "$file")
  files+="$file "
done < $file_list

# echo "$files"

# converts all files from file list from SystemVerilog to Verilog and combines them too one file
    sv2v \
    --define=SYNTHESIS \
    --define=YOSYS \
    -I../rtl/primitives/ \
    -I../rtl/include/ \
    $files \
    > "./generated/$DESIGN.v" \
    2> "./log/$DESIGN.log"

# deletes all "#(1)"
    sed 's/#(1)//' "./generated/$DESIGN.v" > "./generated/${DESIGN}_2.v"

    mv "./generated/${DESIGN}_2.v" "./generated/$DESIGN.v"
