#!/usr/bin/env bash
# Week 1 — inspect a running job-api process via /proc and ss
# Usage: ./inspect-job-api.sh <pid>
#
# Reports:
#   - open DB connections (port 5432)
#   - in-flight HTTP connections (port 8080, ESTABLISHED)
#   - whether the process is shutting down
#
# All data comes from /proc/<pid>/ and ss — no application logs.

set -euo pipefail

PID="${1:?usage: $0 <pid>}"
PROC="/proc/$PID"

[[ -d "$PROC" ]] || { echo "ERROR: no process with PID $PID"; exit 1; }

# ---------------------------------------------------------------------------
# Helper: decode a hex port from /proc/<pid>/net/tcp
# The file uses little-endian hex IP and big-endian hex port.
# ---------------------------------------------------------------------------
hex_port() {
    printf "%d" "0x$1"
}

# /proc/<pid>/net/tcp columns (space-separated):
#   sl  local_address  rem_address  st  ...
# local_address format: HEXIP:HEXPORT  (IP in little-endian hex)
# st: 01=ESTABLISHED 06=TIME_WAIT 08=CLOSE_WAIT 0A=LISTEN

NET_TCP="$PROC/net/tcp"

echo "=== job-api PID $PID ==="
echo

# --- DB connections (remote port 5432 = 0x1538) ---
DB_PORT_HEX="1538"
DB_CONNS=$(awk -v port=":$DB_PORT_HEX" 'NR>1 && $3 ~ port && $4=="01"' "$NET_TCP" | wc -l | tr -d ' ')
echo "Open DB connections (port 5432, ESTABLISHED): $DB_CONNS"

# --- In-flight HTTP (local port 8080 = 0x1F90, state ESTABLISHED) ---
HTTP_PORT_HEX="1F90"
HTTP_CONNS=$(awk -v port=":$HTTP_PORT_HEX" 'NR>1 && $2 ~ port && $4=="01"' "$NET_TCP" | wc -l | tr -d ' ')
echo "In-flight HTTP connections (port 8080, ESTABLISHED): $HTTP_CONNS"

# --- Listening state: if port 8080 is no longer LISTEN, shutdown has started ---
LISTENING=$(awk -v port=":$HTTP_PORT_HEX" 'NR>1 && $2 ~ port && $4=="0A"' "$NET_TCP" | wc -l | tr -d ' ')
if [[ "$LISTENING" -eq 0 ]]; then
    echo "Shutdown state: SHUTTING DOWN (port 8080 no longer accepting connections)"
else
    echo "Shutdown state: RUNNING (accepting connections on port 8080)"
fi

echo
echo "=== Open file descriptors ==="
ls -la "$PROC/fd/" 2>/dev/null | tail -n +2 | wc -l | xargs -I{} echo "Total FDs: {}"

echo
echo "=== Signal mask (SigCgt) ==="
grep SigCgt "$PROC/status"
SIGCGT_HEX=$(grep SigCgt "$PROC/status" | awk '{print $2}')
echo "Caught signals (decimal mask): $((16#$SIGCGT_HEX))"
# Bit 14 = SIGTERM (signal 15, 0-indexed bit 14)
if (( (16#$SIGCGT_HEX >> 14) & 1 )); then
    echo "SIGTERM (15): CAUGHT by process"
else
    echo "SIGTERM (15): NOT caught — default action (terminate)"
fi
