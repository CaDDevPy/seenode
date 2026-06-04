#!/usr/bin/env bash
# build/verify_critical_section.sh
# Simple verifier script: compile the project and print next steps.
# Does NOT flash by default.

set -euo pipefail

echo "[verify] Building project..."
cd build
make all

echo "\n[verify] Build finished. Next steps:"
echo "  - To flash the firmware to your ESP32 run: make flash"
echo "  - To monitor serial output run: make monitor"
echo "\nSuggested manual test sequence:" 
cat <<'EOF'
1) Flash the firmware: make flash
2) Open serial monitor: make monitor
   - Use serial port: /dev/ttyUSB0
   - Baud rate: 115200
3) Observe outputs from demo tasks and the test task:
   - Look for lines like "[DEMO] inside nested critical" and "[TEST] SR before:" and hex SR values
4) If you prefer automated validation, run tests/serial_validate.py from your host (requires pyserial):
   python3 tests/serial_validate.py --port /dev/ttyUSB0 --baud 115200 --timeout 15
EOF

exit 0
