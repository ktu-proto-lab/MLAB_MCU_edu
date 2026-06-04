# Camera Data Streaming with Preprocessing Using MLAB_MCU
## Student Project Specification

| | |
|---|---|
| **Platform** | MLAB_MCU (Ibex RISC-V) on PYNQ-Z2 (Xilinx Zynq XC7Z020) |
| **Target** | Real-time edge-detected video streamed to PC |
| **Student Groups** | Two groups of 2-3 students each |

---

## 1. Project Overview

The goal of this project is to build a complete video streaming pipeline on an FPGA-based RISC-V microcontroller system. A camera captures a live scene, the image is processed on the FPGA to extract edges, the result is compressed and transmitted to a PC where the video can be displayed in real time.

The project is split into two independent subprojects that will ultimately be integrated together:

- **Subproject A** - Image Processing Accelerator (Sobel edge detection)
- **Subproject B** - Data Compression Accelerator

Each subproject team works independently against a well-defined interface. Integration is performed in the final phase of the project.

---

## 2. System Architecture

### 2.1 Full System Block Diagram

```
                       PYNQ-Z2 FPGA
┌───────────────────────────────────────────────────────┐
│                                                       │
│  OV7670 ──► [Camera IF*] ──► [Input FIFO*]            │
│                                     │                 │
│                             [ImgProc Accel]    ◄── WB │
│                                     │                 │
│                                [Int FIFO*]            │
│                                     │                 │
│                            [Compression Accel] ◄── WB │
│                                     │                 │
│                                [TX FIFO]              │
│                                     │                 │
│              [FTDI Sync FIFO IF*] ◄─┘                 │
│                       │                               │
└───────────────────────────────────────────────────────┘
                        │
                     FT2232H ──► USB ──► PC
```

`*` Provided by framework. `WB` = Wishbone slave interface (Ibex CPU on the master side).

### 2.2 Data Flow

The Ibex CPU acts as the control plane. It does not sit in the data path during normal operation - it configures the accelerators, starts transfers, and monitors status registers. The data path is:

1. Camera interface writes pixel data into the Input FIFO (32-bit words, 4 pixels packed).
2. Image processing accelerator reads pixels from the camera FIFO one byte at a time, processes them, and writes the result one byte at a time to the intermediate FIFO (Int FIFO). It increments `FRAME_COUNT` when a full frame is complete.
3. With `auto_start` set, the accelerator restarts automatically on the next frame with no CPU involvement.
4. Compression accelerator reads processed pixels from the intermediate FIFO, compresses the data, and streams output into the TX FIFO. Both accelerators run concurrently — there is no full-frame wait between stages.
6. The FTDI sync FIFO interface drains the TX FIFO and sends data to the PC over USB.

The pipeline is self-sustaining in steady state once configured. The CPU role is boot-time configuration, error recovery, and liveness monitoring via `FRAME_COUNT`.

### 2.3 Hardware Platform

| Component | Part | Notes |
|---|---|---|
| FPGA Board | PYNQ-Z2 | Xilinx Zynq XC7Z020 - 4.9 Mb BRAM, PL only (ARM core not used) |
| Camera | OV7670 (no FIFO) | 8-bit parallel DVP, 640×480 @ 30 fps, Y channel only for grayscale |
| USB Bridge | FT2232H | Sync FIFO data stream to PC. Could use channel B for UART debug |

### 2.4 Pixel Format

All pixel data flowing between BRAMs and accelerators is defined as follows. Both teams must adhere to this specification:

- 8-bit grayscale (probably use YUV422 output format from OV7670)
- Row-major order: pixels stored left-to-right, top-to-bottom
- No padding between rows
- Initial frame dimensions: 320×240 pixels(QVGA). Can be pushed to 480×360 or 640x480, the camera module can be setup to output in different resolutions.
- Total frame size: 320×240=76,800 bytes

---

## 3. Framework Provided to Students

The following components are provided complete and are not student deliverables. Students should understand their interfaces but do not need to implement them.

- MLAB_MCU SoC with Ibex core, memory, and Wishbone interconnect
- OV7670 camera capture interface (DVP -> Input FIFO)
- Camera FIFO (1024×8-bit FWFT, one pixel per word, can be found in `deps/camera_fifo`)
- Intermediate FIFO - same as Camera FIFO (1024×8-bit FWFT) between the two accelerators
- FTDI FT2232H sync FIFO interface (TX FIFO to USB)
- Wishbone slave wrapper with CSR register map skeleton (students fill in the logic)
- Simulation testbenches with a synthetic image streamed through the FIFO

The testbenches are the primary development environment. Students must have a fully working simulation before moving to hardware.

### 3.1 Wishbone CSR Register Map (Image Processing Accelerator)

Base address: `0x6000_0000`.

