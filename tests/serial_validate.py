#!/usr/bin/env python3
"""
tests/serial_validate.py — reads the serial console and validates expected patterns
Requires: pyserial (pip3 install pyserial)
Usage:
  python3 tests/serial_validate.py --port /dev/ttyUSB0 --baud 115200 --timeout 15

This script looks for the test/demo output strings emitted by the firmware's
critical-section demo/test tasks and validates that they appear within the
specified timeout.
"""

import argparse
import re
import time
import sys

try:
    import serial
except Exception as e:
    print("ERROR: pyserial is required. Install with: pip3 install pyserial")
    sys.exit(2)

PATTERNS = [
    re.compile(rb"\[TEST\] SR before"),
    re.compile(rb"0x[0-9A-Fa-f]+"),                # SR hex or hex prints
    re.compile(rb"\[DEMO\] inside nested critical"),
    re.compile(rb"\[DEMO\] ISR-style demo start"),
    re.compile(rb"\[DEMO\] preserve-temporary demo"),
    re.compile(rb"\[TEST\] done"),
]


def read_and_validate(port, baud, timeout):
    try:
        s = serial.Serial(port, baud, timeout=1)
    except Exception as e:
        print(f"ERROR: could not open serial port {port}: {e}")
        return 2

    deadline = time.time() + timeout
    seen = set()
    print(f"Listening on {port} @ {baud} for up to {timeout}s...\n")
    while time.time() < deadline:
        try:
            line = s.readline()
        except Exception as e:
            print(f"ERROR reading serial: {e}")
            break
        if not line:
            continue
        # show the line for debugging
        try:
            print(line.decode('utf-8', errors='replace').rstrip())
        except Exception:
            print(repr(line))
        for i, p in enumerate(PATTERNS):
            if p.search(line):
                seen.add(i)
        if len(seen) == len(PATTERNS):
            print("\nOK: all expected patterns observed on serial.")
            s.close()
            return 0
    missing = [i for i in range(len(PATTERNS)) if i not in seen]
    print(f"\nFAIL: missing patterns indexes: {missing} — seen {sorted(list(seen))}")
    s.close()
    return 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Validate critical-section demo output over serial')
    parser.add_argument('--port', required=True, help='Serial port (e.g. /dev/ttyUSB0)')
    parser.add_argument('--baud', type=int, default=115200, help='Baud rate')
    parser.add_argument('--timeout', type=int, default=15, help='Timeout seconds')
    args = parser.parse_args()
    rc = read_and_validate(args.port, args.baud, args.timeout)
    sys.exit(rc)
