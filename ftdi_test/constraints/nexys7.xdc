## =============================================================================
## ftdi_test - Nexys A7-100T (xc7a100tcsg324-1)
## =============================================================================

## ---- On-board 100 MHz oscillator ----
set_property PACKAGE_PIN E3 [get_ports clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
create_clock -period 10.000 -name clk_in [get_ports clk_in]

## ---- FT2232H 60 MHz CLKOUT ----
## ftdi_clk on Pmod JB10 = H16 (MRCC, clock-capable) 
set_property PACKAGE_PIN H16 [get_ports ft_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ft_clk]
create_clock -period 16.667 -name ft_clk [get_ports ft_clk]

## ---- Async clock groups ----
set_clock_groups -asynchronous \
    -group [get_clocks clk_in] \
    -group [get_clocks ft_clk]

## ---- FT2232H write-interface output timing (AN_130 Table 2) -------------
## The chip samples ft_data / ft_wr_n on the RISING edge of its CLKOUT and
## requires 8 ns setup (t12/t14), 0 ns hold (t13/t15) AT ITS PINS. The clock
## wire delays ft_clk to the FPGA (chip edge is ~1.5 ns earlier than the port
## edge) and the data wire adds ~1.5 ns of travel, so the port-level budget
## is 8 + 2*1.5 = 11 ns.
set FT_OUT_PORTS [get_ports {ft_data[*] ft_wr_n ft_oe_n ft_rd_n}]
set_output_delay -clock ft_clk -max 11.0 $FT_OUT_PORTS
set_output_delay -clock ft_clk -min  0.0 $FT_OUT_PORTS

## ---- FT2232H read-interface input timing (AN_130 Table 2) --------------
## The chip drives ft_data / ft_rxf_n / ft_txe_n valid t4/t5 = 1..7.15 ns
## after its CLKOUT edge (at its pins). With ~equal clock/data wire lengths
## the wire delays cancel on -max; -min 0.0 is slightly conservative
## (chip min Tco is 1 ns). Hold violations reported here are fixed by the
## router adding delay - check WHS is positive after route.
set FT_IN_PORTS [get_ports {ft_data[*] ft_rxf_n ft_txe_n}]
set_input_delay -clock ft_clk -max 7.15 $FT_IN_PORTS
set_input_delay -clock ft_clk -min 0.0  $FT_IN_PORTS

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
set_property IOSTANDARD LVCMOS33 [get_ports ft_rxf_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_txe_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_rd_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_wr_n]
set_property IOSTANDARD LVCMOS33 [get_ports ft_oe_n]

## ---- LEDs ----
set_property PACKAGE_PIN H17 [get_ports {led[0]}]
set_property PACKAGE_PIN K15 [get_ports {led[1]}]
set_property PACKAGE_PIN J13 [get_ports {led[2]}]
set_property PACKAGE_PIN N14 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
