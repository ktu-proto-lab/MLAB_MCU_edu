## Journal for tracking progress of the edge detection assignment development

## Notes
<!-- [risk] [decision] [revisit] - tag freely -->
[revisit] Vivado will not infer BRAM from the IHP behavioral SRAM memories (IMEM and DMEM) because clock is muxed, bit-level write masks are used etc. If we want to significantly increase the sizes of these CPU memories, we will need to switch to models that infer BRAM.

[revisit] `camera_fifo` behavioral sim files placed in `fpga/IP/`; to be regenerated targeting XC7Z020 before hardware bring-up. Also messy Vivado IP integration find a better way.

[decision] CPU is the supervisor, not the data mover. Pipeline runs autonomously once configured. CPU role: configuration, mode switching, error recovery, liveness monitoring via FRAME_COUNT.

[decision] Input side uses a 1024×32-bit FWFT FIFO instead of a full frame buffer. The accelerator begins processing pixels as they arrive. FIFO depth covers ~3 lines, enough for Sobel line buffer fill latency. BRAM B is kept as a full frame buffer for the compression accelerator.

[decision] 32-bit wide data path (4 pixels/word) throughout, matching Xilinx BRAM/FIFO primitive widths.

## Register Map (base: 0x6000_0000, sobel_size = 0x0C)

| Offset | Name          | Access | Description |
|--------|---------------|--------|-------------|
| `0x00` | `CTRL`        | R/W    | bit[0]: `start` - manual trigger, self-clears on start. bit[1]: `auto_start` - fire automatically when `frame_ready_i` is asserted. bit[2]: `algo_sel` - 0: pixel inversion (reference), 1: Sobel (student implementation) |
| `0x04` | `STATUS`      | RO     | bit[0]: `busy`. bit[1]: `done` - held until next CTRL write. bit[2]: `frame_ready` - latched from camera IF pulse; cleared on start. bit[3]: `error` |
| `0x08` | `FRAME_COUNT` | RO     | Completed frame counter, wraps at 2^32. CPU reads to verify pipeline liveness. |

## FIFO usage
The [Camera FIFO](https://github.com/olofk/fifo/tree/master) has a one cycle `empty` signal deassertion latency. Cycle0 write to FIFO, Cycle1 wait, Cycle2 data available at the output and empty flag goes low (see image below). 
![fifo_empty](figures/fifo_empty_wave.png)

Looking at the previous image you can see the `read_pointer` increments even though `rd_en` is not asserted. This is done by the `fifo_fwft_adapter.v` to prefetch for FWFT (First Word Fall Through). FWFT means the output for read is available on the same cycle as you set `rd_en`.

When `full` goes high the last write can still be performed on that cycle (See image below).
![fifo_full](figures/fifo_full_wave.png)

**IMPORTANT**: The FIFO has no overflow protection — if `wr_en` is asserted while `full` is high, the write pointer wraps and silently corrupts stored data. The writer must gate `wr_en` on `full`.

Run the command below if you want to analyse FIFO behaviour yourself.
```
./script/xrun_sim_sobel.sh
```

## FIFO include files for sim (Vivado)
1. C:\Users\dovyd\dtu_chip\original_win_test\Didactic-SoC\build\fpga\basys3\didactic-basys3.gen\sources_1\ip\camera_fifo_V1\sim\camera_fifo.v
2. C:\Users\dovyd\dtu_chip\original_win_test\Didactic-SoC\build\fpga\basys3\didactic-basys3.ip_user_files\ipstatic\hdl\fifo_generator_v13_2_rfs.v
3. C:\Users\dovyd\dtu_chip\original_win_test\Didactic-SoC\build\fpga\basys3\didactic-basys3.ip_user_files\ipstatic\simulation\fifo_generator_vlog_beh.v

/home/la_v9/mlab/MLAB_MCU_edu/fpga/IP/fifo_generator_v13_2_rfs.v

## TODO
1. (DONE) Add WB slave for edge-detection accelerator subsystem
2. (DONE) Implement frame buffer memories, CSRs, pixel inversion reference
3. (DONE) Replace Frame BRAM A with streaming FIFO; simplify FSM to single RUN state
4. (DONE) Develop a testbench that exercises the subsystem in isolation
5. (DONE) Develop full system testbench that exercises the subsystem
6. Write guide how to simulate, explain the system (what is in sobel_acc, FIFO caveats, sw for MCU)

## 2026-05-10
### Did
- `sobel_acc.sv`: Wishbone slave with IDLE/RUN/DONE FSM; reads from FWFT FIFO, writes 32-bit words to Frame BRAM B; `algo_sel` selects pixel inversion or Sobel stub; `auto_start` enables autonomous pipeline operation
- `bram.sv`: 32-bit wide, word-addressed (19,200 words, QVGA frame)
- `ibex_simple_system.sv`: `camera_fifo` and `u_frame_bram_b` instantiated and wired to `sobel_acc`; camera-side FIFO inputs stubbed to zero pending camera IF; `SOBEL_BASE_ADDR = 0x6000_0000` added to `project_defs.svh`

### Next
- Write isolated testbench for `sobel_acc` with behavioral FIFO stimulus
- Generate 320x240 images for the testbench.

## 2026-05-12

- Isolated testbench `sobel_acc_tb.sv` to run use `./script/xrun_sim_sobel.sh`

## 2026-05-14
### Did (FIFO Work)
- Xilinx generated FIFO with FWFT has 3 cycle latency for empty and full signals
- Chose to use an external FIFO from (https://github.com/olofk/fifo/tree/master).
- `sobel_acc_tb.sv` works.

### Next
- Usage guide for students.
- Compression accelerator.
