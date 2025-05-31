#!/bin/bash

# Set date and output file
DATESTAMP=$(date -u +"%Y-%m-%d")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOGDIR="$HOME/logs"

# Ensure log directory exists before using it
mkdir -p "$LOGDIR"

LOGFILE="${LOGDIR}/network_log_${DATESTAMP}.tsv"

# Header line (no spaces)
HEADER="Timestamp	Uplink_Mbps	Downlink_Mbps	Uplink_Responsiveness	Uplink_Latency_ms	Uplink_RPM	Downlink_Responsiveness	Downlink_Latency_ms	Downlink_RPM	Idle_Latency_ms	Idle_RPM"

# Write header if not present
if [ ! -f "$LOGFILE" ] || ! grep -q "^Timestamp" "$LOGFILE"; then
    echo -e "$HEADER" > "$LOGFILE"
fi

# Run test
OUTPUT=$(networkquality -s)

# Parse uplink/downlink
UPLINK=$(echo "$OUTPUT" | awk -F': ' '/^Uplink capacity/ {print $2}' | awk '{print $1}')
DOWNLINK=$(echo "$OUTPUT" | awk -F': ' '/^Downlink capacity/ {print $2}' | awk '{print $1}')

# Uplink responsiveness
UL_RESP_LINE=$(echo "$OUTPUT" | grep "^Uplink Responsiveness:")
UL_RESPONSIVENESS=$(echo "$UL_RESP_LINE" | sed -E 's/^Uplink Responsiveness: ([A-Za-z]+).*/\1/')
UL_LATENCY=$(echo "$UL_RESP_LINE" | grep -oE '[0-9.]+ (milliseconds|seconds)' | awk '{if ($2=="seconds") print $1*1000; else print $1}')
UL_RPM=$(echo "$UL_RESP_LINE" | grep -oE '[0-9]+ RPM' | grep -oE '[0-9]+')

# Downlink responsiveness
DL_RESP_LINE=$(echo "$OUTPUT" | grep "^Downlink Responsiveness:")
DL_RESPONSIVENESS=$(echo "$DL_RESP_LINE" | sed -E 's/^Downlink Responsiveness: ([A-Za-z]+).*/\1/')
DL_LATENCY=$(echo "$DL_RESP_LINE" | grep -oE '[0-9.]+ (milliseconds|seconds)' | awk '{if ($2=="seconds") print $1*1000; else print $1}')
DL_RPM=$(echo "$DL_RESP_LINE" | grep -oE '[0-9]+ RPM' | grep -oE '[0-9]+')

# Idle latency
IDLE_LINE=$(echo "$OUTPUT" | grep "^Idle Latency:")
IDLE_LATENCY=$(echo "$IDLE_LINE" | grep -oE '[0-9.]+ (milliseconds|seconds)' | awk '{if ($2=="seconds") print $1*1000; else print $1}')
IDLE_RPM=$(echo "$IDLE_LINE" | grep -oE '[0-9]+ RPM' | grep -oE '[0-9]+')

# Append data to the log
echo -e "${TIMESTAMP}\t${UPLINK}\t${DOWNLINK}\t${UL_RESPONSIVENESS}\t${UL_LATENCY}\t${UL_RPM}\t${DL_RESPONSIVENESS}\t${DL_LATENCY}\t${DL_RPM}\t${IDLE_LATENCY}\t${IDLE_RPM}" >> "$LOGFILE"

# Sanity check: column count
EXPECTED_COLS=11
ACTUAL_COLS=$(tail -n 1 "$LOGFILE" | awk -F'\t' '{print NF}')
HOST_USER="$(hostname) $(whoami)"

if [ "$ACTUAL_COLS" -ne "$EXPECTED_COLS" ]; then
    echo "$HOST_USER [ERROR ${TIMESTAMP}] Column count mismatch in $LOGFILE (date ${DATESTAMP}): expected $EXPECTED_COLS, got $ACTUAL_COLS" >&2
    echo "$HOST_USER [ERROR] Last line content: $(tail -n 1 "$LOGFILE")" >&2
fi
