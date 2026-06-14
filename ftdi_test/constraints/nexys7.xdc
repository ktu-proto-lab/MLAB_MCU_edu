## =============================================================================
## ftdi_test - Nexys A7-100T (xc7a100tcsg324-1)
## FT2232H Mini Module wired to Pmod JA (top row = JA1..4, bottom row = JA7..10)
##
## Pmod JA pin-to-FPGA mapping (Nexys A7 master XDC):
##   JA1  = C17   JA2  = D18   JA3  = E18   JA4  = G17
##   JA7  = D17   JA8  = E17   JA9  = F18   JA10 = G18
##
## FT2232H Mini Module CN2 wiring assumed:
##   ft_data[0] → JA1  (C17)     ft_data[4] → JA7  (D17)
##   ft_data[1] → JA2  (D18)     ft_data[5] → JA8  (E17)
##   ft_data[2] → JA3  (E18)     ft_data[6] → JA9  (F18)
##   ft_data[3] → JA4  (G17)     ft_data[7] → JA10 (G18)
##
## Control signals wired to Pmod JB (top row):
##   JB1  = D14   ft_rxf_n
##   JB2  = F16   ft_txe_n
##   JB3  = G16   ft_rd_n
##   JB4  = H14   ft_wr_n
##   JB7  = E16   ft_oe_n
##   JB8  = F13   ft_siwu_n
##   JB9  = G13   ft_clk  (must be on a MRCC/SRCC-capable pin - see NOTE)
##
## NOTE: ft_clk (60 MHz) must reach a clock-capable input (MRCC or SRCC).
##   On Nexys A7, Pmod JB pin 9 (G13) is not clock-capable.
##   Use the dedicated clock input on pin E3 (sysclk) is the board osc,
##   so instead route ft_clk to an MRCC pin.  Pmod JB pin 10 (H16) is also
##   not CC.  The safest option is to use one of the dedicated clock
##   pins exposed on the XADC header (J2) or accept the placement
##   constraint warning and add CLOCK_DEDICATED_ROUTE = FALSE for
##   prototyping only.  This file adds that workaround - remove it once
##   you re-route to a CC pin.
## =============================================================================

## ---- On-board 100 MHz oscillator ----
set_property PACKAGE_PIN E3 [get_ports clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
create_clock -period 10.000 -name clk_in [get_ports clk_in]

## ---- FT2232H 60 MHz CLKOUT ----
set_property PACKAGE_PIN G13 [get_ports ft_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ft_clk]
create_clock -period 16.667 -name ft_clk [get_ports ft_clk]
# Workaround: allow non-CC routing for prototyping
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ft_clk_IBUF]

## ---- Async clock groups ----
set_clock_groups -asynchronous \
    -group [get_clocks clk_in] \
    -group [get_clocks ft_clk]

## ---- Data bus ADBUS[7:0] - Pmod JA ----
set_property PACKAGE_PIN C17 [get_ports {ft_data[0]}]
set_property PACKAGE_PIN D18 [get_ports {ft_data[1]}]
set_property PACKAGE_PIN E18 [get_ports {ft_data[2]}]
set_property PACKAGE_PIN G17 [get_ports {ft_data[3]}]
set_property PACKAGE_PIN D17 [get_ports {ft_data[4]}]
set_property PACKAGE_PIN E17 [get_ports {ft_data[5]}]
set_property PACKAGE_PIN F18 [get_ports {ft_data[6]}]
set_property PACKAGE_PIN G18 [get_ports {ft_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[*]}]

## ---- Control signals - Pmod JB ----
set_property PACKAGE_PIN D14 [get_ports ft_rxf_n]
set_property PACKAGE_PIN F16 [get_ports ft_txe_n]
set_property PACKAGE_PIN G16 [get_ports ft_rd_n]
set_property PACKAGE_PIN H14 [get_ports ft_wr_n]
set_property PACKAGE_PIN E16 [get_ports ft_oe_n]
set_property PACKAGE_PIN F13 [get_ports ft_siwu_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_rxf_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_txe_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_rd_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_wr_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_oe_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_siwu_n]

## ---- LEDs ----
set_property PACKAGE_PIN H17 [get_ports {led[0]}]
set_property PACKAGE_PIN K15 [get_ports {led[1]}]
set_property PACKAGE_PIN J13 [get_ports {led[2]}]
set_property PACKAGE_PIN N14 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
