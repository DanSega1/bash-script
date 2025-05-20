#!/bin/bash

INPUT_CSV="route53_records_detailed.csv"
OUTPUT_CSV="route53_records_port_check.csv"
PORTS=(22 80 443 6379 27017 8080 9090 50051)

# Check headers
{
  echo -n "zone_id,zone_name,record,dns_ok,ping_ok"
  for port in "${PORTS[@]}"; do
    echo -n ",port_$port"
  done
  echo
} > "$OUTPUT_CSV"

# Skip header
tail -n +2 "$INPUT_CSV" | while IFS=',' read -r zone_id zone_name record_name _; do
  # Clean up record
  host=$(echo "$record_name" | sed 's/\.$//')

  # DNS check
  host "$host" > /dev/null 2>&1 && dns_ok="v" || dns_ok="X"

  # Ping check
  ping -c 1 -W 1 "$host" > /dev/null 2>&1 && ping_ok="✅" || ping_ok="❌"

  # Start CSV row
  row="$zone_id,$zone_name,$host,$dns_ok,$ping_ok"

  # Port checks
  for port in "${PORTS[@]}"; do
    nc -z -w 2 "$host" "$port" &>/dev/null && port_status="✅" || port_status="❌"
    row+=",$port_status"
  done

  echo "$row" >> "$OUTPUT_CSV"
done

echo "✔️ Results saved to: $OUTPUT_CSV"

