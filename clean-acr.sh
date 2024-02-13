#!/bin/bash

# Check if the ACR registry name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <acr-registry-name>"
    exit 1
fi

ACR_REGISTRY_NAME="$1"

# Login to Azure Container Registry
echo "Logging into ACR $ACR_REGISTRY_NAME..."
az acr login --name "$ACR_REGISTRY_NAME"
if [ $? -ne 0 ]; then
    echo "Failed to log in to ACR $ACR_REGISTRY_NAME. Please check the registry name and your permissions."
    exit 1
fi

# List all repositories in the ACR
repositories=$(az acr repository list --name $ACR_REGISTRY_NAME --output tsv)
if [ $? -ne 0 ]; then
    echo "Failed to list repositories in ACR $ACR_REGISTRY_NAME. Terminating script."
    exit 1
fi

# Loop through all repositories
for repo in $repositories; do
    echo "Processing repository: $repo"
    
    # List all digests in the repository
    digests=$(az acr repository show-manifests --name $ACR_REGISTRY_NAME --repository $repo --query "[].digest" -o tsv)
    if [ $? -ne 0 ]; then
        echo "Failed to list digests in repository $repo. Terminating script."
        exit 1
    fi
    
    # Loop through all digests and delete them
    for digest in $digests; do
        echo "Deleting digest $digest from repository $repo..."
        az acr repository delete --name $ACR_REGISTRY_NAME --image $repo@$digest --yes
        if [ $? -ne 0 ]; then
            echo "Failed to delete digest $digest from repository $repo. Terminating script."
            exit 1
        else
            echo "Successfully deleted digest $digest from repository $repo"
        fi
    done
done

echo "Completed deleting all digests in each repository within the ACR: $ACR_REGISTRY_NAME"
