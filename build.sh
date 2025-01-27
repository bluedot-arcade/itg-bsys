#!/bin/bash

srcDir="src"
buildDir="build"
controlFile="${srcDir}/DEBIAN/control"

build_evhz() {
  echo "=============================="
  echo "Building evhz..."
  echo "=============================="
  
  # Build evhz
  make -C extern/evhz
  if [ $? -ne 0 ]; then
    echo "Error: Failed to build evhz."
    exit 1
  fi

  if [ ! -d "${srcDir}/opt/evhz" ]; then
    echo "Creating directory: ${srcDir}/opt/evhz"
    mkdir -p "${srcDir}/opt/evhz"
  else 
    echo "Directory already exists: ${srcDir}/opt/evhz"
    echo "Clearing directory: ${srcDir}/opt/evhz"
    rm -rfv "${srcDir}/opt/evhz}"/*
  fi 

  echo "Copying files to: ${srcDir}/opt/evhz"
  cp -arv extern/evhz/build/* "${srcDir}/opt/evhz"
  echo ""
}

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

# Build extern/evhz and copy the output to src/opt/evhz
build_evhz

# Construct the output .deb file name
outputFile="${buildDir}/${packageName}-${packageVersion}-${packageArch}.deb"

echo "=============================="
echo "Building debian package..."
echo "=============================="

# Build the .deb package
dpkg-deb --build "$srcDir" "$outputFile"

if [ $? -eq 0 ]; then
  echo ""
  echo -e "\033[0;32m[SUCCESS]\033[0m"
  echo "Package created successfully: $outputFile"
  echo ""
else
  echo ""
  echo -e "\033[0;31m[FAILURE]\033[0m"
  echo "Error: Failed to create the package."
  echo ""
  exit 1
fi