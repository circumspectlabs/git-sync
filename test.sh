#!/bin/bash

# docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6 .

###
### Very basic test, mainly to identify linking issues and
### corrupted dependencies
###

DOCKER_IMAGE=${DOCKER_IMAGE:-"__not_defined__"}
if [ "$DOCKER_IMAGE" = "__not_defined__" ]; then
    echo "ERROR: DOCKER_IMAGE environment variable is not defined"
    exit 1
fi

set -e

# Check gosu linking
docker run --rm --entrypoint "" "${DOCKER_IMAGE}" gosu --version
docker run --rm --entrypoint "" "${DOCKER_IMAGE}" gosu --help

# Check git-sync linking
docker run --rm --entrypoint "" "${DOCKER_IMAGE}" git-sync --version
docker run --rm --entrypoint "" "${DOCKER_IMAGE}" git-sync --help

# Check entrypoint
docker run --rm "${DOCKER_IMAGE}" --version

# Try to pull something with git-sync (https)
docker run --rm "${DOCKER_IMAGE}" \
    --repo https://github.com/kubernetes/git-sync.git \
    --ref master \
    --root /tmp/git-sync \
    --one-time

# Try to pull something with git-sync (ssh)
docker run --rm "${DOCKER_IMAGE}" \
    --repo git@github.com:kubernetes/git-sync.git \
    --ref master \
    --root /tmp/git-sync \
    --one-time
