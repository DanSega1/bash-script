# this script will list all the buckets with MFA delete disabled

#!/bin/bash

# List all S3 buckets and store the names in an array
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Initialize an empty array to store buckets with MFA Delete disabled
buckets_with_mfa_delete_disabled=()

# Loop through each bucket and check the versioning configuration
for bucket in $buckets; do
  echo "Checking MFA Delete status for bucket: $bucket"

  # Get the versioning configuration for the bucket
  versioning_status=$(aws s3api get-bucket-versioning --bucket "$bucket" --query "MFADelete" --output text)

  # Check if MFA Delete is disabled
  if [ "$versioning_status" != "Enabled" ]; then
    buckets_with_mfa_delete_disabled+=("$bucket")
  fi
done

# Print the list of buckets with MFA Delete disabled
echo "Buckets with MFA Delete disabled:"
for bucket in "${buckets_with_mfa_delete_disabled[@]}"; do
  echo "$bucket"
done