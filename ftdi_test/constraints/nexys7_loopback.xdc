## =============================================================================
## fpga_top_ft232h_loopback - Nexys A7-100T (xc7a100tcsg324-1)
## FT2232H Mini Module wired to Pmod JA (data) and Pmod JB (control)
## =============================================================================


## ---- On-board 100 MHz oscillator ----
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name clk [get_ports clk]

## ---- FT2232H 60 MHz CLKOUT ----
## ftdi_clk on Pmod JB10 = H16 (MRCC, clock-capable) 
set_property PACKAGE_PIN H16 [get_ports ftdi_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ftdi_clk]
create_clock -period 16.667 -name ftdi_clk [get_ports ftdi_clk]

## ---- Async clock groups ----
## -include_generated_clocks is harmless here and future-proofs the grouping
## if a clock manager is ever inserted on either clock.
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks clk] \
    -group [get_clocks -include_generated_clocks ftdi_clk]


## ---- Data bus ADBUS[7:0] - Pmod JA ----
set_property PACKAGE_PIN C17 [get_ports {ftdi_data[0]}]
set_property PACKAGE_PIN D18 [get_ports {ftdi_data[1]}]
set_property PACKAGE_PIN E18 [get_ports {ftdi_data[2]}]
set_property PACKAGE_PIN G17 [get_ports {ftdi_data[3]}]
set_property PACKAGE_PIN D17 [get_ports {ftdi_data[4]}]
set_property PACKAGE_PIN E17 [get_ports {ftdi_data[5]}]
set_property PACKAGE_PIN F18 [get_ports {ftdi_data[6]}]
set_property PACKAGE_PIN G18 [get_ports {ftdi_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ftdi_data[*]}]

## ---- Control signals - Pmod JB ----
set_property PACKAGE_PIN D14 [get_ports ftdi_rxf_n]
set_property PACKAGE_PIN F16 [get_ports ftdi_txe_n]
set_property PACKAGE_PIN G16 [get_ports ftdi_rd_n]
set_property PACKAGE_PIN H14 [get_ports ftdi_wr_n]
set_property PACKAGE_PIN E16 [get_ports ftdi_oe_n]
set_property IOSTANDARD LVCMOS33 [get_ports ftdi_rxf_n]
set_property IOSTANDARD LVCMOS33 [get_ports ftdi_txe_n]
set_property IOSTANDARD LVCMOS33 [get_ports ftdi_rd_n]
set_property IOSTANDARD LVCMOS33 [get_ports ftdi_wr_n]
set_property IOSTANDARD LVCMOS33 [get_ports ftdi_oe_n]

## ---- FT2232H sync-245-FIFO I/O timing ----
## Requirements at the FT2232H pins, relative to its CLKOUT (AN_130 Table 2):
##   t4/t5/t11 : RXF#/TXE#/read-data valid 1 .. 7.15 ns after CLKOUT rising edge
##   t9/t14    : RD#/WR# need 8 ns setup, 0 ns hold (write data t12/t13 the same)
## ftdi_clk is created at the FPGA port, i.e. already delayed by the clock
## jumper wire. The chip launches/captures on its local (earlier) CLKOUT edge,
## so the clock wire delay is subtracted on the input side and added on the
## output side. Adjust t_wire_* to the actual jumper length (~5 ns/m).
set t_wire_clk  1.5
set t_wire_data 1.5

set ftdi_in_ports  [get_ports {ftdi_rxf_n ftdi_txe_n ftdi_data[*]}]
set ftdi_out_ports [get_ports {ftdi_oe_n ftdi_rd_n ftdi_wr_n ftdi_data[*]}]

## Chip -> FPGA paths (RXF#, TXE#, data while reading)
set_input_delay  -clock ftdi_clk -max [expr {7.15 + $t_wire_data - $t_wire_clk}] $ftdi_in_ports
set_input_delay  -clock ftdi_clk -min [expr {1.0 - $t_wire_clk}]                 $ftdi_in_ports

## FPGA -> chip paths (OE#, RD#, WR#, data while writing)
## KNOWN ACCEPTED VIOLATION: the unmodified ftdi_245fifo IP drives these
## combinationally (CHIP_DRIVE_AT_NEGEDGE=0) and there is no MMCM to cancel
## the ~5 ns BUFG clock insertion delay, so these paths CANNOT formally close
## (expect several ns of negative WNS). Empirical consequence: the chip
## registers the first RD#/WR# assertion of a burst one clock late, which
## duplicates the first read byte / drops the first written byte per burst.
## See ftdi_test/README.md "Status"; a full fix was prototyped in
## rtl/fpga_top_ft232h_loopback_mmcm.v and intentionally not adopted.
set_output_delay -clock ftdi_clk -max [expr {8.0 + $t_wire_data + $t_wire_clk}]    $ftdi_out_ports
set_output_delay -clock ftdi_clk -min [expr {0.0 - ($t_wire_data + $t_wire_clk)}]  $ftdi_out_ports

## ---- LEDs ----
set_property PACKAGE_PIN H17 [get_ports {LED[0]}]
set_property PACKAGE_PIN K15 [get_ports {LED[1]}]
set_property PACKAGE_PIN J13 [get_ports {LED[2]}]
set_property PACKAGE_PIN N14 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]
