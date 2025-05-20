#!/bin/bash

# Define the output file
output_file="s3_buckets_info.txt"

# Create a temporary file to store the bucket information
temp_file=$(mktemp)

# List all S3 buckets and get MFADelete status, region, and lifecycle configuration
for bucket in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do
    region=$(aws s3api get-bucket-location --bucket $bucket --query "LocationConstraint" --output text)
    mfa_delete=$(aws s3api get-bucket-versioning --bucket $bucket --query "MFADelete" --output text)
    lifecycle=$(aws s3api get-bucket-lifecycle-configuration --bucket $bucket --query "Rules" --output text 2>/dev/null)
    echo "$bucket,${region:-us-east-1},$mfa_delete,${lifecycle:-None}" >> $temp_file
done

# Call the Python script to format the output
python3 s3-table.py $temp_file $output_file

# Clean up the temporary file
rm $temp_file

# Print the output file content
cat $output_file