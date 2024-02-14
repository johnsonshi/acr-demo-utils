# ACR Demo Utils

Scripts for Azure Container Registry demonstrations.

## Prerequisites
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [Docker](https://www.docker.com/products/docker-desktop)
* [oras](https://oras.land/docs/installation)
* [curl](https://curl.se/)

# Usage

Set the environment variable `ACR_REGISTRY_NAME` to the name of the Azure Container Registry (without the `.azurecr.io` URL suffix) that you want to use for the demonstration.

```bash
export ACR_REGISTRY_NAME=myacrname
```

#### Populate ACR with sample images
```bash
curl -s https://raw.githubusercontent.com/johnsonshi/acr-demo-utils/main/populate-acr.sh | bash -s -- "$ACR_REGISTRY_NAME"
```

#### Build new image digests, retag existing tags to the new digests, and mark the existing tags' existing digests as EOL with Lifecycle Metadata
```bash
curl -s https://raw.githubusercontent.com/johnsonshi/acr-demo-utils/main/build-new-retag-and-mark-existing-as-eol.sh | bash -s -- "$ACR_REGISTRY_NAME"
```

#### Clean up ACR
```bash
curl -s https://raw.githubusercontent.com/johnsonshi/acr-demo-utils/main/clean-acr.sh | bash -s -- "$ACR_REGISTRY_NAME"
```
