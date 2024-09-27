#!/bin/bash

# Define the source directory and target directory
SOURCE_DIR="$(pwd)"
TARGET_DIR="/usr/local/bin"
TARGET_SCRIPT="$TARGET_DIR/fdd"
DOCKER_IMAGE_NAME="flutter-dev"

# Function to check for Docker
check_docker() {
  if ! command -v docker &>/dev/null; then
    echo "Error: Docker is not installed. Please install Docker to continue."
    exit 1
  fi
}

# Function to build the Docker image
build_docker_image() {
  echo "Building Docker image '$DOCKER_IMAGE_NAME' from Dockerfile..."
  docker build -t "$DOCKER_IMAGE_NAME" "$SOURCE_DIR" || {
    echo "Error: Failed to build Docker image."
    exit 1
  }
  echo "Docker image '$DOCKER_IMAGE_NAME' built successfully."
}

# Function to clone LazyVim config
clone_lazyvim_config() {
  read -p "Enter the GitHub URL for your LazyVim config: " LAZYVIM_REPO

  # Validate the URL
  if [[ ! "$LAZYVIM_REPO" =~ ^https://github\.com/ ]]; then
    echo "Error: Please enter a valid GitHub URL."
    exit 1
  fi

  # Clone the repository
  echo "Cloning LazyVim config from $LAZYVIM_REPO..."
  git clone "$LAZYVIM_REPO" lazyvim-config
}

# Check if the source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: Source directory $SOURCE_DIR does not exist."
  exit 1
fi

# Check for Docker
check_docker

# Clone LazyVim configuration
clone_lazyvim_config

# Check if the Docker image already exists
if docker images | grep -q "$DOCKER_IMAGE_NAME"; then
  echo "Docker image '$DOCKER_IMAGE_NAME' already exists. Rebuilding..."
else
  echo "Docker image '$DOCKER_IMAGE_NAME' does not exist. Building it now..."
fi

# Build the Docker image
build_docker_image

# Copy fdd.sh and other necessary files
echo "Installing fdd and associated files..."

# Create the target directory if it doesn't exist
sudo mkdir -p "$TARGET_DIR"

# Copy the main script
sudo cp "$SOURCE_DIR/fdd.sh" "$TARGET_SCRIPT"

# Copy the Dockerfile and LazyVim config directory
sudo cp "$SOURCE_DIR/Dockerfile" "$TARGET_DIR/Dockerfile"
sudo cp -r "$SOURCE_DIR/lazyvim-config" "$TARGET_DIR/lazyvim-config"

# Make the main script executable
sudo chmod +x "$TARGET_SCRIPT"

echo "fdd has been installed successfully! You can now use it from any terminal."
