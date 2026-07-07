#!/usr/bin/env python3
"""
  Contributors:
    * Dovydas Liutkus
  Description:
    * PC-side receiver + verifier for ftdi_test_top.v frame stream
    * Frame = magic header DE AD BE EF + 256-byte incrementing payload
    *
    * Discards an initial chunk (stale bytes from before the FPGA was
    * reprogrammed may sit in the chip's TX buffer), then captures NBYTES,
    * aligns on the magic header and verifies every payload byte.
    * Reports every resync/bad byte with its offset, plus totals and
    * throughput.
    *
    * Usage:
    *   python ftdi_rx_verify.py [nbytes]      - verify (default 4 MiB)
    *   python ftdi_rx_verify.py --dump [n]    - hexdump n bytes (default 512)
    *
    * NOTE: unbind ftdi_sio from the FT2232H interface first, e.g.
    *   echo -n '3-6:1.0' | sudo tee /sys/bus/usb/drivers/ftdi_sio/unbind
"""

import sys
import time

sys.path.insert(0, "../../deps/ftdi_controller/python")
from USB_FTX232H_FT60X import USB_FTX232H_FT60X_sync245mode

MAGIC     = bytes([0xDE, 0xAD, 0xBE, 0xEF])
FRAME_LEN = 4 + 256
DISCARD   = 65536           # flush stale pre-capture bytes


def hexdump(data):
    for i in range(0, len(data), 16):
        chunk = data[i:i+16]
        hex_part = " ".join(f"{b:02X}" for b in chunk)
        print(f"  {i:04X}  {hex_part}")


def verify(data):
    start = data.find(MAGIC)
    if start < 0:
        print("ERROR: no magic header found in capture")
        return 1

    frames_ok  = 0
    resyncs    = 0
    bad_bytes  = 0
    i = start
    while i + FRAME_LEN <= len(data):
        if data[i:i+4] != MAGIC:
            resyncs += 1
            ctx = " ".join(f"{b:02X}" for b in data[i:i+8])
            print(f"  [RESYNC] offset 0x{i:06X}: expected header, got {ctx}")
            nxt = data.find(MAGIC, i + 1)
            if nxt < 0:
                break
            i = nxt
            continue
        payload = data[i+4:i+4+256]
        frame_bad = False
        for j, b in enumerate(payload):
            if b != j:
                bad_bytes += 1
                frame_bad = True
                print(f"  [BAD BYTE] frame@0x{i:06X} payload[{j}] "
                      f"= 0x{b:02X}, expected 0x{j:02X}")
                break                     # realign via header search
        if frame_bad:
            nxt = data.find(MAGIC, i + 4)
            if nxt < 0:
                break
            i = nxt
        else:
            frames_ok += 1
            i += FRAME_LEN

    total_errors = resyncs + bad_bytes
    print(f"\nframes verified : {frames_ok}")
    print(f"resyncs         : {resyncs}")
    print(f"bad bytes       : {bad_bytes}")
    if total_errors == 0:
        print("PASS - no dropped or corrupted bytes")
    else:
        print(f"FAIL - {total_errors} error(s) in "
              f"{frames_ok + resyncs + bad_bytes} frames")
    return 0 if total_errors == 0 else 1


if __name__ == "__main__":
    args = sys.argv[1:]
    dump_mode = "--dump" in args
    nums = [a for a in args if not a.startswith("-")]
    if dump_mode:
        nbytes = int(nums[0]) if nums else 512
    else:
        nbytes = int(nums[0]) if nums else 4 * 1024 * 1024

    usb = USB_FTX232H_FT60X_sync245mode(
        device_to_open_list=[("FTX232H", "USB <-> Serial Converter A")]
    )

    usb.recv(DISCARD)                    # flush stale buffer contents

    t0 = time.time()
    data = usb.recv(nbytes)
    dt = time.time() - t0
    usb.close()

    rate = len(data) / dt / 1e6 if dt > 0 else 0.0
    print(f"received {len(data)} bytes in {dt:.2f} s ({rate:.2f} MB/s)")

    if len(data) < nbytes:
        print(f"WARNING: short read ({len(data)}/{nbytes}) - "
              "stream slower than expected or timeout too small")

    if dump_mode:
        hexdump(data)
    else:
        sys.exit(verify(data))
