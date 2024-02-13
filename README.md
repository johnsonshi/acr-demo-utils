# ACR Demo Utils

Scripts for Azure Container Registry demonstrations.

## Prerequisites
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [Docker](https://www.docker.com/products/docker-desktop)
* [oras](https://oras.land/docs/installation)
* [curl](https://curl.se/)

# Usage

#### Populate ACR with sample images
```bash
curl -s https://raw.githubusercontent.com/johnsonshi/acr-demo-utils/main/populate-acr.sh | bash -s -- <acr-registry-name>
```

#### Build new image digests, retag existing tags to the new digests, and mark the existing tags' existing digests as EOL with Lifecycle Metadata
```bash
curl -s https://raw.githubusercontent.com/johnsonshi/acr-demo-utils/main/build-new-retag-and-mark-existing-as-eol.sh | bash -s -- <acr-registry-name>
```

#### Clean up ACR
```bash
curl -s https://raw.githubusercontent.com/johnsonshi/acr-demo-utils/main/clean-acr.sh | bash -s -- <acr-registry-name>
```
