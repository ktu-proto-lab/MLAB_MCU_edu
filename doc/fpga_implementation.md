# FPGA Implementation Guide

## Notes
<!-- [risk] [decision] [revisit] - tag freely -->

[decision] Use **WangXuan95/FPGA-ftdi245fifo** as the sync-FIFO controller rather than writing one from scratch. It supports FT232H and FT2232H in sync-245-FIFO mode, handles the ft_clk<->sys_clk crossing internally with an async FIFO, and has been measured at 42 MB/s FPGA->PC. A thin wrapper (`fpga/rtl/ft2232h_tx.v`) hides the AXI-stream interface and exposes a simple `wr_en / wr_data / full` byte FIFO port to the rest of the design. (Claude generated).

[decision] Only Channel A of the FT2232H can be put into sync-245-FIFO mode. Channel B stays as a UART and is available for debug console traffic. Wire FTDI data pipe to Channel A; Optional: debug UART to Channel B.

[revisit] `fpga/rtl/ft2232h_tx_usage_example.v` shows the PYNQ-Z2 XDC constraints with placeholder `<PIN>` values. Fill in the actual PYNQ-Z2 Pmod pin assignments before hardware bring-up.

[revisit] `TX_DEPTH_EXP=10` gives a 1 kB internal TX buffer. A 320×240 frame is 76,800 bytes - the buffer is a smoothing FIFO, not a full frame store. The compression accelerator must drain it continuously. If the accelerator stalls for more than ~1024/throughput seconds, back-pressure will propagate. Increase to 11 (2 kB) or 12 (4 kB) if bursts are expected.

---

## 1. PC Interface Architecture

```
  sobel_acc                compress_acc               FT2232H Mini Module
  (inter FIFO out) --8b--> (out_wr_en/out_din) --8b--> ft2232h_tx --> USB --> PC
                                                          ^
                                           fpga/rtl/ft2232h_tx.v
                                           wraps ftdi_245fifo_top
```

The pipeline is fully streaming. No frame buffer is needed between the compression accelerator and the PC - bytes flow out as they are produced. Back-pressure from the FT2232H (`full`) must propagate back through the compression accelerator to the intermediate FIFO.

---

## 2. One-Time FT2232H Chip Setup

Each FT2232H chip must be programmed to 245-sync-FIFO mode **once** using FTDI's [FT_Prog](https://ftdichip.com/utilities/) utility. This writes to onboard EEPROM and survives power cycles.

1. Download FT_Prog from the FTDI utilities page.
2. Plug in the FT2232H Mini Module via USB.
3. In FT_Prog: scan devices -> expand the device tree -> select **Channel A -> Hardware -> 245 FIFO**.
4. Click **Program Device**.
5. Unplug and re-plug USB - the new mode takes effect after re-enumeration.

**Channel B** can remain as UART (default) for debug output.

---

## 4. FT2232H Mini Module Pin Connections

Channel A FIFO signals map to the CN2 connector on the Mini Module.

