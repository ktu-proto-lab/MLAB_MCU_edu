# FTDI TX Interface Test

Guide for testing `ft2232h_tx.v` by streaming a magic-word pattern from the FPGA to the PC over the FT2232H Mini Module in 245-sync-FIFO mode.

The other test is loopback from the original WangXuan95/FPGA-ftdi245fifo repository. Refer to 
[Getting started with FT232H](../deps/ftdi_controller/README.md#getting-started-with-ft232h) for a guide.

# Status (Dovydas, 2026-07-07)

Both examples are functional after tying **SIWU# high** (jumper CN2-22 ->
CN2-21 on the Mini Module - a floating/pulled-down SIWU# blocks all FPGA->PC
traffic, TXE# never asserts). Neither example is 100% byte-perfect; the
residual errors are documented below.

## 1. Loopback example

Uses the **unmodified** `deps/ftdi_controller` repo sources
(`fpga_top_ft232h_loopback.v`) with `ftdi_test/constraints/nexys7_loopback.xdc`.

- PC->FPGA->PC loopback works; payload bytes are transferred without bit
  errors.
- Known artifact: the **first byte of each burst is duplicated** (send 16 B,
  receive 17 B with byte 0 doubled), and under sustained load an occasional
  byte is dropped/duplicated at USB packet (~512 B) boundaries.

## 2. Single-direction stream (FPGA->PC) - `ftdi_test/rtl/ftdi_test_top.v`

- Streams 260-byte frames (magic header + 0x00..0xFF counter) continuously;
  verified with `python/ftdi_rx_verify.py`.
- At **full rate** (producer faster than USB drains, so the chip TX buffer is
  always full) exactly **one byte is dropped per 512-byte USB packet**,
  always the first byte written after a TXE# pause.
- **Pacing does not help**: at 6.25 MB/s the loss rate is unchanged (4 MiB
  capture: ~8k bad bytes / 16k frames). TXE# pulses at every 512 B USB packet
  commit regardless of data rate.
- Root cause (ILA-verified): the FPGA logic is correct - it re-presents the
  in-flight byte after the TXE# pulse - but only for one 16.7 ns window,
  which misses the chip's 8 ns setup (unfixable without clock deskew; output
  paths report ~-3..-6 ns WNS, documented in `constraints/nexys7.xdc`).
- **Consequence**: any multi-KB frame will always be corrupted, so this must
  be fixed before carrying camera data. Options:
  (a) MMCM deskew + registered outputs, prototyped in
  `rtl/fpga_top_ft232h_loopback_mmcm.v` (+ `CHIP_DRIVE_AT_NEGEDGE=1` and
  -90 deg output phase) - full ~40 MB/s, but modifies the IP;
  (b) switch to FT245 **async** FIFO mode - ~8 MB/s max, relaxed ~30 ns
  timings that breadboard wiring meets easily, small self-contained TX
  module - **recommended** for the camera stream (a few MB/s).


## Directory Structure

```
ftdi_test/
├── rtl/
│   └── ftdi_test_top.v          - FPGA top-level (pattern generator + ft2232h_tx)
├── constraints/
│   ├── nexys7.xdc               - Nexys A7-100T pin assignments
│   └── pynq_z2.xdc              - PYNQ-Z2 pin assignments
├── python/
│   └── ftdi_rx_verify.py        - PC-side receive and verify script
└── README.md
```

---

## Pattern Format

The FPGA continuously streams 260-byte frames back-to-back:

| Bytes | Value | Description |
|-------|-------|-------------|
| 0-3 | `0xDE 0xAD 0xBE 0xEF` | Magic header |
| 4-259 | `0x00 .. 0xFF` | Incrementing counter payload |

The Python script aligns on the first magic header and verifies every payload byte.

---

## Hardware Setup

### 1. Program the FT2232H Mini Module (one-time)

