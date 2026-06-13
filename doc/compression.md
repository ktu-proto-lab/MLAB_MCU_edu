# Data Compression Accelerator 

## Student Lab Guide

| | |
|---|---|
| **Module** | `rtl/peripherals/compress_acc.sv` |
| **Testbenches** | `tb/compress_acc_tb.sv` (isolated), `tb/compress_full_tb.sv` (full system WIP) |
| **Firmware** | `sw/ibex/test/compress_acc/` |

---

## 1. Goal

Implement a lossless data compression accelerator as the final stage of the on-chip image pipeline. At QVGA resolution the FTDI USB link is not bandwidth-limited, so compression is not strictly necessary, but it demonstrates a real technique used when resolution scales up. Also in the future we might switch to a higher resolution camera.

By the end of this project you will have:
- Implemented Run-Length Encoding (RLE) and decoding in software
- Replaced the pass-through in the hardware accelerator skeleton with your RLE encoder
- Measured the compression ratio on a real Sobel-processed image
- Written CPU firmware to read back compression statistics over Wishbone

---

## 2. Overview

The compression accelerator is the final stage of the on-chip image pipeline. It reads processed pixel words from an intermediate FIFO (written by `sobel_acc`) and streams compressed output into the TX FIFO that feeds the FTDI USB bridge.

```
[Input FIFO] ──► [sobel_acc] ──► [Inter FIFO] ──► [compress_acc] ──► [TX FIFO] ──► [FTDI IF] ──► USB ──► PC
                     ▲                                    ▲
                   WB CSR                              WB CSR
                  (Ibex CPU)                          (Ibex CPU)
```

The **FTDI interface** (FT2232H chip on the board) is the hardware bridge between the FPGA and the PC. The FPGA cannot connect to USB natively, so pixel data is routed from the TX FIFO into the FTDI chip, which presents itself to the PC as a high-speed USB serial device. The PC-side Python script reads the byte stream from this USB port and reconstructs the frames. The FTDI chip has a maximum sustained throughput of around 40 MB/s; the TX FIFO decouples the bursty on-chip datapath from the USB transfer rate.

Using a FIFO between the two accelerators means both stages run concurrently: `sobel_acc` produces words as the camera streams in, and `compress_acc` consumes and compresses them at the same time. There is no full-frame buffering between stages.

A skeleton module is provided in `rtl/peripherals/compress_acc.sv`. It already handles Wishbone CSR decoding, the streaming read loop, and TX FIFO write with backpressure. The pass-through assignment `tx_din = fifo_dout` is the only line that changes - everything around it stays.


---

## 3. Motivation

QVGA video (320×240 @ 30 fps, 1 byte/pixel) produces ~2.3 MB/s, well within the 40 MB/s FTDI budget. Compression is therefore not strictly necessary at this resolution - but it is fun to see how much bandwidth we could save. Also we might move to a bigger resolution camera which will push the FTDI controller's bandwidth budget.

Sobel-processed images compress exceptionally well:

- Sobel highlights edges; the background is zero-valued pixels
- A typical Sobel output is 80-95% zeros
- RLE encoding of such an image can achieve 5-20× compression ratio

### Compression requirements

1. **Lossless** - decompressing the output must reproduce the original frame byte-for-byte.
2. **Backpressure** - the accelerator must stall when `tx_full` is high. No data may be dropped.
3. **`COMPRESSED_SIZE`** - the accelerator must count every byte it writes to the TX FIFO and expose the count in the `COMPRESSED_SIZE` CSR when `done` is asserted.

---

### Tasks