| FT2232H signal | Mini Module net | `ft2232h_tx` port | Direction |
|---|---|---|---|
| ADBUS[7:0] | CN2 pins 1-8  | `ft_data[7:0]` | inout |
| ACBUS0 (RXF#) | CN2 pin 9  | `ft_rxf_n` | input |
| ACBUS1 (TXE#) | CN2 pin 10 | `ft_txe_n` | input |
| ACBUS2 (RD#)  | CN2 pin 11 | `ft_rd_n`  | output |
| ACBUS3 (WR#)  | CN2 pin 12 | `ft_wr_n`  | output |
| ACBUS4 (SIWU) | CN2 pin 13 | `ft_siwu_n`| output (tied 1 in wrapper) |
| ACBUS5 (CLK)  | CN2 pin 14 | `ft_clk`   | input (60 MHz from chip) |
| ACBUS6 (OE#)  | CN2 pin 15 | `ft_oe_n`  | output |
| GND           | CN2 pin 16 | GND        | - |

---

## 5. Wrapper Usage (`fpga/rtl/ft2232h_tx.v`)

The wrapper presents a simple byte FIFO write interface to the rest of the design. See `fpga/rtl/ft2232h_tx_usage_example.v` for a full instantiation template.

```verilog
ft2232h_tx #(
    .TX_DEPTH_EXP ( 10 )    // 1024-byte internal TX buffer; increase if needed
) u_ft2232h (
    .sys_clk    ( sys_clk            ),
    .sys_rst_n  ( sys_rst_n          ),
    // From compression accelerator
    .wr_en      ( comp_valid & ~ft_full ),
    .wr_data    ( comp_byte           ),
    .full       ( ft_full             ),
    // To FT2232H Mini Module pins
    .ft_clk     ( ft_clk   ),
    .ft_data    ( ft_data  ),
    .ft_rxf_n   ( ft_rxf_n ),
    .ft_txe_n   ( ft_txe_n ),
    .ft_rd_n    ( ft_rd_n  ),
    .ft_wr_n    ( ft_wr_n  ),
    .ft_oe_n    ( ft_oe_n  ),
    .ft_siwu_n  ( ft_siwu_n)
);
```

The compression accelerator must check `ft_full` before asserting `wr_en`. When `ft_full` is high it must also stop consuming from the intermediate FIFO - back-pressure must propagate all the way back to the sobel_acc `out_full` input.

---

## 6. XDC Constraints

Two constraints are mandatory and easy to forget.

```tcl
# ft_clk comes from the FT2232H chip itself - declare it as a primary clock.
set_property PACKAGE_PIN <PIN> [get_ports ft_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ft_clk]
create_clock -period 16.667 -name ft_clk [get_ports ft_clk]

# ft_clk and sys_clk are asynchronous - the IP handles crossing internally.
# Without this constraint, Vivado analyses false paths across the domains
# and generates thousands of spurious timing violations.
set_clock_groups -asynchronous \
    -group [get_clocks sys_clk] \
    -group [get_clocks ft_clk]

# Bidirectional data bus (IOBUF instantiated inside the IP, not here)
set_property PACKAGE_PIN <PIN> [get_ports {ft_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[0]}]
# ... repeat for ft_data[1:7] ...

# Control signals
set_property PACKAGE_PIN <PIN> [get_ports ft_rxf_n]
set_property PACKAGE_PIN <PIN> [get_ports ft_txe_n]
set_property PACKAGE_PIN <PIN> [get_ports ft_rd_n]
set_property PACKAGE_PIN <PIN> [get_ports ft_wr_n]
set_property PACKAGE_PIN <PIN> [get_ports ft_oe_n]
set_property PACKAGE_PIN <PIN> [get_ports ft_siwu_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_*]
```

---

## 7. PC-Side Receive (Python)

A minimal Python script to receive the raw byte stream into a file:

```python
import ftd2xx as ft

dev = ft.open(0)                    # Channel A = device index 0
dev.setBitMode(0xFF, 0x40)          # Sync-245-FIFO mode
dev.setTimeouts(5000, 5000)

FRAME_BYTES = 320 * 240
with open("out.pgm", "wb") as f:
    f.write(b"P5\n320 240\n255\n")  # PGM binary header
    received = 0
    while received < FRAME_BYTES:
        chunk = dev.read(FRAME_BYTES - received)
        f.write(chunk)
        received += len(chunk)

dev.close()
```

Requires `pip install ftd2xx` and the FTDI D2XX driver installed on the host. For Linux, `libftd2xx.so` must be on `LD_LIBRARY_PATH`.

---

## TODO
1. Fill in actual PYNQ-Z2 Pmod pin assignments in the XDC (`<PIN>` placeholders).
2. Implement compression accelerator with proper `ft_full` back-pressure.
3. Test loopback: send a known byte pattern, verify receipt on PC.
4. Measure sustained throughput - target is 42 MB/s, QVGA at 30 fps needs ~2.3 MB/s so headroom is large.