| Offset | Name | Access | Description |
|---|---|---|---|
| `0x00` | `CTRL` | R/W | bit[0]: `auto_start` - restart automatically on `frame_ready`. bit[1]: `algo_sel` - 0: pixel inversion, 1: Sobel (student impl). |
| `0x04` | `STATUS` | RO | bit[0]: `busy`. bit[1]: `done` - held for one cycle. bit[2]: `error` - currently unused, should be assigned during development for recovery. |
| `0x08` | `FRAME_COUNT` | RO | Completed frame counter, wraps at 2³². Read to verify pipeline liveness. |

The CPU may poll FRAME_COUNT or wait for an interrupt (interrupt support is not currently setup).

### 3.2 Camera FIFO Port Interface

The camera FIFO (`fifo_fwft`, `DATA_WIDTH=8`, `DEPTH_WIDTH=10`) carries one grayscale pixel per word. The OV7670 delivers pixels one byte at a time, and this FIFO accepts them directly. It is First Word Fall-Through: `dout` is valid without asserting `rd_en` first.

| Signal | Direction | Width | Description |
|---|---|---|---|
| `clk` | Input | 1 | System clock |
| `rst` | Input | 1 | Synchronous reset, active-high |
| `din` | Input | 8 | One pixel (camera side writes) |
| `wr_en` | Input | 1 | Write enable. Data is pushed when `wr_en=1` and `full=0`. |
| `full` | Output | 1 | FIFO full. Do not assert `wr_en` when high. |
| `dout` | Output | 8 | One pixel. Valid whenever `empty=0`. |
| `rd_en` | Input | 1 | Read advance. Assert for one cycle to consume the current pixel and present the next. |
| `empty` | Output | 1 | FIFO empty. `dout` is not valid when high. |

### 3.3 Intermediate FIFO Port Interface

The intermediate FIFO (`fifo_fwft`, `DATA_WIDTH=8`, `DEPTH_WIDTH=11`) sits between the two accelerators. `sobel_acc` writes one processed pixel per cycle; `compress_acc` reads one pixel per cycle. Using a FIFO here (rather than a frame buffer) allows both accelerators to run concurrently.

| Signal | Direction | Width | Description |
|---|---|---|---|
| `clk` | Input | 1 | System clock |
| `rst` | Input | 1 | Synchronous reset, active-high |
| `din` | Input | 8 | One processed pixel (sobel_acc writes) |
| `wr_en` | Input | 1 | Write enable. |
| `full` | Output | 1 | Full. `sobel_acc` must stall when high. |
| `dout` | Output | 8 | One processed pixel. Valid whenever `empty=0`. |
| `rd_en` | Input | 1 | Read advance (compress_acc drives this). |
| `empty` | Output | 1 | Empty. `compress_acc` must stall when high. |

---

## 4. Subproject A - Image Processing Accelerator

### 4.1 Overview

The image processing accelerator reads one pixel (8 bits) per clock cycle from the camera FIFO, processes it, and writes the result one pixel at a time to the intermediate FIFO. Processing begins as pixels arrive — no full-frame buffering anywhere in the pipeline. The CPU configures and starts the accelerator via the Wishbone CSR interface; in `auto_start` mode the pipeline runs without CPU involvement after initial setup.

The reference implementation provided to students performs pixel inversion (`output = ~input`). Students replace this with Sobel edge detection by implementing the `algo_sel=1` branch in the accelerator.

### 4.2 The Sobel Algorithm

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
   G = |Gx| + |Gy|    (Manhattan approximation - no sqrt needed)
```

The output pixel is G clamped to [0, 255]. Pixels on the image border where the full 3×3 neighbourhood is not available should use mirroring of the boundary pixels.

### 4.3 Performance Requirement

The accelerator processes one pixel per clock cycle when neither FIFO is stalling. At 50 MHz this gives:

```
   320 × 240 pixels / 1 pixel per cycle / 50 MHz = 1.54 ms per frame
   Camera frame period at 30 fps                 = 33.3 ms
   → Accelerator has ~21× headroom vs camera rate
