#!/usr/bin/env python3
import sys
sys.path.insert(0, "../../deps/ftdi_controller/python")
from USB_FTX232H_FT60X import USB_FTX232H_FT60X_sync245mode

NBYTES = 4096

usb = USB_FTX232H_FT60X_sync245mode(
    device_to_open_list=[("FTX232H", "USB <-> Serial Converter A")]
)

data = usb.recv(NBYTES)
usb.close()

MAGIC = bytes([0xDE, 0xAD, 0xBE, 0xEF])

# Mark every byte position that belongs to a DE AD BE EF sequence so the
# hex dump can highlight it.  ANSI colour is only used when stdout is a tty.
HL = "\033[1;33m" if sys.stdout.isatty() else ""   # bright yellow
RST = "\033[0m" if sys.stdout.isatty() else ""

magic_bytes = set()
pos = data.find(MAGIC)
while pos >= 0:
    magic_bytes.update(range(pos, pos + 4))
    pos = data.find(MAGIC, pos + 1)

print(f"received {len(data)} bytes")
for i in range(0, len(data), 16):
    chunk = data[i:i+16]
    hex_part = " ".join(
        f"{HL}{b:02X}{RST}" if (i + k) in magic_bytes else f"{b:02X}"
        for k, b in enumerate(chunk)
    )
    print(f"  {i:04}  {hex_part}")

# -------------------------------------------------------------------------
# Verify the continuous payload stream.  Every byte should be exactly
# (previous + 1) mod 256, EXCEPT across the 4-byte magic header DE AD BE EF
# which interrupts the count once per 260-byte frame.  Report every gap.
# -------------------------------------------------------------------------

# find first header to align
start = data.find(MAGIC)
if start < 0:
    print("ERROR: no magic header found")
    sys.exit(1)

errors = 0
i = start
while i + 4 <= len(data):
    if data[i:i+4] != MAGIC:
        print(f"  [SYNC LOST] at offset 0x{i:04X}: "
              f"{' '.join(f'{b:02X}' for b in data[i:i+4])}")
        errors += 1
        nxt = data.find(MAGIC, i + 1)
        if nxt < 0:
            break
        i = nxt
        continue
    # header OK - verify the 256-byte payload that follows
    payload = data[i+4:i+4+256]
    for j, b in enumerate(payload):
        if b != j:
            print(f"  [BAD BYTE] frame@{i:04} payload[{j}] "
                  f"= 0x{b:02X}, expected 0x{j:02X}")
            errors += 1
            break
    i += 260

if errors == 0:
    print("PASS - all frames verified, no dropped or corrupted bytes")
else:
    print(f"FAIL - {errors} error(s) detected")

