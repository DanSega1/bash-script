#!/bin/bash

IDS_FILE="zone_ids.txt"
CSV_FILE="route53_records.csv"

# CSV header
echo "zone_id,name,type,value" > "$CSV_FILE"

# Loop through hosted zone IDs
while read -r zone_id; do
    echo "Fetching records for zone: $zone_id"
    
    aws route53 list-resource-record-sets \
        --hosted-zone-id "$zone_id" \
        --output json | jq -r \
        --arg zone_id "$zone_id" '
        .ResourceRecordSets[]
        | select(.Type != "NS" and .Type != "SOA")
        | .ResourceRecords[]
        | [$zone_id, .Name, .Type, .Value] 
        | @csv' >> "$CSV_FILE"
done < "$IDS_FILE"

echo "Records saved to $CSV_FILE"
