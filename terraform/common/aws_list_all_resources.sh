#!/bin/bash
# This script retrieves all deployed AWS resources in all regions using AWS CLI
# contributors: Ross Ivanov

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it and try again."
    exit 1
fi
# Get the list of all AWS regions
regions=$(aws ec2 describe-regions --all-regions --query 'Regions[].RegionName' --output text)
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve AWS regions."
    exit 1
fi

echo $regions

# Loop through each region and list all resources
for region in ${regions[@]}:
do
    echo "Checking region: $region"
    # Use --no-tag-filters to list ALL resources discoverable by this API, even untagged ones.
    # Adjust --resource-type-filters if you only want specific types (e.g., "ec2:instance", "lambda:function")
    # Use 2>/dev/null to suppress "Could not connect to the endpoint URL" errors for opt-in regions you don't have access to.
    aws resourcegroupstaggingapi get-resources --no-tag-filters --region "$region" --output json 2>/dev/null
    echo "----------------------"
done