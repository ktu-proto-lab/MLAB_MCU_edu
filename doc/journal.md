## Notes
<!-- [risk] [decision] [revisit] - tag freely -->


---


## TODO

---
## 2026-04-10

Rokas

### Notes

Using sharedbus wishbone interconnect is not applicable when slaves uses `stall` signal.
-  QSPI memory controller, takes about 16 cycles (SPI clock prescaller set to 2), to finish a one single read. During whole reading cycles, when controller is busy, it sets `stall` signal, effectively stalling whole sharedbus. Problem appears if a master with higher priority (data memory master over instruction memory master) tries accesing other slave (`PS + 11 (Assertion output stop: simple_system_tb.dut.u_wb_ibex_top.inst_ibex_top.PendingAccessTrackingCorrect = failed`). A possible fix is to replace line 112 with`if (wbm_cyc[i] && (stall == gnt[i]) ) begin` in file `rtl/wb/wb_interconnect_sharedbus.sv` (potentially losing master priority feature).

- Multiplexing a stall signal (commit a506a10, file `rtl/wb/wb_spi_flash.sv`) works, but only if none of the slaves takes up more than previously mentioned 16 cycles. Exceeding this number of cycles, results in switched up data. As of now, none of the slaves (except QSPI memory controller) uses `stall` signal. This problem will occur implementing DirectMemoryAccess or a debugger.

- Decided to use crossbar wishbone interconnect.

### Did
- Fixed wishbone crossbar interconnect

### Next
- Synthesising whole design with crossbar interconnect.
- Comparing sizes of design using a sharedbus and a crossbar.
- Start implementing external RAM capability (another QSPI controller? same controller, but switching chip select signal?)

### Blocked
- 


---

