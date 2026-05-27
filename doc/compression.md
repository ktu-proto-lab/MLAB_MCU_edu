# Data Compression Accelerator 

## Student Lab Guide

| | |
|---|---|
| **Module** | `rtl/peripherals/compress_acc.sv` |
| **Testbenches** | `tb/compress_acc_tb.sv` (isolated), `tb/compress_full_tb.sv` (full system) |
| **Firmware** | `sw/ibex/test/compress_acc/` |

---

## 1. Overview

For this accelerator, a looser framework and specification are provided to let you explore and choose a compression algorithm. You are given a Wishbone slave with basic Control and Status registers as a starting point, along with a software example of run-length encoding performed by the CPU. The latter can also serve as a baseline for a compression benchmark.

The compression must be fast enough to avoid blocking data transfers. In this project, compression is used to increase the throughput of data sent to the host computer through the FTDI USB converter, which nominally operates at around 40 Mb/s.

An algorithm that does not require the full frame is preferable, as it would allow frame BRAM B to be replaced with a FIFO, reducing memory usage and enabling higher resolutions. It would also allow all pipeline stages to operate concurrently, rather than waiting for the edge detection accelerator to finish processing the image before compression can begin.