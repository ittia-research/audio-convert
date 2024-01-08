#!/bin/bash

# Script to check if a Docker image 'audio-convert:latest' exists,
# and if not, attempt to restore it from 'audio-convert.tar.gz'.

# Docker image name
IMAGE_NAME="audio-convert"
IMAGE_TAG="latest"

# File name of the Docker image archive
IMAGE_ARCHIVE="audio-convert.tar.gz"

# Function to log errors
log_error() {
    echo "Error: $1" >&2
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if the Docker image exists
if docker image inspect "$IMAGE_NAME:$IMAGE_TAG" > /dev/null 2>&1; then
    echo "Docker image '$IMAGE_NAME:$IMAGE_TAG' exists."
else
    echo "Docker image '$IMAGE_NAME:$IMAGE_TAG' does not exist. Attempting to restore from archive."

    # Check if the archive file exists
    if [ -f "$IMAGE_ARCHIVE" ]; then
        # Attempt to load the image from the archive using gunzip and docker load
        if ! gunzip -c "$IMAGE_ARCHIVE" | docker load; then
            log_error "Failed to load Docker image from $IMAGE_ARCHIVE"
            exit 1
        else
            echo "Successfully restored Docker image '$IMAGE_NAME:$IMAGE_TAG' from $IMAGE_ARCHIVE."
        fi
    else
        log_error "The archive file $IMAGE_ARCHIVE does not exist."
        exit 1
    fi
fi
