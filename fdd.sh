#!/bin/bash

HOST_DIR="$1"
if [ -z "$HOST_DIR" ]; then
  echo "Please provide the host directory path as an argument."
  exit 1
fi

# Check if a container using the flutter-dev image is already running
CONTAINER_ID=$(docker ps -q --filter ancestor=flutter-dev)

if [ -z "$CONTAINER_ID" ]; then
  # Check if a stopped container exists
  CONTAINER_ID=$(docker ps -aq --filter name=flutter-dev-container)

  if [ -n "$CONTAINER_ID" ]; then
    echo "Container exists but is not running. Starting it..."
    docker start flutter-dev-container
    docker exec -it flutter-dev-container bash
  else
    echo "No running container found. Starting a new one..."
    docker run -it \
      --name flutter-dev-container \
      --volume /tmp/.X11-unix:/tmp/.X11-unix \
      --env DISPLAY=$DISPLAY \
      --volume "$HOST_DIR":/home/flutter/projects \
      flutter-dev
  fi
else
  echo "Existing container found. Attaching to it..."
  docker exec -it $CONTAINER_ID bash
fi
