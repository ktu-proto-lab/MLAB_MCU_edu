## Directory structure

Software for the Ibex core.

- `ibex/`: Software directory for building executable programs for the Ibex core.
  - `common/`: Shared files used by all software projects.
    - `drivers/`: Peripheral driver implementations. Each peripheral has its own subdirectory for the original (earliest) version. 
    Updated driver revisions are stored in versioned subdirectories such as `v0.1/`, `v0.2/`, etc.
    For new projects, always use the latest available version. 
    - `lib/`: Common C libraries.
    - `common.mk`: Common MakeFile included by all projects.
    - `crt0.S`: Startup assembly code.
    - `link.ld`: Linker script.
  - `example/`: Template project for creating new programs.
    - `build/`: Program build output directory (created by running `make`).
    - `core/`: Main source and header files, including interrupt handling.
    - `drivers/`: Project-specific copy of the required drivers from `common/drivers/`.
  - `test/`: Main projects used in the MCU labs.
    - `full_peripheral/`: Program that runs a state machine to test all peripherals (for detailed explanation see [test/full_peripheral/readme.md](ibex/test/full_peripheral/readme.md))
    - `gpio_simple/`: Basic GPIO example project.
    - `uart_simple/`: basic UART example project.
  - `other_test/`: Additional projects for testing the MCU. 

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

To build a project, navigate to the desired project directory and run `make`.

For example, to compile the `full_peripheral` project:
```bash
cd test/full_peripheral
make
```
This will create a `build/` directory containing the compiled output.
When rebuilding a project, it is recommended to clean the previous build first:
```bash
make clean
```
This will remove the previous `build/` directory.  

If you compile the software on one machine and run the simulation on another, copy the `build/` directory to the corresponding project directory on the simulation machine. Or at minimum copy the `build/verilog_hex.v` file. `verilog_hex.v` file contains the compiled machine code in a Verilog-readable format and is used to initialize the EEPROM model during simulation.
<!-- 
## Program flashing for FPGA

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
``` -->
