# Data Compression Accelerator 

## Student Lab Guide

| | |
|---|---|
| **Module** | `rtl/peripherals/compress_acc.sv` |
| **Testbenches** | `tb/compress_acc_tb.sv` (isolated), `tb/compress_full_tb.sv` (full system) |
| **Firmware** | `sw/ibex/test/compress_acc/` |

---

## 1. Goal
The overall goal of the compression accelerator is to increase the speed (throughput) at which frames are streamed to the PC over the FTDI-USB converter. The accelerator should achieve this by reducing (compressing) the amount of data that the FTDI-USB converter has to handle. 

## 1. Overview

For this accelerator, a looser framework and specification are provided to let you explore and choose a compression algorithm. You are given a **Wishbone slave with basic Control and Status registers** as a starting point, along with a **software example of run-length encoding** performed by the CPU. The latter can also serve as a baseline for your compression implementation benchmark.

You may ask why don't we simply do compression in software and the answer is ofcourse because that would be very slow and in our aim to speed up the system would only make speed worse.

Therefore the compression accelerator must be fast enough to avoid blocking data transfers. In this project, compression is used to increase the throughput of data sent to the host computer through the FTDI USB converter, which nominally operates at around 40 Mb/s.

An algorithm that does not require the full frame is preferable, as it would allow frame BRAM B to be replaced with a FIFO, reducing memory usage and enabling higher resolutions. It would also allow all pipeline stages to operate concurrently, rather than waiting for the edge detection accelerator to finish processing the image before compression can begin.



------------------------------------------------------------------------------------

# Data Compression Accelerator

## Student Lab Guide

| | |
|---|---|
| **Module** | `rtl/peripherals/compress_acc.sv` |
| **Testbenches** | `tb/compress_acc_tb.sv` (isolated), `tb/compress_full_tb.sv` (full system) |
| **Firmware** | `sw/ibex/test/compress_acc/` |

---

## 1. Overview

The compression accelerator is the final stage of the on-chip image pipeline. It reads processed pixel words from an intermediate FIFO (written by `sobel_acc`) and streams compressed output into the TX FIFO that feeds the FTDI USB bridge.

```
[Input FIFO] ──► [sobel_acc] ──► [Inter FIFO] ──► [compress_acc] ──► [TX FIFO] ──► [FTDI IF] ──► USB ──► PC
                     ▲                                    ▲
                   WB CSR                              WB CSR
                  (Ibex CPU)                          (Ibex CPU)
```

Using a FIFO between the two accelerators means both stages run concurrently: `sobel_acc` produces words as the camera streams in, and `compress_acc` consumes and compresses them at the same time. There is no full-frame wait between stages.

A skeleton module is provided in `rtl/peripherals/compress_acc.sv`. It already handles Wishbone CSR decoding, the streaming read loop, and TX FIFO write with backpressure. The pass-through assignment `tx_din = fifo_dout` is the only line that changes - everything around it stays unless your algorithm requires additional state.

**Your task:** replace the pass-through with a lossless compression algorithm of your choice and add a `COMPRESSED_SIZE` register that reports how many bytes were written to the TX FIFO.

---

## 2. Motivation

QVGA video (320×240 @ 30 fps, 1 byte/pixel) produces ~2.3 MB/s, well within the 40 MB/s FTDI budget. Compression is therefore not strictly necessary at this resolution - but it is fun to see how much bandwidth we could save. Also we might move to a bigger resolution camera which will push the FTDI controller's bandwidth budget.

Sobel-processed images compress exceptionally well:

- Sobel highlights edges; the background is zero-valued pixels
- A typical Sobel output is 80-95% zeros
- RLE encoding of such an image can achieve 5-20× compression ratio

The goal is to demonstrate that hardware compression is faster than software compression, and to measure the compression ratio achieved on a real image.

---

## 3. Accelerator Interface

### 3.1 Wishbone CSR Register Map

Base address: `0x7000_0000`.

| Offset | Name | Access | Description |
|---|---|---|---|
| `0x00` | `CTRL` | R/W | bit[0]: `auto_start` - keep compressing frames continuously; write 0 to stop after the current frame completes. Any CTRL write also clears `done`. |
| `0x04` | `STATUS` | RO | bit[0]: `busy`. bit[1]: `done` - stays high after a frame completes until the next CTRL write. |
| `0x08` | `COMPRESSED_SIZE` | RO | Number of bytes written to the TX FIFO in the last completed frame. Updated atomically when `done` is asserted. **Students must implement this register**. |

