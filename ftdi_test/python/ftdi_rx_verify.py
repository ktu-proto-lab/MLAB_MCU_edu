#!/usr/bin/env python3
"""
ftdi_rx_verify.py
Receives the magic-word pattern stream from ftdi_test_top and verifies it.

Frame format (260 bytes, repeated continuously by the FPGA):
  [0xDE, 0xAD, 0xBE, 0xEF]  -- 4-byte magic header
  [0x00 .. 0xFF]             -- 256-byte incrementing payload

Usage:
  python ftdi_rx_verify.py [--frames N] [--device "USB <-> Serial Converter"]

Dependencies:
  pip install ftd2xx
  The FT2232H Channel A must be programmed to 245-sync-FIFO mode (FT_Prog).
"""

import sys
import time
import argparse

# ---------------------------------------------------------------------------
# Import the USB helper from the WangXuan95 repo already in deps/
# ---------------------------------------------------------------------------
sys.path.insert(0, "../../deps/ftdi_controller/python")
from USB_FTX232H_FT60X import USB_FTX232H_FT60X_sync245mode

# ---------------------------------------------------------------------------
# Frame parameters - must match ftdi_test_top.v
# ---------------------------------------------------------------------------
MAGIC   = bytes([0xDE, 0xAD, 0xBE, 0xEF])
PAYLOAD = bytes(range(256))
FRAME   = MAGIC + PAYLOAD          # 260 bytes
FRAME_LEN = len(FRAME)             # 260

MAGIC_LEN   = len(MAGIC)           # 4
PAYLOAD_LEN = len(PAYLOAD)         # 256


def find_magic(buf: bytearray) -> int:
    """Return the index of the first MAGIC occurrence in buf, or -1."""
    m = bytes(buf)
    idx = m.find(MAGIC)
    return idx


def verify_frames(data: bytes, frame_offset: int):
    """
    Verify as many complete frames as possible starting at frame_offset in data.
    Returns (frames_ok, frames_bad, next_offset).
    next_offset is the byte index in data where we left off.
    """
    frames_ok = 0
    frames_bad = 0
    i = frame_offset

    while i + FRAME_LEN <= len(data):
        chunk = data[i:i + FRAME_LEN]

        # Header check
        if chunk[:MAGIC_LEN] != MAGIC:
            # Lost sync - search for next header
            search = bytearray(data[i:])
            nxt = find_magic(search)
            if nxt == -1:
                # No more headers in the buffer
                return frames_ok, frames_bad, len(data)
            i += nxt
            frames_bad += 1
            continue

        # Payload check
        payload = chunk[MAGIC_LEN:]
        expected = PAYLOAD
        if payload != expected:
            mismatches = [(j, payload[j], expected[j])
                          for j in range(PAYLOAD_LEN) if payload[j] != expected[j]]
            print(f"  [FAIL] payload mismatch at frame boundary +{i}: "
                  f"{len(mismatches)} byte(s) wrong, first: "
                  f"offset={mismatches[0][0]} got=0x{mismatches[0][1]:02X} "
                  f"exp=0x{mismatches[0][2]:02X}")
            frames_bad += 1
        else:
            frames_ok += 1

        i += FRAME_LEN

    return frames_ok, frames_bad, i


def main():
    parser = argparse.ArgumentParser(description="FTDI TX pattern verifier")
    parser.add_argument("--frames",  type=int, default=100,
                        help="Number of frames to verify (default: 100)")
    parser.add_argument("--device",  type=str,
                        default="USB <-> Serial Converter",
                        help="FT2232H USB device name as seen by D2XX")
    args = parser.parse_args()

    target_bytes = args.frames * FRAME_LEN

    print(f"Opening FTDI device: '{args.device}'")
    usb = USB_FTX232H_FT60X_sync245mode(
        device_to_open_list=[("FTX232H", args.device)]
    )
    print(f"Device opened.  Expecting {args.frames} frames ({target_bytes} bytes).")
    print(f"Frame layout: {MAGIC_LEN}-byte magic + {PAYLOAD_LEN}-byte counter payload")
    print()

    # ------------------------------------------------------------------
    # Receive enough bytes to cover the requested frames plus one extra
    # frame for alignment slack.
    # ------------------------------------------------------------------
    recv_len  = target_bytes + FRAME_LEN
    t0        = time.time()
    raw       = usb.recv(recv_len)
    t1        = time.time()
    usb.close()

    elapsed  = t1 - t0
    rate_kBs = len(raw) / elapsed / 1e3 if elapsed > 0 else 0

    print(f"Received {len(raw)} bytes in {elapsed:.3f} s  ({rate_kBs:.0f} kB/s)")

    if len(raw) < MAGIC_LEN:
        print("ERROR: too few bytes received to locate magic header.")
        sys.exit(1)

    # ------------------------------------------------------------------
    # Find first frame boundary
    # ------------------------------------------------------------------
    buf = bytearray(raw)
    sync_idx = find_magic(buf)

    if sync_idx == -1:
        print("ERROR: magic header 0xDE 0xAD 0xBE 0xEF not found in received data.")
        print("  Check: FT_Prog mode, pin wiring, FPGA bitstream loaded.")
        sys.exit(1)

    if sync_idx > 0:
        print(f"  Sync: skipped {sync_idx} byte(s) before first header.")

    # ------------------------------------------------------------------
    # Verify frames
    # ------------------------------------------------------------------
    frames_ok, frames_bad, _ = verify_frames(raw, sync_idx)
    total = frames_ok + frames_bad

    print()
    print(f"Results: {frames_ok}/{total} frames OK,  {frames_bad} bad")

    if frames_bad == 0 and frames_ok >= args.frames:
        print("PASS - all frames verified correctly.")
        sys.exit(0)
    else:
        print("FAIL - see errors above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
