#!/bin/bash

set -uo pipefail

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
ISO8601_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") # End-of-life date for artifacts
BASE_DIR=~/test-Dockerfiles
FOLDER_NAME="$BASE_DIR/Dockerfile-$CURRENT_DATETIME"
SUBFOLDERS=("fruit-apple" "fruit-banana" "fruit-orange" "meat-chicken" "meat-lamb")


# Ensure base directory exists
mkdir -p "$BASE_DIR"

# Create main Dockerfile folder
mkdir -p "$FOLDER_NAME"

# Initialize global Dockerfile counter
unique_dockerfile_counter=1

# Array to hold image digests
declare -A image_digests

# Create subfolders and Dockerfiles
for SUBFOLDER in "${SUBFOLDERS[@]}"; do
    mkdir "$FOLDER_NAME/$SUBFOLDER"
    for N in {1..5}; do
        unique_string_within_each_dockerfile="${CURRENT_DATETIME}-${unique_dockerfile_counter}"
        DOCKERFILE_NAME="$FOLDER_NAME/$SUBFOLDER/$SUBFOLDER-$N.Dockerfile"
        echo "FROM mcr.microsoft.com/cbl-mariner/base/python:3" > "$DOCKERFILE_NAME"
        echo "RUN echo $unique_string_within_each_dockerfile > file.txt" >> "$DOCKERFILE_NAME"
        let "unique_dockerfile_counter++"
    done
done

# Table header
echo "| Full Image Reference with Repo and Tag | Tag | Existing Digest | New Digest |" > image_digests_table.txt
echo "|----------------------------------------|-----|-----------------|------------|" >> image_digests_table.txt

# Build and push Docker images
for SUBFOLDER in "${SUBFOLDERS[@]}"; do
    for N in {1..5}; do
        DOCKERFILE_PATH="$FOLDER_NAME/$SUBFOLDER/$SUBFOLDER-$N.Dockerfile"
        TAG="1.${N}" # Tag includes "1" and the Dockerfile sequence number.
        REPO_NAME=$(echo "$SUBFOLDER" | sed 's/-/\//') # Replace dash with slash for repo name
        FULL_IMAGE_NAME="$ACR_REGISTRY_NAME.azurecr.io/$REPO_NAME:$TAG"

        # Check if the tag already exists
        EXISTING_DIGEST=$(az acr repository show-manifests --name "$ACR_REGISTRY_NAME" --repository "$REPO_NAME" --query "[?tags[0]=='$TAG'].digest" --output tsv)
        if [ ! -z "$EXISTING_DIGEST" ]; then
            echo "[*] Tag $TAG already exists with digest $EXISTING_DIGEST"
            image_digests["$FULL_IMAGE_NAME,existing"]=$EXISTING_DIGEST
        else
            echo "[*] Tag $TAG is new and does not exist yet."
        fi

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

        # Get new digest
        NEW_DIGEST=$(az acr repository show-manifests --name "$ACR_REGISTRY_NAME" --repository "$REPO_NAME" --query "[?tags[0]=='$TAG'].digest" --output tsv)
        image_digests["$FULL_IMAGE_NAME,new"]=$NEW_DIGEST

        # If tag already existed, attach artifact with end-of-life date
        if [ ! -z "$EXISTING_DIGEST" ]; then
            oras attach --artifact-type application/vnd.microsoft.artifact.lifecycle --annotation vnd.microsoft.artifact.lifecycle.end-of-life.date="$ISO8601_DATE" "$ACR_REGISTRY_NAME.azurecr.io/$REPO_NAME@${image_digests["$FULL_IMAGE_NAME,existing"]}"
        fi

        # Append to table
        if [ ! -z "$EXISTING_DIGEST" ]; then
            echo "| $FULL_IMAGE_NAME | $TAG | ${image_digests["$FULL_IMAGE_NAME,existing"]} | $NEW_DIGEST |" >> image_digests_table.txt
        else
            echo "| $FULL_IMAGE_NAME | $TAG | <no-existing-digest> | $NEW_DIGEST |" >> image_digests_table.txt
        fi
    done
done

echo "[*] Docker images have been built and pushed to $ACR_REGISTRY_NAME."

echo ""
echo "[*] Image digests and end-of-life artifacts have been recorded in image_digests_table.txt"
echo ""

echo ""
cat image_digests_table.txt
echo ""

echo ""
echo "[*] Run \"oras discover -o tree --artifact-type 'application/vnd.microsoft.artifact.lifecycle' $ACR_REGISTRY_NAME.azurecr.io/<repo-name>@<existing-digest>\" to view the Lifecycle Metadata digest for an existing image digest."
echo ""

echo ""
echo "[*] Run \"oras manifest fetch $ACR_REGISTRY_NAME.azurecr.io/<repo-name>@<lifecycle-metadata-digest>\" to view the Lifecycle Metadata JSON (including EOL date) for an existing image digest."
echo ""
