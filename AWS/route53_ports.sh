#!/bin/bash

INPUT_CSV="route53_records_detailed.csv"
OUTPUT_CSV="route53_records_port_check.csv"
PORTS=(22 80 443 6379 27017 8080 9090 50051)

# Create header
header="zone_id,zone_name,record,type,dns_ok,ping_ok"
for port in "${PORTS[@]}"; do
    header="${header},port_${port}"
done
echo "$header" > "$OUTPUT_CSV"

# Function to check if a host is reachable
check_host() {
    local host="$1"
    local zone_id="$2"
    local zone_name="$3"
    local record_name="$4"
    local record_type="$5"
    
    # Clean up record name (remove trailing dot)
    clean_host=$(echo "$host" | sed 's/\.$//')
    
    # DNS check - try to resolve the host
    if nslookup "$clean_host" > /dev/null 2>&1; then
        dns_ok="✅"
    else
        dns_ok="❌"
    fi
    
    # Ping check
    if ping -c 1 -W 2 "$clean_host" > /dev/null 2>&1; then
        ping_ok="✅"
    else
        ping_ok="❌"
    fi
    
    # Start building the row
    row="\"$zone_id\",\"$zone_name\",\"$clean_host\",\"$record_type\",$dns_ok,$ping_ok"
    
    # Port checks
    for port in "${PORTS[@]}"; do
        if timeout 3 nc -z "$clean_host" "$port" 2>/dev/null; then
            port_status="✅"
        else
            port_status="❌"
        fi
        row="${row},${port_status}"
    done
    
    echo "$row" >> "$OUTPUT_CSV"
}

# Read CSV properly handling quoted fields
{
    read # Skip header
    while IFS= read -r line; do
        # Parse CSV line properly (basic CSV parsing)
        if [[ -z "$line" ]]; then
            continue
        fi
        
        # Extract fields using cut (assuming proper CSV format)
        zone_id=$(echo "$line" | cut -d',' -f1 | tr -d '"')
        zone_name=$(echo "$line" | cut -d',' -f2 | tr -d '"')
        record_name=$(echo "$line" | cut -d',' -f3 | tr -d '"')
        record_type=$(echo "$line" | cut -d',' -f4 | tr -d '"')
        value=$(echo "$line" | cut -d',' -f7 | tr -d '"')
        
        # Only test A and AAAA records
        if [[ "$record_type" == "A" || "$record_type" == "AAAA" ]]; then
            echo "Processing: $record_name ($record_type)"
            
            # For A records that point to ELB/ALB, we test the record name itself
            # For A records with direct IP addresses, we could test both
            check_host "$record_name" "$zone_id" "$zone_name" "$record_name" "$record_type"
            
            # If the value contains direct IP addresses (contains dots but not amazonaws.com)
            if [[ "$value" =~ ^[0-9] && "$value" != *"amazonaws.com"* ]]; then
                # Handle multiple IPs separated by semicolon
                IFS=';' read -ra IPS <<< "$value"
                for ip in "${IPS[@]}"; do
                    ip=$(echo "$ip" | xargs) # trim whitespace
                    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                        echo "  Also checking direct IP: $ip"
                        check_host "$ip" "$zone_id" "$zone_name" "$record_name (IP: $ip)" "$record_type"
                    fi
                done
            fi
        fi
    done
} < "$INPUT_CSV"

echo "✔️ Results saved to: $OUTPUT_CSV"
echo "📊 Summary:"
echo "- Total records processed: $(wc -l < "$OUTPUT_CSV")"
echo "- Records with successful DNS resolution: $(grep -c '✅' "$OUTPUT_CSV" | head -1)"