**Workflow:** CPU writes `CTRL[0]=1` → accelerator runs continuously frame-after-frame → to capture a result, write `CTRL[0]=0` to stop after the current frame → poll `STATUS[1]` (done) → read `COMPRESSED_SIZE`.

### 3.2 Intermediate FIFO Port Interface

The intermediate FIFO (`fifo_fwft`, `DATA_WIDTH=32`) carries processed pixel words from `sobel_acc`. It is a First Word Fall-Through FIFO: data is valid on `fifo_dout` as soon as `fifo_empty=0`, with no read strobe needed to present the first word. Asserting `fifo_rd_en` advances to the next word on the following cycle.

| Signal | Direction | Width | Description |
|---|---|---|---|
| `fifo_empty` | Input | 1 | FIFO empty. `fifo_dout` is not valid when high. Stall the datapath. |
| `fifo_dout` | Input | 32 | Read data. Valid whenever `fifo_empty=0`. |
| `fifo_rd_en` | Output | 1 | Read advance. Assert for one cycle to consume the current word. |

Four pixels are packed into each 32-bit word, little-endian: pixel N in bits [7:0], pixel N+1 in bits [15:8], pixel N+2 in bits [23:16], pixel N+3 in bits [31:24].

### 3.3 TX FIFO Port Interface

The TX FIFO accepts 32-bit writes. The accelerator must never write when `tx_full` is high.

| Signal | Direction | Width | Description |
|---|---|---|---|
| `tx_wr_en` | Output | 1 | Write enable. Assert for one cycle to push one word. |
| `tx_din` | Output | 32 | Write data. Must be valid when `tx_wr_en=1`. |
| `tx_full` | Input | 1 | FIFO full. Gate `tx_wr_en` on this signal - writing while full silently corrupts data. |

---

## 4. Output Format

Compressed bytes are packed into 32-bit words for the TX FIFO, using the same little-endian convention as the pixel data:

```
  tx_din bits [7:0]   → earliest byte in the compressed stream
  tx_din bits [15:8]  → next byte
  tx_din bits [23:16] → next byte
  tx_din bits [31:24] → latest byte
```

If the total compressed payload is not a multiple of 4 bytes, the last word is zero-padded in the upper bytes.

The number of 32-bit words written to the TX FIFO is `⌈COMPRESSED_SIZE / 4⌉`.

**Framing note:** during system integration, the FTDI interface will prepend a 4-byte packet header (2-byte magic marker + 2-byte compressed length) to each frame, derived from the `COMPRESSED_SIZE` CSR. This is required so that the PC-side receiver can detect frame boundaries in the raw byte data stream.

---

## 5. Algorithm Requirements

1. **Lossless** - decompressing the output must reproduce the original frame byte-for-byte. There must be a matching software decompressor for your chosen algorithm.
2. **Backpressure** - the accelerator must stall when `tx_full` is high. No data may be dropped.
3. **`COMPRESSED_SIZE`** - the accelerator must count every byte it writes to the TX FIFO and expose the count in the `COMPRESSED_SIZE` CSR when `done` is asserted.

**Algorithm is your choice** - any lossless algorithm is accepted. Run-Length Encoding is the simplest starting point. You may develop a software reference first for testing and understanding.

The sections below describe the candidate algorithms in increasing order of complexity.

---

## 6. Candidate Algorithms

### 6.1 Run-Length Encoding (RLE) - recommended starting point

Consecutive identical byte values are replaced by a `(count, value)` pair. This is extremely effective on Sobel images where long runs of `0x00` are common.

**Encoding rule (byte-level, 8-bit count):**
- Scan the input byte stream left to right.
- When a run of identical bytes is detected, emit `(count, value)` where count is 1–255.
- If a run exceeds 255, split into multiple pairs.
- Bytes that do not form runs can be emitted as single pairs `(1, value)`.

**Example:**
```
Input:  00 00 00 00 FF 00 00
Output: 04 00 01 FF 02 00
```

**Worst case:** alternating bytes produce output twice as large as the input. Design your implementation to handle this - do not assume the output is always smaller than the input.

