# FTDI TX Interface Test

Tests `ft2232h_tx.v` by streaming a magic-word pattern from the FPGA to the PC over the FT2232H Mini Module in 245-sync-FIFO mode.

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

Run **FT_Prog** (Windows) and set **Channel A** to **FT 245 FIFO** mode. The default factory mode is UART - it must be changed before any of this will work.

### 2. Wire the FT2232H Mini Module to the FPGA

Both boards use **Pmod JA** for the 8-bit data bus and **Pmod JB** for control signals.

#### FT2232H Mini Module CN2 pinout

| CN2 Pin | FT2232H Signal | Direction | This design |
|---------|---------------|-----------|-------------|
| 1-8 | ADBUS[0:7] | Bidir | `ft_data[7:0]` |
| 9 | ACBUS0 / RXF# | In (FPGA) | `ft_rxf_n` |
| 10 | ACBUS1 / TXE# | In (FPGA) | `ft_txe_n` |
| 11 | ACBUS2 / RD# | Out (FPGA) | `ft_rd_n` |
| 12 | ACBUS3 / WR# | Out (FPGA) | `ft_wr_n` |
| 13 | ACBUS4 / SIWU# | Out (FPGA) | `ft_siwu_n` |
| 14 | ACBUS5 / CLKOUT | In (FPGA) | `ft_clk` (60 MHz) |
| 15 | ACBUS6 / OE# | Out (FPGA) | `ft_oe_n` |
| 16 | GND | - | GND |

#### Nexys A7 wiring

| Signal | CN2 Pin | Pmod | FPGA Pin |
|--------|---------|------|----------|
| `ft_data[0]` | 1 | JA1 | C17 |
| `ft_data[1]` | 2 | JA2 | D18 |
| `ft_data[2]` | 3 | JA3 | E18 |
| `ft_data[3]` | 4 | JA4 | G17 |
| `ft_data[4]` | 5 | JA7 | D17 |
| `ft_data[5]` | 6 | JA8 | E17 |
| `ft_data[6]` | 7 | JA9 | F18 |
| `ft_data[7]` | 8 | JA10 | G18 |
| `ft_rxf_n` | 9 | JB1 | D14 |
| `ft_txe_n` | 10 | JB2 | F16 |
| `ft_rd_n` | 11 | JB3 | G16 |
| `ft_wr_n` | 12 | JB4 | H14 |
| `ft_siwu_n` | 13 | JB8 | F13 |
| `ft_clk` | 14 | JB9 | G13 |
| `ft_oe_n` | 15 | JB7 | E16 |

> **Note:** G13 (JB9) is not a clock-capable pin on the Nexys A7. The XDC includes `CLOCK_DEDICATED_ROUTE FALSE` as a workaround for prototyping. If timing closure fails, move `ft_clk` to an MRCC/SRCC pin (e.g. on the XADC header) and update the XDC.

#### PYNQ-Z2 wiring

| Signal | CN2 Pin | Pmod | FPGA Pin |
|--------|---------|------|----------|
| `ft_data[0]` | 1 | JA1 | Y18 |
| `ft_data[1]` | 2 | JA2 | Y19 |
| `ft_data[2]` | 3 | JA3 | Y16 |
| `ft_data[3]` | 4 | JA4 | Y17 |
| `ft_data[4]` | 5 | JA7 | U18 |
| `ft_data[5]` | 6 | JA8 | U19 |
| `ft_data[6]` | 7 | JA9 | W18 |
| `ft_data[7]` | 8 | JA10 | W19 |
| `ft_rxf_n` | 9 | JB1 | W14 |
| `ft_txe_n` | 10 | JB2 | Y14 |
| `ft_rd_n` | 11 | JB3 | T11 |
| `ft_wr_n` | 12 | JB4 | T10 |
| `ft_siwu_n` | 13 | JB8 | W16 |
| `ft_clk` | 14 | JB9 | V12 |
| `ft_oe_n` | 15 | JB7 | V16 |

> **Note:** V12 is an MRCC pin on PYNQ-Z2 - no clock routing workaround needed.

---

## Vivado Project Setup

### Source files to add

1. All `.v` files from `deps/ftdi_controller/RTL/ftdi_245fifo/`
2. `fpga/rtl/ft2232h_tx.v`
3. `fpga/rtl/ft2232h_tx.v` dependency: `deps/ftdi_controller/RTL/ftdi_245fifo/ftdi_245fifo_top.v` (already covered above)
4. `ftdi_test/rtl/ftdi_test_top.v`
5. `deps/ftdi_controller/RTL/fpga_ft232h_example/clock_beat.v`

### Constraints file

Add the XDC for your board:

| Board | File |
|-------|------|
| Nexys A7-100T | `ftdi_test/constraints/nexys7.xdc` |
| PYNQ-Z2 | `ftdi_test/constraints/pynq_z2.xdc` |

### Top-level parameter

Set the `BOARD` parameter on `ftdi_test_top` before synthesising:

| Value | Board |
|-------|-------|
| `0` | Nexys A7 (100 MHz oscillator → 50 MHz sys_clk) |
| `1` | PYNQ-Z2 (125 MHz oscillator → 62.5 MHz sys_clk) |

In Vivado, right-click the top module → **Set as Top**, then edit generic/parameter in the synthesis settings.

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

On Linux you also need the FTDI D2XX shared library. Download `libftd2xx` from the FTDI website and follow their installation instructions, or install via the system package manager if available.

### Run

```bash
cd ftdi_test/python
python ftdi_rx_verify.py --frames 200
```

Optional arguments:

| Argument | Default | Description |
|----------|---------|-------------|
| `--frames N` | 100 | Number of frames to verify |
| `--device NAME` | `"USB <-> Serial Converter"` | D2XX device name (check with FT_Prog if different) |

### Expected output on success

```
Opening FTDI device: 'USB <-> Serial Converter'
Successfully opened FTX232H USB device: USB <-> Serial Converter
Device opened.  Expecting 200 frames (52000 bytes).
Frame layout: 4-byte magic + 256-byte counter payload

Received 52260 bytes in 0.013 s  (4020 kB/s)
  Sync: skipped 3 byte(s) before first header.

Results: 200/200 frames OK,  0 bad
PASS - all frames verified correctly.
```

### Failure modes

| Symptom | Likely cause |
|---------|-------------|
| `Failed to import ftd2xx` | `pip install ftd2xx` not done, or D2XX driver not installed |
| `Could not open FTX232H USB device` | Wrong device name; check FT_Prog. Channel A may need to be the active channel |
| Magic header not found | FT2232H not in 245-FIFO mode, or bitstream not loaded |
| Payload mismatches | Pin wiring error on the data bus - check bit ordering |
| `led[3]` not blinking | FT2232H not supplying `ft_clk` - USB not connected or wrong mode |
