#! /bin/bash

readonly PROJECT_ROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

cd "$PROJECT_ROOT/pnr" || exit

innovus -stylus -log log/innovus.log -cmd log/innovus.cmd -overwrite 

