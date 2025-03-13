#!/bin/bash

# TMH Release Script
# This script creates a release package for the TMH EdgeTX Telemetry script

# Set variables
VERSION=$(grep -o "Version: [0-9]\+\.[0-9]\+\.[0-9]\+" src/SCRIPTS/TELEMETRY/TMH.lua | cut -d' ' -f2)
RELEASE_DIR="release"
PACKAGE_NAME="TMH-v${VERSION}"

# Create release directory if it doesn't exist
mkdir -p "${RELEASE_DIR}"

# Create the release packages
echo "Creating release packages..."

# Create tar.gz archive directly from src directory with only .lua files
echo "Creating tar.gz package..."
(cd src && find . -name "*.lua" -print0 | tar -czf "../${RELEASE_DIR}/${PACKAGE_NAME}.tar.gz" --null -T -)
echo "Created ${RELEASE_DIR}/${PACKAGE_NAME}.tar.gz"

# Create zip archive directly from src directory
echo "Creating zip package..."
(cd src && find . -name "*.lua" -o -type d | zip -@ "../${RELEASE_DIR}/${PACKAGE_NAME}.zip")
echo "Created ${RELEASE_DIR}/${PACKAGE_NAME}.zip"

echo "Release v${VERSION} packages created successfully in ${RELEASE_DIR}/"
echo "Files created:"
echo "- ${PACKAGE_NAME}.tar.gz"
echo "- ${PACKAGE_NAME}.zip" 