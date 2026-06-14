## =============================================================================
## ftdi_test - PYNQ-Z2 (xc7z020clg400-1)
## FT2232H Mini Module wired to Pmod JA and Pmod JB
##
## Pmod JA pin-to-FPGA mapping (PYNQ-Z2 master XDC):
##   JA1  = Y18    JA2  = Y19    JA3  = Y16    JA4  = Y17
##   JA7  = U18    JA8  = U19    JA9  = W18    JA10 = W19
##
## Pmod JB pin-to-FPGA mapping:
##   JB1  = W14    JB2  = Y14    JB3  = T11    JB4  = T10
##   JB7  = V16    JB8  = W16    JB9  = V12    JB10 = W13
##
## FT2232H Mini Module CN2 wiring assumed:
##   ft_data[0] → JA1  (Y18)     ft_data[4] → JA7  (U18)
##   ft_data[1] → JA2  (Y19)     ft_data[5] → JA8  (U19)
##   ft_data[2] → JA3  (Y16)     ft_data[6] → JA9  (W18)
##   ft_data[3] → JA4  (Y17)     ft_data[7] → JA10 (W19)
##
##   ft_rxf_n   → JB1  (W14)
##   ft_txe_n   → JB2  (Y14)
##   ft_rd_n    → JB3  (T11)
##   ft_wr_n    → JB4  (T10)
##   ft_oe_n    → JB7  (V16)
##   ft_siwu_n  → JB8  (W16)
##   ft_clk     → JB9  (V12)  - clock-capable MRCC pin on bank 34
##
## NOTE: V12 is an MRCC pin (MRCC_P of pair V12/W12) - no
##       CLOCK_DEDICATED_ROUTE workaround needed on PYNQ-Z2.
## =============================================================================

## ---- On-board 125 MHz oscillator (PL clock) ----
set_property PACKAGE_PIN H16 [get_ports clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
create_clock -period 8.000 -name clk_in [get_ports clk_in]

## ---- FT2232H 60 MHz CLKOUT ----
set_property PACKAGE_PIN V12 [get_ports ft_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ft_clk]
create_clock -period 16.667 -name ft_clk [get_ports ft_clk]

## ---- Async clock groups ----
set_clock_groups -asynchronous \
    -group [get_clocks clk_in] \
    -group [get_clocks ft_clk]

## ---- Data bus ADBUS[7:0] - Pmod JA ----
set_property PACKAGE_PIN Y18 [get_ports {ft_data[0]}]
set_property PACKAGE_PIN Y19 [get_ports {ft_data[1]}]
set_property PACKAGE_PIN Y16 [get_ports {ft_data[2]}]
set_property PACKAGE_PIN Y17 [get_ports {ft_data[3]}]
set_property PACKAGE_PIN U18 [get_ports {ft_data[4]}]
set_property PACKAGE_PIN U19 [get_ports {ft_data[5]}]
set_property PACKAGE_PIN W18 [get_ports {ft_data[6]}]
set_property PACKAGE_PIN W19 [get_ports {ft_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[*]}]

## ---- Control signals - Pmod JB ----
set_property PACKAGE_PIN W14 [get_ports ft_rxf_n]
set_property PACKAGE_PIN Y14 [get_ports ft_txe_n]
set_property PACKAGE_PIN T11 [get_ports ft_rd_n]
set_property PACKAGE_PIN T10 [get_ports ft_wr_n]
set_property PACKAGE_PIN V16 [get_ports ft_oe_n]
set_property PACKAGE_PIN W16 [get_ports ft_siwu_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_rxf_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_txe_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_rd_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_wr_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_oe_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_siwu_n]

## ---- LEDs (LD0..LD3 on PYNQ-Z2) ----
set_property PACKAGE_PIN R14 [get_ports {led[0]}]
set_property PACKAGE_PIN P14 [get_ports {led[1]}]
set_property PACKAGE_PIN N16 [get_ports {led[2]}]
set_property PACKAGE_PIN M14 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
