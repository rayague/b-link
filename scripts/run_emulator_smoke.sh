#!/usr/bin/env bash
# Run emulator smoke test and capture stdout/stderr to a log file
# Usage: ./run_emulator_smoke.sh [with-functions]
set -euo pipefail
PROJECT=${PROJECT:-b-link-local}
TS=$(date +"%Y%m%d_%H%M%S")
LOGFILE="emulator_smoke_${TS}.log"

if [ "${1:-}" = "with-functions" ]; then
  CMD=(firebase emulators:exec "node tool/client_smoke_emulator_puppet.js" --only auth,firestore,functions --project "$PROJECT" --debug)
else
  CMD=(firebase emulators:exec "node tool/client_smoke_emulator_puppet.js" --only auth,firestore --project "$PROJECT" --debug)
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}" > "$LOGFILE" 2>&1 || true
echo "Exit code: $?" >> "$LOGFILE"
echo "Logs written to $LOGFILE"
echo "To share the result: cat $LOGFILE | sed -n '1,400p'"