**Hardware note:** the algorithm is naturally streaming. For each output byte your logic decides: does the new input byte continue the current run? If yes, increment the count register. If no, emit the previous `(count, value)` pair and start a new run. You will need to delay one output pair to handle the end-of-run decision.

### 6.2 Delta + Rice Coding

Store the difference between adjacent pixels (delta encoding) and apply Rice/Golomb coding to exploit the fact that differences cluster near zero for smooth images.

**Delta stage:** for each pixel at position `i`, emit `delta[i] = pixel[i] - pixel[i-1]` (first pixel emitted as-is). For a Sobel image dominated by zeros, most deltas are also zero. Deltas are signed, range [-255, 255]; use a bias (e.g., add 255) to make them unsigned before Rice coding.

**Rice coding:** choose a Rice parameter `k`. For each unsigned value `v`, emit `⌊v / 2^k⌋` unary zeros followed by a 1 (the quotient in unary), then `k` binary bits of the remainder `v mod 2^k`. The parameter `k` should be tuned to the image statistics.

**Hardware note:** the delta stage is a single subtractor and register. Rice coding requires a variable-length bit output, which means you need a bit-packing shift register to assemble complete bytes before writing to the TX FIFO. This is the primary complexity of the design.

### 6.3 LZSS

A sliding-window dictionary coder. For each input position, search recent output for the longest matching string (up to a maximum match length). Emit a back-reference `(distance, length)` if a match is found; otherwise emit a literal byte with a 1-bit flag.

LZSS achieves better compression than RLE on images with repeated textures, but the hardware is significantly more complex: the sliding window requires a circular buffer and a match-search unit. The variable-length output (references vs. literals) requires bit-level output packing.

This algorithm is a suitable choice if your goal is to explore a more challenging hardware design.

---

## 8. Simulation

### 8.1 Isolated Testbench (`compress_acc_tb`)

`tb/compress_acc_tb.sv` exercises the compression accelerator in isolation, without the full SoC. It:

- Loads the intermediate FIFO with an image (a Sobel-processed PGM stored in `tb/src_images/` ending with `*_edge`)
- Drives the Wishbone CSR interface to assert `start`
- Receives data from the TX FIFO and writes it to a file in `tb/out2_images/`
- Reports elapsed clock cycles (so you can later compare with your `COMPRESSED_SIZE` implementation)

**Workflow:**
1. Select the test image by editing `SRC_IMAGE` in `tb/compress_acc_tb.sv`.
2. Run the testbench:
```bash
./script/xrun_sim_compress.sh 
```
3. Decompress the output file using the matching software decompressor and verify it matches the original.
4. Inspect elapsed cycles and COMPRESSED_SIZE in the transcript.

### 8.2 Full System Testbench (`compress_full_tb`)

`tb/compress_full_tb.sv` instantiates the complete `ibex_simple_system` SoC. The firmware runs on the Ibex core - it configures both accelerators, injects a test frame through the camera FIFO, and signals completion via GPIO0.

**Workflow:**
1. Build the firmware:
```bash
cd sw/ibex/test/compress_acc && make clean && make all
```
2. Run the full system testbench:
```bash
./script/xrun_sim_run.sh -t compress_full
```
3. Open with GUI for waveform debugging:
```bash
./script/xrun_sim_run.sh -t compress_full -gui
```

---

## 9. Firmware (CPU Side)

The firmware in `sw/ibex/test/compress_acc/core/src/main.c` demonstrates the full sequence:

1. Configure and start the Sobel accelerator; wait for a completed frame (`FRAME_COUNT` increments).
2. Write `COMPRESS_CTRL = 0x1` to set `auto_start` - the accelerator begins immediately and restarts after each frame.
3. Poll `COMPRESS_STATUS` until `done` is set.
4. Read `COMPRESSED_SIZE`.
5. Raise GPIO0 to signal the testbench that results are ready.

A software-only RLE reference is also included in the same directory. Run it with a test image before writing any RTL - this gives you the expected compression ratio to validate your hardware against.

---

## 10. Benchmarking

Measure and report the following for your chosen algorithm:

| Metric | How to measure |
|---|---|
| Compression ratio | `COMPRESSED_SIZE` / 76,800 on the test image |
| Software throughput (bytes/cycle) | If you develop a C reference on the Ibex |
| Hardware throughput (bytes/cycle) | Testbench: input bytes / clock cycles elapsed |

---