> **Important**: Before using the FT2232H Mini Module make sure to short CN3 pin 1 to CN3 pin 3 for powering the FT2232H chip from USB. And CN2 pin 1 to CN2 pin 11 for powering the chip IOs. See the [FT2232H Mini Module Datasheet](https://ftdichip.com/wp-content/uploads/2020/07/DS_FT2232H_Mini_Module.pdf) for more information.

Run **FT_Prog** (Windows) and set **Channel A** to **FT 245 FIFO** mode. The default factory mode is UART - it must be changed before any of this will work.

Use the guide from the original [ftdi245fifo repository](../deps/ftdi_controller/README.md#step3-program-ft232h-chip). (If the link doesn't work make sure you have submodules cloned)

### 2. Wire the FT2232H Mini Module to the FPGA


| CN2 Pin | FT2232H Signal | 245-FIFO Function | This design |
|---------|---------------|-------------------|-------------|
| 7  | ADBUS0 | D0     | `ft_data[0]` |
| 10 | ADBUS1 | D1     | `ft_data[1]` |
| 9  | ADBUS2 | D2     | `ft_data[2]` |
| 12 | ADBUS3 | D3     | `ft_data[3]` |
| 14 | ADBUS4 | D4     | `ft_data[4]` |
| 13 | ADBUS5 | D5     | `ft_data[5]` |
| 16 | ADBUS6 | D6     | `ft_data[6]` |
| 15 | ADBUS7 | D7     | `ft_data[7]` |
| 18 | ACBUS0 | RXF#   | `ft_rxf_n` |
| 17 | ACBUS1 | TXE#   | `ft_txe_n` |
| 20 | ACBUS2 | RD#    | `ft_rd_n` |
| 19 | ACBUS3 | WR#    | `ft_wr_n` |
| 24 | ACBUS5 | CLKOUT | `ft_clk` (60 MHz) |
| 23 | ACBUS6 | OE#    | `ft_oe_n` |
| 22 -> 21 | - | SIWU#  | tie high (to VIO) |


> Note: ADBUS and ACBUS pins are interleaved on CN2 (odd pins are one row, even pins the other). Pin numbers are from Table 3.1 of the [FT2232H Mini Module Datasheet](https://ftdichip.com/wp-content/uploads/2020/07/DS_FT2232H_Mini_Module.pdf).

Both boards use **Pmod JA** for the 8-bit data bus and **Pmod JB** for control signals.

#### Nexys A7 wiring

| Signal | CN2 Pin | Pmod | FPGA Pin |
|--------|---------|------|----------|
| `ft_data[0]`  | 7  | JA1  | C17 |
| `ft_data[1]`  | 10 | JA2  | D18 |
| `ft_data[2]`  | 9  | JA3  | E18 |
| `ft_data[3]`  | 12 | JA4  | G17 |
| `ft_data[4]`  | 14 | JA7  | D17 |
| `ft_data[5]`  | 13 | JA8  | E17 |
| `ft_data[6]`  | 16 | JA9  | F18 |
| `ft_data[7]`  | 15 | JA10 | G18 |
| `ft_rxf_n`    | 18 | JB1  | D14 |
| `ft_txe_n`    | 17 | JB2  | F16 |
| `ft_rd_n`     | 20 | JB3  | G16 |
| `ft_wr_n`     | 19 | JB4  | H14 |
| `ft_siwu_n`   | 22 | JB8  | F13 |
| `ft_clk`      | 24 | JB10 | H16 |
| `ft_oe_n`     | 23 | JB7  | E16 |

> **Note:** It's a good idea to use a clock capable pin for `ft_clk`. For me the only free clock-capable pin on Pmod JB is **JB10 = H16 (MRCC)**

#### PYNQ-Z2 wiring

For you to fill in below :)

| Signal | CN2 Pin | Pmod | FPGA Pin |
|--------|---------|------|----------|
| `ft_data[0]`  | 7  |   |  |
| `ft_data[1]`  | 10 |   |  |
| `ft_data[2]`  | 9  |   |  |
| `ft_data[3]`  | 12 |   |  |
| `ft_data[4]`  | 14 |   |  |
| `ft_data[5]`  | 13 |   |  |
| `ft_data[6]`  | 16 |   |  |
| `ft_data[7]`  | 15 |   |  |
| `ft_rxf_n`    | 18 |   |  |
| `ft_txe_n`    | 17 |   |  |
| `ft_rd_n`     | 20 |   |  |
| `ft_wr_n`     | 19 |   |  |
| `ft_siwu_n`   | 22 |   |  |
| `ft_clk`      | 24 |   |  |
| `ft_oe_n`     | 23 |   |  |


---

## Vivado Project Setup

### Source files to add

1. All `.v` files from `deps/ftdi_controller/RTL/ftdi_245fifo/`
2. `deps/ftdi_controller/RTL/fpga_ft232h_example/clock_beat.v`
3. `ftdi_test/rtl/ftdi_test_top.v`
4. `fpga/rtl/ft2232h_tx.v`

### Constraints file

Add the XDC for your board:

| Board | File |
|-------|------|
| Nexys A7-100T | `ftdi_test/constraints/nexys7.xdc` |
| PYNQ-Z2 | `ftdi_test/constraints/pynq_z2.xdc` |

> **PYNQ Z2 XDC is AI GENERATED USE AS A STARTING TEMPLATE**

In Vivado, right-click `ftdi_test_top` -> **Set as Top**. If not already top

---

## LEDs

| LED | Meaning |
|-----|---------|
| `led[3]` | Blinks at ~5 Hz when `ft_clk` (60 MHz from FT2232H) is running |
| `led[2:0]` | Low 3 bits of the frame counter - rolls over every 8 frames |

`led[3]` is the first thing to check after programming. If it is not blinking, the FT2232H is not supplying a clock - verify the USB connection and FT_Prog mode.

---

## Running the PC-Side Verifier

### Install dependency

```bash
pip install ftd2xx
```

You also need the FTDI D2XX shared library. Download `libftd2xx` from the [FTDI website](https://ftdichip.com/drivers/d2xx-drivers/).

Extract, install library into system library and create symlink for the linker, refresh linker cache:
```
tar -xzf libftd2xx-linux-x86_64-1.4.35.tgz
sudo cp linux-x86_64/libftd2xx.so.1.4.35 /usr/local/lib/
sudo ln -s /usr/local/lib/libftd2xx.so.1.4.35 /usr/local
sudo ldconfig
```

Verify it's found:
```
ldconfig -p | grep ftd2xx
```

### Run

Unbind kernel driver
```bash
sudo rmmod ftdi_sio
```

If FPGA is connected to the same computer and you are running an ILA you must unbind only for the FTDI controller
```
echo -n '3-6:1.0' | sudo tee /sys/bus/usb/drivers/ftdi_sio/unbind
```

<!-- A better option 
```bash

``` -->

Then run python
```bash
cd ftdi_test/python
python ftdi_rx_verify.py
```

### Failure modes

| Symptom | Likely cause |
|---------|-------------|
| `Failed to import ftd2xx` | `pip install ftd2xx` not done, or D2XX driver not installed |
| `Could not open FTX232H USB device` | Wrong device name; check FT_Prog. Channel A may need to be the active channel |
| `led[3]` not blinking | FT2232H not supplying `ft_clk` - USB not connected or wrong mode |
