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

## TODO
1. (DONE) Add WB slave for edge-detection accelerator subsystem
2. (DONE) Implement frame buffer memories, CSRs, pixel inversion reference
3. (DONE) Replace Frame BRAM A with streaming FIFO; simplify FSM to single RUN state
4. (DONE) Develop a testbench that exercises the subsystem in isolation
5. Develop full system testbench that exercises the subsystem

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
