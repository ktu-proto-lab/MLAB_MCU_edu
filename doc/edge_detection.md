# Image Processing Accelerator 

## Student Lab Guide

| | |
|---|---|
| **Module** | `rtl/peripherals/sobel_acc.sv` |
| **Testbenches** | `tb/sobel_acc_tb.sv` (isolated), `tb/sobel_full_tb.sv` (full system) |
| **Firmware** | `sw/ibex/test/sobel_acc/` |

---

## 1. Overview

The image processing accelerator streams 32-bit words (4 pixels packed) from the Input FIFO, processes them, and writes results to Frame BRAM B. Processing begins as pixels arrive - no full-frame buffering on the input side.

The CPU configures and starts the accelerator via the Wishbone CSR interface. In `auto_start` mode the pipeline runs frame-after-frame without CPU involvement after initial setup.

A reference implementation is provided that performs pixel inversion (`output = ~input`, `algo_sel=0`). **Your task is to replace this with Sobel edge detection by implementing the `algo_sel=1` branch in `rtl/peripherals/sobel_acc.sv`**

The accelerator sits between the Input FIFO and Frame BRAM B. It reads from the FIFO and writes to BRAM B. The CPU only touches the CSR registers.

To reach the BRAM write bottleneck the accelerator should process one 32-bit word (4 pixels) per clock cycle when the FIFO is not empty. As a 32-bit word can be written to the BRAM each cycle.

---

## 2. The Sobel Algorithm

Sobel edge detection estimates the gradient of pixel intensity at each point in the image. A large gradient indicates an edge.

For each pixel at position (x, y), two 3×3 convolution kernels are applied:

```
        Gx (horizontal)        Gy (vertical)

       -1   0  +1            +1  +2  +1
       -2   0  +2             0   0   0
       -1   0  +1            -1  -2  -1
```

Each kernel is applied to the 3×3 neighbourhood of pixels surrounding (x, y). The results are combined to give the gradient magnitude:

```
   G = |Gx| + |Gy|
```

The output pixel is G clamped to [0, 255]. Pixels on the image border where the full 3×3 neighbourhood is not available should use **mirroring** of the boundary pixels (e.g. the pixel one step outside the left edge mirrors the pixel one step inside).

---

## 3. Accelerator Interface

### 3.1 Wishbone CSR Register Map

Base address: `0x6000_0000`.

| Offset | Name | Access | Description |
|---|---|---|---|
| `0x00` | `CTRL` | R/W | bit[0]: `auto_start` - restart automatically on `frame_ready`.<br>bit[1]: `algo_sel` - 0: pixel inversion (reference), 1: Sobel (student impl). |
| `0x04` | `STATUS` | RO | bit[0]: `busy`.<br>bit[1]: `done` - high for one cycle after a frame completes.<br>bit[2]: `error` - unused; assign during development for recovery. |
| `0x08` | `FRAME_COUNT` | RO | Completed frame counter, wraps at 2³². Poll to verify pipeline liveness. |

### 3.2 FIFO Port Interface

The Input FIFO (`fifo_fwft`, `DATA_WIDTH=32`, `DEPTH_WIDTH=10`) is a First Word Fall-Through FIFO. Data is available on `fifo_dout` without asserting `fifo_rd_en` first; `fifo_rd_en` advances to the next word on the following cycle.

| Signal | Direction | Width | Description |
|---|---|---|---|
| `fifo_empty` | Input | 1 | FIFO empty. `fifo_dout` is not valid when high. Stall the datapath. |
| `fifo_dout` | Input | 32 | Read data. Valid whenever `fifo_empty=0`. |
| `fifo_rd_en` | Output | 1 | Read advance. Assert for one cycle to consume the current word and present the next. |

### 3.4 Frame BRAM B Port Interface

Frame BRAM B is 32-bit wide and word-addressed. Four pixels are packed into each word, little-endian (pixel N in bits [7:0], pixel N+1 in bits [15:8], etc.).

