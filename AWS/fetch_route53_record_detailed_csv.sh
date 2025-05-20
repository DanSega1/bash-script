#!/bin/bash

IDS_FILE="zone_ids.txt"
NAMES_FILE="zone_names.txt"
CSV_FILE="route53_records_detailed.csv"

# CSV header
echo "zone_id,zone_name,record_name,type,routing_policy,set_identifier,value,ttl,health_check,evaluate_target_health" > "$CSV_FILE"

# Read both files line by line in parallel
exec 3< "$IDS_FILE"
exec 4< "$NAMES_FILE"

while true; do
  IFS= read -r zone_id <&3 || break
  IFS= read -r zone_name <&4 || break

  echo "Fetching records for zone: $zone_id ($zone_name)"

  aws route53 list-resource-record-sets --hosted-zone-id "$zone_id" --output json | jq -r --arg zone_id "$zone_id" --arg zone_name "$zone_name" '
    .ResourceRecordSets[]
    | select(.Type != "NS" and .Type != "SOA")
    | {
        zone_id: $zone_id,
        zone_name: $zone_name,
        record_name: .Name,
        type: .Type,
        routing_policy: (.Region // .GeoLocation.ContinentCode // .GeoLocation.CountryCode // .GeoLocation.SubdivisionCode // "Simple"),
        set_identifier: (.SetIdentifier // ""),
        value: (
          if .ResourceRecords then
            (.ResourceRecords | map(.Value) | join("; "))
          elif .AliasTarget.DNSName then
            .AliasTarget.DNSName
          else
            ""
          end
        ),
        ttl: (.TTL // ""),
        health_check: (.HealthCheckId // ""),
        evaluate_target_health: (.AliasTarget.EvaluateTargetHealth // "")
      }
    | [.zone_id, .zone_name, .record_name, .type, .routing_policy, .set_identifier, .value, (.ttl|tostring), .health_check, (.evaluate_target_health|tostring)]
    | @csv
  ' >> "$CSV_FILE"
done

exec 3<&-
exec 4<&-

echo "Detailed records saved to $CSV_FILE"

