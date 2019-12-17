#!/bin/sh -e

if [ $# -lt 2 ]; then
  echo "Usage: $0 CONTAINER_IMAGE_LOADER CONTAINER_IMAGE_NAME" >&2
  exit 1
fi

# check if we are running inside a Docker container, and skip this test if so.
if [ -z "$(ps -ef | grep [d]ocker)" ]; then
  echo "Already running inside Docker — on CircleCI."
  exit 0
else
  CONTAINER_IMAGE_LOADER="$1"
  CONTAINER_IMAGE_NAME="$2"

  ${CONTAINER_IMAGE_LOADER}
  docker run "${CONTAINER_IMAGE_NAME}"
fi

