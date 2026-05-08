# Camera Data Streaming with Preprocessing Using MLAB_MCU
## Student Project Specification

| | |
|---|---|
| **Platform** | MLAB_MCU (Ibex RISC-V) on PYNQ-Z2 (Xilinx Zynq XC7Z020) |
| **Target** | Real-time edge-detected video streamed to PC |
| **Student Groups** | Two groups of 2-5 students each |

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
│  OV7670 ──► [Camera IF*] ──► [Frame BRAM A]           │
│                                     │                 │
│                             [ImgProc Accel]    ◄── WB │
│                                     |                 │
│                                     │                 │
│                              [Frame BRAM B]           │
│                                     │                 │
│                            [Compression Accel] ◄── WB │
│                                     │                 │
│                                     │                 │
│                                [TX FIFO]              │
│                                     │                 │
│              [FTDI Sync FIFO IF*] ◄─┘                 │
│                       │                               │
│                       │                               │
└───────────────────────────────────────────────────────┘
                        │
                     FT2232H ──► USB ──► PC
```

`*` Provided by framework. `WB` = Wishbone slave interface (Ibex CPU on the master side).

### 2.2 Data Flow

The Ibex CPU acts as the control plane. It does not sit in the data path during normal operation - it configures the accelerators, starts transfers, and monitors status registers. The data path is:

1. Camera interface captures a full frame into Frame BRAM A.
2. CPU detects the frame-ready interrupt, writes the source/destination addresses and length to the image processing accelerator CSR, then asserts the start bit.
3. Image processing accelerator reads from Frame BRAM A, applies Sobel edge detection, and writes the result to Frame BRAM B. It asserts the done bit when complete.
4. CPU detects done, configures the compression accelerator with the source address and length, and asserts its start bit.
5. Compression accelerator reads from Frame BRAM B, compresses the data, and streams output into the TX FIFO. It does not wait for a full frame before outputting - compression is pipelined.
6. The FTDI sync FIFO interface drains the TX FIFO and sends data to the PC over USB.

This architecture keeps the two accelerators decoupled and independently testable. The CPU moves a pointer between stages rather than pixel data, so CPU overhead is minimal.

### 2.3 Hardware Platform

| Component | Part | Notes |
|---|---|---|
| FPGA Board | PYNQ-Z2 | Xilinx Zynq XC7Z020 - 4.9 Mb BRAM, PL only (ARM core not used) |
| Camera | OV7670 (no FIFO) | 8-bit parallel DVP, 640×480 @ 30 fps, Y channel only for grayscale |
| USB Bridge | FT2232H | Channel A: sync FIFO data stream. Channel B: UART debug |
| MCU Core | Ibex RISC-V (RV32IMC) | Provided as MLAB_MCU SoC |

### 2.4 Pixel Format

All pixel data flowing between BRAMs and accelerators is defined as follows. Both teams must adhere to this specification:

- 8-bit grayscale (luminance / Y channel from OV7670 YUV422 output)
- Row-major order: pixels stored left-to-right, top-to-bottom
- No padding between rows
- Frame dimensions: 320×240 pixels (QVGA)
- Total frame size: 76,800 bytes

> **Note on BRAM sizing:** two frames at 320×240 = 150 KB. The XC7Z020 has 4.9 Mb (612 KB) of BRAM, giving comfortable headroom for both frame buffers and the TX FIFO.

---

## 3. Framework Provided to Students

The following components are provided complete and are not student deliverables. Students should understand their interfaces but do not need to implement them.

- MLAB_MCU SoC with Ibex core, memory, and Wishbone interconnect
- OV7670 camera capture interface (DVP to Frame BRAM A)
- FTDI FT2232H sync FIFO interface (TX FIFO to USB)
- Frame BRAM A and Frame BRAM B instantiations with fixed port definitions
- Wishbone slave wrapper with CSR register map skeleton (students fill in the logic)
- Simulation testbenches with a synthetic image pre-loaded in BRAM

The testbenches are the primary development environment. Students must have a fully working simulation before moving to hardware.

### 3.1 Wishbone CSR Register Map

Each accelerator is given a Wishbone slave with the following memory-mapped registers. The base address differs per accelerator and is provided in the SoC address map.

| Offset | Name | Access | Description |
|---|---|---|---|
| `0x00` | `CTRL` | R/W | Bit 0: start. Write 1 to begin. Auto-clears when done. |
| `0x04` | `STATUS` | RO | Bit 0: busy. Bit 1: done. Bit 2: error. |
| `0x08` | `SRC_ADDR` | R/W | Base address of source data in BRAM. |
| `0x0C` | `DST_ADDR` | R/W | Base address of destination in BRAM. |
| `0x10` | `LENGTH` | R/W | Number of bytes to process. |

The done bit remains set until CTRL is written again. The CPU polls STATUS or waits for an interrupt (interrupt support is optional).

### 3.2 BRAM Port Interface

Both BRAMs present the following synchronous single-port interface to the accelerators:

| Signal | Direction | Width | Description |
|---|---|---|---|
| `clk` | Input | 1 | System clock |
| `en` | Input | 1 | Enable. Must be high for read or write. |
| `we` | Input | 1 | Write enable. High = write, low = read. |
| `addr` | Input | 17 | Byte address. 0 to 76,799 for a 320×240 frame. |
| `wdata` | Input | 8 | Write data. |
| `rdata` | Output | 8 | Read data. Valid one cycle after addr with en=1, we=0. |

---

## 4. Subproject A - Image Processing Accelerator

### 4.1 Overview

The image processing accelerator reads a raw grayscale frame from Frame BRAM A, applies Sobel edge detection, and writes the result to Frame BRAM B. The CPU configures and starts the accelerator via the Wishbone CSR interface.

### 4.2 The Sobel Algorithm

Sobel edge detection estimates the gradient of pixel intensity at each point in the image. A large gradient indicates an edge.

For each pixel at position (x, y), two 3×3 convolution kernels are applied:

```
        Gx (horizontal)        Gy (vertical)

       -1   0  +1            -1  -2  -1
       -2   0  +2             0   0   0
       -1   0  +1            +1  +2  +1
