## =============================================================================
## fpga_top_ft232h_loopback - Nexys A7-100T (xc7a100tcsg324-1)
## FT2232H Mini Module wired to Pmod JA (data) and Pmod JB (control)
##
## CN2 pin mapping (from FT2232H Mini Module datasheet Table 3.1):
##   ftdi_data[0] = ADBUS0 CN2-7   → JA1  (C17)
##   ftdi_data[1] = ADBUS1 CN2-10  → JA2  (D18)
##   ftdi_data[2] = ADBUS2 CN2-9   → JA3  (E18)
##   ftdi_data[3] = ADBUS3 CN2-12  → JA4  (G17)
##   ftdi_data[4] = ADBUS4 CN2-14  → JA7  (D17)
##   ftdi_data[5] = ADBUS5 CN2-13  → JA8  (E17)
##   ftdi_data[6] = ADBUS6 CN2-16  → JA9  (F18)
##   ftdi_data[7] = ADBUS7 CN2-15  → JA10 (G18)
##   ftdi_rxf_n   = ACBUS0 CN2-18  → JB1  (D14)
##   ftdi_txe_n   = ACBUS1 CN2-17  → JB2  (F16)
##   ftdi_rd_n    = ACBUS2 CN2-20  → JB3  (G16)
##   ftdi_wr_n    = ACBUS3 CN2-19  → JB4  (H14)
##   ftdi_clk     = ACBUS5 CN2-24  → JB9  (G13)
##   ftdi_oe_n    = ACBUS6 CN2-23  → JB7  (E16)
##
## NOTE: G13 (JB9) is not a clock-capable pin. CLOCK_DEDICATED_ROUTE FALSE is
##   used as a prototyping workaround. Move ftdi_clk to JB10 (H16, MRCC) for a
##   clean implementation (JB2/F16 SRCC and JB3/G16 MRCC are used by control signals).
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
set_clock_groups -asynchronous \
    -group [get_clocks clk] \
    -group [get_clocks ftdi_clk]


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

## ---- LEDs ----
set_property PACKAGE_PIN H17 [get_ports {LED[0]}]
set_property PACKAGE_PIN K15 [get_ports {LED[1]}]
set_property PACKAGE_PIN J13 [get_ports {LED[2]}]
set_property PACKAGE_PIN N14 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]
