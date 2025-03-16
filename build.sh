#!/bin/bash

srcDir="src"
buildDir="build"
controlFile="${srcDir}/DEBIAN/control"
build_itgmania_flag=true  # Default is true, i.e., build ITGmania

# Check for command-line arguments
for arg in "$@"; do
  case $arg in
    --no-itgmania)
      build_itgmania_flag=false  # Set to false if --no-itgmania is provided
      shift
      ;;
  esac
done

build_evhz() {
  echo "=============================="
  echo "Building evhz..."
  echo "=============================="
  
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

build_itgmania() {
  echo "=============================="
  echo "Building ITGmania..."
  echo "=============================="
  
  sudo extern/itgmania/Utils/build-release-linux.sh
  if [ $? -ne 0 ]; then
    echo "Error: Failed to build ITGmania."
    exit 1
  fi

  buildArchive="extern/itgmania/Build/release/ITGmania-0.9.0-Linux-no-songs.tar.gz"
  tempDir="/tmp/itgmania_build"

  if [ ! -f "$buildArchive" ]; then
    echo "Error: ITGmania build archive not found at $buildArchive"
    exit 1
  fi

  echo "Extracting ITGmania build archive..."
  mkdir -p "$tempDir"
  tar -xzf "$buildArchive" -C "$tempDir"

  # Ensure only the last 'itgmania' folder is copied to src/opt
  extractedDir="$tempDir/ITGmania-0.9.0-Linux-no-songs/itgmania"
  
  if [ ! -d "$extractedDir" ]; then
    echo "Error: Directory $extractedDir not found in the extracted archive."
    exit 1
  fi

  echo "Copying itgmania folder to: ${srcDir}/opt"
  cp -arv "$extractedDir" "${srcDir}/opt"
  rm -rf "$tempDir"
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
mkdir -p "$buildDir"

# Clear the build directory
echo "Clearing build directory: $buildDir"
rm -rfv "${buildDir:?}/"*

# Build extern/evhz and copy the output to src/opt/evhz
build_evhz

# Optionally build ITGmania and copy output to src/opt
if [ "$build_itgmania_flag" = true ]; then
  build_itgmania
fi

# Construct the output .deb file name
outputFile="${buildDir}/${packageName}-${packageVersion}-${packageArch}.deb"

echo "=============================="
echo "Building debian package..."
echo "=============================="

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