```

Each kernel is applied to the 3×3 neighbourhood of pixels surrounding (x, y). The results are combined to give the gradient magnitude:

```
   G = |Gx| + |Gy|    (Manhattan approximation - no sqrt needed)
```

The output pixel is G clamped to [0, 255]. Pixels on the image border where the full 3×3 neighbourhood is not available should use mirroring of the boundary pixels.

### 4.3 Performance Requirement

Would be nice to set a performance requirement like at least 4 pixels per clock cycle. Although at a 50 MHz system clock:

```
   320 × 240 pixels / 4 pixels per cycle / 50 MHz = 384 µs per frame
   Camera frame period at 30 fps                  = 33.3 ms
   → Accelerator has ~86× headroom vs camera rate
```

The 4 pixel/cycle is quite faster than the camera but we might replace with a faster camera later.

### 4.4 Design Hints (HIDEN FROM STUDENTS, reveal if they struggle)

- The Sobel kernel requires access to three rows of pixels simultaneously. Think about what you need to store to have those three rows available as the image streams through.
- A pipelined datapath can begin computing a new output pixel every cycle once the pipeline is filled, even if each individual computation takes multiple stages.
- The Sobel kernel values are only ±1 and ±2, so all 8 multiplications reduce to additions and a single left shift.
- Consider what happens at the edges of the image - your design must handle boundaries without reading out-of-bounds addresses.



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

- Pre-loads a 320×240 synthetic test image into the source BRAM at time zero
- Instantiates the student's accelerator module under test
- Drives the Wishbone CSR interface to configure and start the accelerator
- Monitors the destination BRAM (or TX FIFO) for output data
- Compares output against a golden reference and reports pass/fail
- Reports elapsed clock cycles for throughput calculation

Make the testbench simple so the students can modify it to their needs. But it must be there so they have something to start with.


## 8. System Integration

Integration in Phase 5 is a supervised activity. The following must be resolved jointly:

- **Clock domain crossing:** both accelerators share the 50 MHz system clock. The FTDI interface runs on the 60 MHz CLKOUT from the FT2232H chip. The TX FIFO is an asynchronous FIFO crossing this boundary - this is provided by the framework.
- **Frame synchronisation:** the camera interface raises an interrupt when a new frame is written to Frame BRAM A. The CPU interrupt handler starts the image processing accelerator. Students must ensure their done/busy status registers are correctly implemented so the CPU can sequence the two accelerators without race conditions.
- **Backpressure:** if the TX FIFO fills, the compression accelerator must stall rather than drop data. The FIFO full signal must be respected.

---

## Appendix A - Bandwidth Budget

| Stage | Data Rate | Notes |
|---|---|---|
| OV7670 raw output (YUV422) | ~18 MB/s | Full 640×480 @ 30 fps |
| Y channel only at QVGA | ~2.3 MB/s | 320×240 × 30 fps × 1 byte |
| After Sobel (same size) | ~2.3 MB/s | Lossless transform, same frame size |
| After RLE (typical) | ~0.5–1.5 MB/s | Depends on image content |
| After LZSS / Delta+Rice | ~0.3–0.8 MB/s | Estimated 3–8× compression |
| FTDI sync FIFO budget | ~40 MB/s | FT2232H in synchronous FIFO mode |

The bandwidth budget shows significant headroom. Even uncompressed QVGA at 30 fps (2.3 MB/s) fits within the FTDI budget. Compression is therefore primarily a design and algorithm exercise rather than a strict necessity at this resolution - which means students can verify the pipeline is working before compression is fully implemented.

---
