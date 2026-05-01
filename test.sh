#!/bin/bash

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

# Check enptrypoint
docker run --rm "${DOCKER_IMAGE}" --version

# Try to pull something with git-sync
docker run --rm --entrypoint "" "${DOCKER_IMAGE}" git-sync \
    --repo https://github.com/kubernetes/git-sync.git \
    --branch master \
    --root /tmp/git-sync \
    --one-time
