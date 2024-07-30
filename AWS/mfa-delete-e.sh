# the script is used to enable MFA Delete for all buckets in the list
# to enable MFA Delete you have to use the root account
# the MFA token is work for 1 iteration at a time
# don't use the same token twice it will not work "Mfa header is invalid"

#!/bin/bash

# Read the list of bucket names from bucket-list.txt
buckets=$(cat "Buckets with MFA Delete disabled.txt")

# Prompt for the MFA device ARN
read -p "Enter the MFA device ARN: " mfa_arn

# Loop through each bucket and enable versioning and MFA Delete
for bucket in $buckets; do
  echo "Enabling versioning and MFA Delete for bucket: $bucket"

  # Prompt for the MFA token
  read -p "Enter the MFA token for bucket $bucket: " mfa_token

  # Enable versioning and MFA Delete, change root to your profile root user
  aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration Status=Enabled,MFADelete=Enabled --mfa "$mfa_arn $mfa_token" --profile root
done

echo "Versioning and MFA Delete enabled for all buckets."