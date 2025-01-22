#!/bin/bash

controlFile="src/DEBIAN/control"

# Verify the control file exists
if [ ! -f "$controlFile" ]; then
  echo "Error: Control file not found at $controlFile"
  exit 1
fi

# Extract package details from the control file
packageName=$(grep '^Package:' "$controlFile" | awk '{print $2}')
packageVersion=$(grep '^Version:' "$controlFile" | awk '{print $2}')
packageArch=$(grep '^Architecture:' "$controlFile" | awk '{print $2}')

# Validate extracted details
if [ -z "$packageName" ] || [ -z "$packageVersion" ] || [ -z "$packageArch" ]; then
  echo "Error: Failed to extract package details from control file."
  exit 1
fi

# Create build directory
mkdir -p "build"

# Construct the output .deb file name
outputFile="build/${packageName}-${packageVersion}-${packageArch}.deb"

# Build the .deb package
dpkg-deb --build "$srcFolder" "$outputFile"

if [ $? -eq 0 ]; then
  echo "Package created successfully: $outputFile"
else
  echo "Error: Failed to create the package."
  exit 1
fi