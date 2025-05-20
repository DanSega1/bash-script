#!/bin/bash

# Output files
NAMES_FILE="zone_names.txt"
IDS_FILE="zone_ids.txt"

# Clear previous files if they exist
> "$NAMES_FILE"
> "$IDS_FILE"

# Fetch hosted zones using AWS CLI
aws route53 list-hosted-zones --output json | \
    jq -r '.HostedZones[] | [.Name, .Id] | @tsv' | while IFS=$'\t' read -r name id; do
    # Clean up ID (strip the '/hostedzone/' prefix)
    zone_id="${id##*/}"

    # Write name and ID to their respective files
    echo "$name" >> "$NAMES_FILE"
    echo "$zone_id" >> "$IDS_FILE"
done

echo "Route 53 zones fetched successfully."
echo "Names saved to: $NAMES_FILE"
echo "IDs saved to: $IDS_FILE"
