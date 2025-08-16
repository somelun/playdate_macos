#!/bin/bash

set -e

PROJECT_ROOT="."

BUILD_DIR="$PROJECT_ROOT/build-macos"

if [ -d "$BUILD_DIR" ]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"/*
else
    echo "Build directory does not exist. Creating it..."
    mkdir "$BUILD_DIR"
fi

echo "Running cmake..."
cmake -S . -B build-macos -G Xcode -DBUILD_TARGET=macos

echo "Done."