**Task 1:** Implement Run-Length Encoding (RLE) in software (Python, C or whatever you're used to).

**Task 2:** Implement a decoder for RLE in the same software language and verify that encode-decode round-trips correctly.

**Task 3:** Implement the hardware accelerator by replacing the pass-through (`tx_din = fifo_dout`) with your RLE encoder.

**Task 4:** Use the testbench `tb/compress_acc_tb.sv` to test your compression accelerator on an image. The testbench loads a Sobel-processed image into the intermediate FIFO and writes the TX FIFO output to a binary file. See [Simulation](#4-simulation) section for more details.

**Task 5:** Decompress the binary output from Task 4 using your software decoder and verify it matches the original image byte-for-byte.

**Task 6:** Implement the `COMPRESSED_SIZE` register that reports how many bytes were written to the TX FIFO for the last completed frame.

**Task 7:** Write a CPU program that reads the `COMPRESSED_SIZE` register, calculates the compression ratio for each frame, and outputs it via UART.

**Task 8:** Expand the CPU program to dynamically calculate the running average compression ratio as frames arrive.

---

## 4. Simulation

### 4.1 Isolated Testbench (`compress_acc_tb`)

`tb/compress_acc_tb.sv` exercises the compression accelerator in isolation, without the full SoC.

- Loads the intermediate FIFO with an image (a Sobel-processed PGM stored in `tb/src_images/`)
- Drives the Wishbone CSR interface to assert `start`
- Receives data from the TX FIFO and writes it to a file in `tb/out2_images/`
- Reports elapsed clock cycles (so you can later compare with your `COMPRESSED_SIZE` implementation)

**Workflow:**
1. Select the test image by editing `SRC_IMAGE` in `tb/compress_acc_tb.sv`. Using an edge processed examples by default.
2. Run the testbench:
```bash
./script/xrun_sim_compress.sh 
```
3. Decompress the output file using your software decoder and verify it matches the original.

### 4.2 Full Testbench (`compress_full_tb`)

Instantiates the complete `ibex_simple_system` SoC. The CPU firmware (`sw/ibex/test/compress_acc/`) runs on the Ibex core - it writes `COMPRESS_CTRL = 0x1`, polls the `done` bit in `COMPRESS_STATUS`, then raises GPIO0 to signal completion. 

The testbench forces `fifo_din`/`fifo_wr_en` (tied off in RTL) to inject one pixel byte at a time into the intermediate FIFO. Output pixels are captured by shadowing `dut.inter_wr_en`/`dut.inter_din` as compress_acc writes to the TX FIFO. On GPIO0 going high the testbench verifies the shadow against the golden model and writes a PGM.

**Workflow:**
1. Build the firmware:
```bash
cd sw/ibex/test/compress_acc && make clean && make all
```
2. Run the full system testbench:

```bash
./script/xrun_sim_run.sh -t compress_full
```

You can also run it with GUI for visual debugging:
```bash
./script/xrun_sim_run.sh -t compress_full -gui
```

3. For the test example use `script/bin2pgm.py` to convert from .bin to .pgm for visual verification. To run it from project root:
```
python3 script/bin2pgm.py tb/out2_images/baboon_edge_compressed.bin 
```

4. Inspect the output PGM in `tb/out2_images/`.

---

## 5. Output Format (System integration stage)

After compression each frame will have a different size, therefore during system integration, the compression accelerator will need to prepend a packet header so that the PC-side receiver can detect frame boundaries in the raw byte data stream.

An example header could be a 4-byte packet header (2-byte magic marker + 2-byte compressed length) to each frame, derived from the `COMPRESSED_SIZE` CSR.


---

## 6. Accelerator Interface

### 6.1 Wishbone CSR Register Map

Base address: `0x7000_0000`.

| Offset | Name | Access | Description |
|---|---|---|---|
| `0x00` | `CTRL` | R/W | bit[0]: `auto_start` - keep compressing frames continuously; write 0 to stop after the current frame completes. Any CTRL write also clears `done`. |
| `0x04` | `STATUS` | RO | bit[0]: `busy`. bit[1]: `done` - stays high after a frame completes until the next CTRL write. |
| `0x08` | `COMPRESSED_SIZE` | RO | Number of bytes written to the TX FIFO in the last completed frame. Updated atomically when `done` is asserted. **Students must implement this register**. |

### 6.2 Intermediate FIFO Port Interface

The intermediate FIFO (`fifo_fwft`, `DATA_WIDTH=32`) carries processed pixel words from `sobel_acc`. It is a First Word Fall-Through FIFO: data is valid on `fifo_dout` as soon as `fifo_empty=0`, with no read strobe needed to present the first word. Asserting `fifo_rd_en` advances to the next word on the following cycle.

| Signal | Direction | Width | Description |
|---|---|---|---|
| `fifo_empty` | Input | 1 | FIFO empty. `fifo_dout` is not valid when high. Stall the datapath. |
| `fifo_dout` | Input | 8 | Read data. Valid whenever `fifo_empty=0`. |
| `fifo_rd_en` | Output | 1 | Read advance. Assert for one cycle to consume the current word. |

### 6.3 TX FIFO Port Interface

The TX FIFO accepts 8-bit writes. The accelerator must never write when `tx_full` is high.

| Signal | Direction | Width | Description |
|---|---|---|---|
| `tx_wr_en` | Output | 1 | Write enable. Assert for one cycle to push one word. |
| `tx_din` | Output | 8 | Write data. Must be valid when `tx_wr_en=1`. |
| `tx_full` | Input | 1 | FIFO full. Gate `tx_wr_en` on this signal - writing while full silently corrupts data. |

---

# Appendix

## A.1. Candidate Algorithms

### A.1.1 Run-Length Encoding (RLE)

Consecutive identical byte values are replaced by a `(count, value)` pair. This is extremely effective on Sobel images where long runs of `0x00` are common.

**Encoding rule (byte-level, 8-bit count):**
- Scan the input byte stream left to right.
- When a run of identical bytes is detected, emit `(count, value)` where count is 1-255.
- If a run exceeds 255, split into multiple pairs.
- Bytes that do not form runs can be emitted as single pairs `(1, value)`.

**Example:**
```
Input:  00 00 00 00 FF 00 00
Output: 04 00 01 FF 02 00
```

**Worst case:** alternating bytes produce output twice as large as the input. Design your implementation to handle this - do not assume the output is always smaller than the input.

**Hardware note:** the algorithm is naturally streaming. For each output byte your logic decides: does the new input byte continue the current run? If yes, increment the count register. If no, emit the previous `(count, value)` pair and start a new run. You will need to delay one output pair to handle the end-of-run decision.

### A.1.2 Delta + Rice Coding

Store the difference between adjacent pixels (delta encoding) and apply Rice/Golomb coding to exploit the fact that differences cluster near zero for smooth images.

**Delta stage:** for each pixel at position `i`, emit `delta[i] = pixel[i] - pixel[i-1]` (first pixel emitted as-is). For a Sobel image dominated by zeros, most deltas are also zero. Deltas are signed, range [-255, 255]; use a bias (e.g., add 255) to make them unsigned before Rice coding.

**Rice coding:** choose a Rice parameter `k`. For each unsigned value `v`, emit `⌊v / 2^k⌋` unary zeros followed by a 1 (the quotient in unary), then `k` binary bits of the remainder `v mod 2^k`. The parameter `k` should be tuned to the image statistics.

**Hardware note:** the delta stage is a single subtractor and register. Rice coding requires a variable-length bit output, which means you need a bit-packing shift register to assemble complete bytes before writing to the TX FIFO. This is the primary complexity of the design.

### A.1.3 LZSS

A sliding-window dictionary coder. For each input position, search recent output for the longest matching string (up to a maximum match length). Emit a back-reference `(distance, length)` if a match is found; otherwise emit a literal byte with a 1-bit flag.

LZSS achieves better compression than RLE on images with repeated textures, but the hardware is significantly more complex: the sliding window requires a circular buffer and a match-search unit. The variable-length output (references vs. literals) requires bit-level output packing.

This algorithm is a suitable choice if your goal is to explore a more challenging hardware design.
