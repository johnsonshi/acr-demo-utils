#!/bin/bash

set -uo pipefail

# Check if the ACR registry name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <acr-registry-name>"
    exit 1
fi

ACR_REGISTRY_NAME="$1"

# Login to Azure Container Registry
echo "[*] Logging into ACR $ACR_REGISTRY_NAME..."
az acr login --name "$ACR_REGISTRY_NAME"
if [ $? -ne 0 ]; then
    echo "[!] Failed to log in to ACR $ACR_REGISTRY_NAME. Please check the registry name and your permissions."
    exit 1
fi

# List all repositories in the ACR
repositories=$(az acr repository list --name $ACR_REGISTRY_NAME --output tsv)
if [ $? -ne 0 ]; then
    echo "[!] Failed to list repositories in ACR $ACR_REGISTRY_NAME."
    exit 1
fi

# Loop through all repositories
for repo in $repositories; do
    echo "[*] Deleting repository: $repo"

    az acr repository delete --name $ACR_REGISTRY_NAME --repository $repo --yes
done
