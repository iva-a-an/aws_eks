#!/bin/bash
# This script retrieves the kubeconfig from aws deployment using data from terrorm output. 
# contributors: Ross Ivanov

# check if jq, terraform, aws and kubectl are installed
for tool in jq terraform aws kubectl; do
    if ! command -v $tool &> /dev/null; then
        echo "Error: $tool is not installed. Please install it and try again."
        exit 1
    fi
done


# Read the Terraform output
terraform_output=$(terraform output -json)
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve Terraform output."
    exit 1
fi

# Extract the EKS cluster name and region from the Terraform output
eks_cluster_name=$(echo $terraform_output | jq -r '.eks_cluster_name.value')
aws_region=$(echo $terraform_output | jq -r '.eks_cluster_region.value')
if [ -z "$eks_cluster_name" ] || [ -z "$aws_region" ]; then
    echo "Error: eks_cluster_name or eks_cluster_region is not set in Terraform output."
    exit 1
fi

echo "Retrieving kubeconfig for EKS cluster: $eks_cluster_name in region: $aws_region"
# Update kubeconfig using AWS CLI
aws eks update-kubeconfig --name "$eks_cluster_name" --region "$aws_region"
if [ $? -ne 0 ]; then
    echo "Error: Failed to update kubeconfig for EKS cluster."
    exit 1
fi
echo "Kubeconfig updated successfully for EKS cluster: $eks_cluster_name"
# Verify the kubeconfig by getting the cluster info
kubectl cluster-info
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve cluster info. Please check your kubeconfig."
    exit 1
fi
