#!/bin/bash

HOST_DIR="$1"
if [ -z "$HOST_DIR" ]; then
  echo "Please provide the host directory path as an argument."
  exit 1
fi

# Check if a container using the flutter-dev image is already running
CONTAINER_ID=$(docker ps -q --filter ancestor=flutter-dev)

# If a container is running, stop and remove it
if [ -n "$CONTAINER_ID" ]; then
  echo "Stopping and removing existing container..."
  docker stop $CONTAINER_ID
  docker rm $CONTAINER_ID
fi

# Check for any stopped container with the same name
STOPPED_CONTAINER_ID=$(docker ps -aq --filter name=flutter-dev-container)
if [ -n "$STOPPED_CONTAINER_ID" ]; then
  echo "Removing stopped container..."
  docker rm $STOPPED_CONTAINER_ID
fi

echo "Starting a new container..."
docker run -it \
  --name flutter-dev-container \
  --volume /tmp/.X11-unix:/tmp/.X11-unix \
  --env DISPLAY=$DISPLAY \
  --volume "$HOST_DIR":/home/flutter/projects \
  flutter-dev
