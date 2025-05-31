#!/bin/bash

# Smoothed out via GTP-4o
# 2025-05-22

# Output log file
LOGFILE="network_log.tsv"

# Create header if file does not exist
if [ ! -f "$LOGFILE" ]; then
    echo -e "Timestamp\tUpload_Mbps\tDownload_Mbps\tUpload_Flows\tDownload_Flows\tUpload_Responsiveness\tUpload_RPM\tDownload_Responsiveness\tDownload_RPM" > "$LOGFILE"
fi

# Get UTC timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Run networkquality
OUTPUT=$(networkquality -s)

# Parse bandwidth and flows
UPLOAD=$(echo "$OUTPUT" | awk -F': ' '/^Upload capacity/ {print $2}' | awk '{print $1}')
DOWNLOAD=$(echo "$OUTPUT" | awk -F': ' '/^Download capacity/ {print $2}' | awk '{print $1}')
UFLOWS=$(echo "$OUTPUT" | awk -F': ' '/^Upload flows/ {print $2}' | awk '{print $1}')
DFLOWS=$(echo "$OUTPUT" | awk -F': ' '/^Download flows/ {print $2}' | awk '{print $1}')

# Parse Upload Responsiveness
U_RESP_LINE=$(echo "$OUTPUT" | grep "^Upload Responsiveness:")
UPLOAD_RESPONSIVENESS=$(echo "$U_RESP_LINE" | awk -F': ' '{print $2}' | sed -E 's/ \([0-9]+ RPM\)//' | sed 's/ /-/g')
UPLOAD_RPM=$(echo "$U_RESP_LINE" | awk -F'[()]' '{gsub(/[^0-9]/, "", $2); print $2}')

# Parse Download Responsiveness
D_RESP_LINE=$(echo "$OUTPUT" | grep "^Download Responsiveness:")
DOWNLOAD_RESPONSIVENESS=$(echo "$D_RESP_LINE" | awk -F': ' '{print $2}' | sed -E 's/ \([0-9]+ RPM\)//' | sed 's/ /-/g')
DOWNLOAD_RPM=$(echo "$D_RESP_LINE" | awk -F'[()]' '{gsub(/[^0-9]/, "", $2); print $2}')

# Fallbacks if fields are missing
[ -z "$UPLOAD_RESPONSIVENESS" ] && UPLOAD_RESPONSIVENESS="NA"
[ -z "$UPLOAD_RPM" ] && UPLOAD_RPM="NA"
[ -z "$DOWNLOAD_RESPONSIVENESS" ] && DOWNLOAD_RESPONSIVENESS="NA"
[ -z "$DOWNLOAD_RPM" ] && DOWNLOAD_RPM="NA"

# Append one clean tab-delimited line to the log
echo -e "${TIMESTAMP}\t${UPLOAD}\t${DOWNLOAD}\t${UFLOWS}\t${DFLOWS}\t${UPLOAD_RESPONSIVENESS}\t${UPLOAD_RPM}\t${DOWNLOAD_RESPONSIVENESS}\t${DOWNLOAD_RPM}" >> "$LOGFILE"

# Show last logged line
tail -n 1 "$LOGFILE"
