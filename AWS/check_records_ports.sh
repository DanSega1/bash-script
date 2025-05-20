#!/bin/bash

RECORDS_FILE="route53_records.txt"
PORTS=(22 80 8080 9090 6379 27017)  # Add MongoDB default port
CHECK_LOG="port_check_results.txt"

# Clear previous log
> "$CHECK_LOG"

# Extract unique hostnames or IPs
grep -Eo '^[a-zA-Z0-9.-]+' "$RECORDS_FILE" | sort -u | while read -r host; do
    echo "Checking host: $host" | tee -a "$CHECK_LOG"
    
    for port in "${PORTS[@]}"; do
        timeout 2 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null \
            && echo "✅ $host:$port open" \
            || echo "❌ $host:$port closed"
    done | tee -a "$CHECK_LOG"
    
    echo "" >> "$CHECK_LOG"
done

echo "Port checks complete. Results saved to $CHECK_LOG"
