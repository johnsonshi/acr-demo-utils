#!/bin/bash

# Check if the ACR registry name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <acr-registry-name>"
    exit 1
fi

ACR_REGISTRY_NAME=$1

# Login to Azure Container Registry
echo "[*] Logging into ACR $ACR_REGISTRY_NAME..."
az acr login --name "$ACR_REGISTRY_NAME"
if [ $? -ne 0 ]; then
    echo "[!] Failed to log in to ACR $ACR_REGISTRY_NAME. Please check the registry name and your permissions."
    exit 1
fi

CURRENT_DATETIME=$(date +"%Y%m%d%H%M%S")
BASE_DIR=~/test-Dockerfiles
FOLDER_NAME="$BASE_DIR/Dockerfile-$CURRENT_DATETIME"
SUBFOLDERS=("fruit-apple" "fruit-banana" "fruit-orange" "meat-chicken" "meat-lamb")

# Ensure base directory exists
mkdir -p "$BASE_DIR"

# Create main Dockerfile folder
mkdir -p "$FOLDER_NAME"

# Initialize global Dockerfile counter
unique_dockerfile_counter=1

# Create subfolders and Dockerfiles
for SUBFOLDER in "${SUBFOLDERS[@]}"; do
    mkdir "$FOLDER_NAME/$SUBFOLDER"
    for N in {1..5}; do
        unique_string_within_each_dockerfile="${CURRENT_DATETIME}-${counter}"
        # NOTE: DOCKERFILE_NAME should match the format as DOCKERFILE_PATH defined later.
        DOCKERFILE_NAME="$FOLDER_NAME/$SUBFOLDER/$SUBFOLDER-$N.Dockerfile"
        echo "FROM mcr.microsoft.com/cbl-mariner/base/python:3" > "$DOCKERFILE_NAME"
        echo "RUN echo $unique_string_within_each_dockerfile > file.txt" >> "$DOCKERFILE_NAME"
        let "unique_dockerfile_counter++"
    done
done

# Build and push Docker images
for SUBFOLDER in "${SUBFOLDERS[@]}"; do
    for N in {1..5}; do
        # NOTE: DOCKERFILE_PATH should match the format as DOCKERFILE_NAME defined earlier.
        DOCKERFILE_PATH="$FOLDER_NAME/$SUBFOLDER/$SUBFOLDER-$N.Dockerfile"
        TAG="1.${N}" # Tag includes "1" and the Dockerfile sequence number.
        REPO_NAME=$(echo "$SUBFOLDER" | sed 's/-/\//') # Replace dash with slash for repo name
        FULL_IMAGE_NAME="$ACR_REGISTRY_NAME.azurecr.io/$REPO_NAME:$TAG"

        # Navigate to subfolder for build context
        pushd "$FOLDER_NAME/$SUBFOLDER" > /dev/null
        docker build -t "$FULL_IMAGE_NAME" -f "$DOCKERFILE_PATH" .
        if [ $? -ne 0 ]; then
            echo "[!] Docker build failed for $FULL_IMAGE_NAME."
        fi
        docker push "$FULL_IMAGE_NAME"
        if [ $? -ne 0 ]; then
            echo "[!] Docker push failed for $FULL_IMAGE_NAME."
        fi
        popd > /dev/null # Return to previous directory
    done
done

echo "[*] Docker images have been built and pushed to $ACR_REGISTRY_NAME."