| Signal | Direction | Width | Description |
|---|---|---|---|
| `dst_en` | Output | 1 | Enable |
| `dst_we` | Output | 1 | Write enable |
| `dst_addr` | Output | 15 | Word address. 0 to 19,199 for a 320×240 frame. |
| `dst_wdata` | Output | 32 | Write data (4 pixels) |

### 3.5 Pixel Packing

All 32-bit words carry 4 grayscale pixels, little-endian:

```
  bits [7:0]   → pixel N       (leftmost in the group)
  bits [15:8]  → pixel N+1
  bits [23:16] → pixel N+2
  bits [31:24] → pixel N+3    (rightmost in the group)
```

<!-- Frame layout is row-major, 320 pixels wide, 240 rows. Word address = (row × 320 + col) / 4. -->

---

## 5. Simulation

### 5.1 Isolated Testbench (`sobel_acc_tb`)

When you first start developing the edge detection algorithm inside the `sobel_acc` accelerator you will want to test in in isolation. For this reason `tb/sobel_acc_tb.sv` is provided.

The testbench emulates the FWFT FIFO directly, drives the Wishbone CSR interface, and shadows all BRAM B writes into an array for verification. After the frame completes, the array is written out as a P2 ASCII PGM to `tb/out_images/` for visual inspection.

**Workflow:**
1. Set `SRC_IMAGE` in `tb/sobel_acc_tb.sv` to one of the PGMs in `tb/src_images/`.
2. Run the testbench (command below).
3. Open the matching file in `tb/out_images/` for visual verification.

```bash
./script/xrun_sim_sobel.sh
```

### 5.2 Full System Testbench (`sobel_full_tb`)

Instantiates the complete `ibex_simple_system` SoC. The CPU firmware (`sw/ibex/test/sobel_acc/`) runs on the Ibex core - it writes `SOBEL_CTRL=1`, polls `FRAME_COUNT`, then raises GPIO0 to signal completion. The testbench forces `fifo_din`/`fifo_wr_en` (tied off in RTL) to inject pixel words into the camera FIFO. On GPIO0 going high, the testbench reads Frame BRAM B, verifies output against a golden model (for inversion), and writes a PGM.

**Workflow:**
1. Build the firmware:
```bash
cd sw/ibex/test/sobel_acc && make clean && make all
```
2. Run the full system testbench (command below).
3. Inspect the output PGM in `tb/out_images/`.

```bash
./script/xrun_sim_run.sh -t sobel_full
```

You can also run it with GUI for visual debugging:
```bash
./script/xrun_sim_run.sh -t sobel_full -gui
```

---

## 6. Firmware (CPU Side)

The CPU program is in `sw/ibex/test/sobel_acc/core/src/main.c`. It:

1. Enables GPIO0 as output.
2. Writes `SOBEL_CTRL = 0x1` to set `auto_start` with `algo_sel=0` (inversion reference).
3. Polls `SOBEL_FRAME_COUNT` until a frame completes.
4. Raises GPIO0 to signal the testbench.

When you implement Sobel, change `SOBEL_CTRL = 0x3` (`auto_start=1`, `algo_sel=1`) and any other updates you may need.

Build:

```bash
cd sw/ibex/test/sobel_acc
make clean && make all
```

---

## 7. Design Hints

- Data arrives as a stream, 4 pixels per 32-bit word. The Sobel kernel needs three rows simultaneously - you need internal **line buffers** to hold rows N-1 and N while row N+1 streams in.
- A pipelined datapath can produce one output pixel per cycle once the pipeline is filled, even if each individual computation takes multiple stages.
- The Sobel kernel values are only ±1 and ±2, so all multiplications reduce to additions and a single left shift.
- Consider image borders carefully - your design must handle boundary pixels without reading out-of-bounds addresses. Mirror the outermost row/column in the line buffers.
- Output pixels must be packed back into 32-bit words in the same little-endian order as the input before writing to BRAM B.

---
