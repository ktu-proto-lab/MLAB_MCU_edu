## Directory structure

Software sources and examples for the Ibex core.

- `ibex_repo_sw_example/`: Reference software from the Ibex repository.
- `ibex_sw/`: Custom software repository for Ibex program generation.
  - `common/`: 
    - `common.mk`: Common MakeFile for all programs
    - `crt0.S`: Startup assembly code.
    - `link.ld`: Linker script.
  - `gpio`:
    - `build/`: Program build folder (Present only after running make)
      - `gpio.bin`: Compiled program bin file ready for uploading to EEPROM (padded with zeros)
      - `verilog_hex.v`: Compiled program in HEX file for simulation
      - `gpio.list`: Compiled assembly listing (human-readable).
    - `gpio.c`: Main C source file for the program.
    - `Makefile`: Build file for compiling the software.
  - `verilog_bin.bin`: (Copied form last compiled program `build/` folder) Compiled program bin file ready for uploading to EEPROM (padded with zeros)
  - `verilog_hex.v`: (Copied form last compiled program build/ folder) Compiled program in HEX file for simulation
  - `verilog_hex.v_mem_test`: EEPROM test file (fils full EEPROM of data, for checking bootloader)
- `programmer/`: Software and firmware required for physical EEPROM programming.
  - `programmer.py`: Software written in python to load BIN file to EEPROM.
  - `programmer.cpp`: ESP32 microcontroller firmware for EEPROM programming.

## Toolchain

#### Ubuntu (Linux)

Install the tools by running the following command in the terminal:
```bash
sudo apt-get install -y make gcc-riscv64-unknown-elf
```

#### Windows

The same commands that are used for Ubuntu can be used under Windows
by using the Windows Subsystem for Linux (WSL).
Activate it and install Ubuntu by following the guide
[here](https://ubuntu.com/tutorials/ubuntu-on-windows#1-overview).

#### macOS
### 😩 

## Compiling
When software is modified, just run 
```bash 
make
```
in program folder. Necessary files for simulation is copied to `ibex_sw/` folder.
If you are compiling software on one machine and running simulation on another, just copy `ibex_sw/verilog_hex.v` file and run simulation.

```bash
make clean
```
Only removes `ibex_sw/gpio/build/` folder, but `verilog_hex.v` and `verilog_bin.bin` in `ibex_sw/` folder remains untouched.

## Programming

To run compiled software on physical hardware for example on FPGA you need to upload the binary image into an I2C EEPROM. We use the 24CS512 EEPROM (see [../doc/24CS512.pdf](../doc/24CS512.pdf)). And we use a custom programmer based on the [ESP8266 MCU](https://www.wemos.cc/en/latest/d1/d1_mini.html). 

Firmware for microcontroller is located in `programmer/`.

To program an EEPROM (after compiling software), connect programmer to a computer and determine which serial port was assigned to the programmer.

#### Ubuntu (Linux)

Type into the terminal

```bash
ls /dev | grep 'ttyUSB'
```

a list of connect serial port using USB should appear. The last one is usually the recently connected one.

#### Windows

Press `Windows` + `R` on the keyboard and type `devmgmt.msc` to open a device manager.

Under the `Ports (COM & LPT)` find your recently connected programmer port. Should be something like `COM5`

Open `programmer/programmer.py` and edit line 9 (for Linux) or line 12 (for Windows).

Install pyserial library:

#### Ubuntu (Linux)
```bash
sudo apt install python3-serial
```
#### Windows
```bash
pip3 install pyserial
```

To flash bin file `ibex/verilog_bin.bin` (copied automaticaly everytime after compilation), simply run

```bash
python3 programmer.py --write
```

To flash different file run
```bash
python3 programmer.py --write -i ../read_back.bin
```

When MCU is turned on, bootloader transfers program from EEPROM to internal memory and then writes it back EEPROM. To check whether the write-back was successful, use `--check` parameter.

Parameter `--write` is recomended to always be used with `--check`, to verify correct bootloader operation.
```bash
python3 programmer.py --check --write 
```

There is also a possibility to save data from EEPROM:
```bash
python3 programmer.py --read --size 65536 --r_addr 0
```