```

The accelerator therefore spends most of its time stalled waiting for the camera. The camera FIFO absorbs timing differences between the camera and the accelerator.

### 4.4 Design Hints 

- Data arrives one pixel (8 bits) per clock cycle from the camera FIFO. The Sobel kernel needs three rows simultaneously — you will need internal line buffers (one per row, 320 bytes each) to hold rows N-1 and N while row N+1 streams in.
- A pipelined datapath can produce one output pixel per cycle once the pipeline is filled, even if each individual computation takes multiple stages.
- The Sobel kernel values are only ±1 and ±2, so all multiplications reduce to additions and a single left shift.
- Consider what happens at image borders — your design must handle boundary pixels without reading out-of-bounds addresses.
- Output is also one byte per cycle via `out_wr_en`/`out_din`. Stall the whole pipeline (stop consuming from camera FIFO too) when `out_full` is asserted.



---

## 5. Subproject B - Data Compression Accelerator

### 5.1 Overview

The compression accelerator reads processed image data from Frame BRAM B, compresses it, and streams the output into the TX FIFO that feeds the FTDI USB bridge. The goal is to reduce the data rate to the PC. Lossless compression is required.

### 5.2 Compression Algorithm

Students work through a progression of algorithms, each evaluated in software on the Ibex before hardware implementation.

#### Stage 1 - Baseline: Run-Length Encoding (RLE)

RLE is the starting point. Consecutive identical byte values are replaced by a (count, value) pair. Students implement this in C on the Ibex, measure the compression ratio on the test image, and record the CPU cycles consumed per frame.

Expected outcome: RLE performs well on synthetic images with flat regions but poorly on natural images with fine detail. This motivates the next stage.

#### Stage 2 - Improved Algorithm (TBD)

A more sophisticated algorithm will be selected from the following candidates. Students implement the chosen algorithm in C, compare against RLE, and then proceed to hardware.

**LZSS** - a sliding-window dictionary coder. For each input byte, search recent output for the longest matching string and emit either a (distance, length) back-reference or a literal byte. Compression ratio is significantly better than RLE on natural images. The hardware implementation must manage the sliding window and variable-length output, making it a richer but more demanding design exercise.

**Delta + Rice coding** - store the difference between adjacent pixels (delta encoding), then apply Rice/Golomb coding to exploit the fact that differences cluster near zero for smooth images. Very hardware-friendly: the delta stage is a single subtractor and Rice coding is a shift register with a unary prefix. Naturally pipelined at one pixel per cycle.

The algorithm will be confirmed before students begin Stage 2. Both are described above so students can read ahead.

### 5.3 Pipelining Requirement

The compression accelerator must not wait for a complete frame before beginning output. It must pipeline compression so that compressed bytes are emitted into the TX FIFO as soon as they are produced. The TX FIFO decouples the accelerator from the FTDI interface - the accelerator writes to the FIFO and the FTDI interface reads independently. The FIFO depth is 1024 bytes. The accelerator must handle FIFO full conditions gracefully (backpressure stall, no data loss).

### 5.4 Benchmarking

Students must measure and report the following at each stage:

| Metric | How to measure |
|---|---|
| Compression ratio | Compressed size / original size on the test image |
| Software throughput (bytes/cycle) | Cycle counter on Ibex in C benchmark |
| Hardware throughput (bytes/cycle) | Simulation: input bytes / clock cycles |
| Latency (first output byte) | Simulation: cycles from start to first FIFO write |
| FPGA resource usage | Vivado synthesis report: LUTs, FFs, BRAM |

---

## 6. Simulation Testbenches

### 6.1 What is Provided

Each subproject receives a self-contained Verilog testbench that exercises the accelerator in isolation. The testbench:

- Streams a 320×240 synthetic test image into the Input FIFO word by word
- Instantiates the student's accelerator module under test
- Drives the Wishbone CSR interface to configure and start the accelerator
- Monitors Frame BRAM B (or TX FIFO) for output data
- Compares output against a golden reference and reports pass/fail
- Reports elapsed clock cycles for throughput calculation

Make the testbench simple so students can modify it. It must be there so they have something to start from.

## 8. System Integration

Integration is a supervised activity. The following must be resolved jointly:

- **Clock domain crossing:** both accelerators share the 50 MHz system clock. The FTDI interface runs on the 60 MHz CLKOUT from the FT2232H chip. The TX FIFO is an asynchronous FIFO crossing this boundary - provided by the framework.
- **Frame synchronisation:** in `auto_start` mode the pipeline sequences itself via `frame_ready_i` and `FRAME_COUNT`. In manual mode the CPU interrupt handler starts each stage. Students must ensure `done`/`busy` flags are correctly implemented so the CPU can sequence accelerators without race conditions.
- **Backpressure:** the Input FIFO asserts `full` to stall the camera interface. If the TX FIFO fills, the compression accelerator must stall rather than drop data.

---

## Appendix A - Bandwidth Budget

| Stage | Data Rate | Notes |
|---|---|---|
| OV7670 raw output (YUV422) | ~18 MB/s | Full 640×480 @ 30 fps |
| Y channel only at QVGA | ~2.3 MB/s | 320×240 × 30 fps × 1 byte |
| After Sobel (same size) | ~2.3 MB/s | Lossless transform, same frame size |
| After RLE (typical) | ~0.5-1.5 MB/s | Depends on image content |
| After LZSS / Delta+Rice | ~0.3-0.8 MB/s | Estimated 3-8× compression |
| FTDI sync FIFO budget | ~40 MB/s | FT2232H in synchronous FIFO mode |

The bandwidth budget shows significant headroom. Even uncompressed QVGA at 30 fps (2.3 MB/s) fits within the FTDI budget. Compression is therefore primarily a design and algorithm exercise rather than a strict necessity at this resolution - which means students can verify the pipeline is working before compression is fully implemented.

---
