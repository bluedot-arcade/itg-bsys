#!/bin/bash

set -e  # Exit on error

# Check if the script is running as root or with sudo
if [[ $(id -u) -ne 0 ]]; then
    echo "This script requires root privileges. Please run with sudo."
    sudo "$0" "$@"
    exit 1
fi

show_help() {
    cat <<EOF
Usage: $0 [DISK] [OUTPUT_FILE]

Creates a compressed image of a disk using dd, copying only used sectors.

Arguments:
  DISK           Optional. The disk to image (e.g., /dev/sdb). If omitted, you'll be prompted.
  OUTPUT_FILE    Optional. Output file name. Defaults to DISKNAME.img.xz.

Options:
  -h, --help     Show this help message and exit.

Example:
  $0
  $0 /dev/sdb mybackup.img
EOF
}

usage_error() {
    echo "Error: $1"
    echo "Try '$0 --help' for more information."
    exit 1
}

disk="$1"
output="$2"

# Help option
if [[ "$disk" == "--help" || "$disk" == "-h" ]]; then
    show_help
    exit 0
fi

# If no disk provided, show all available
if [[ -z "$disk" ]]; then
    echo "Listing available disks..."

    DISKS=($(lsblk -dpno NAME | grep -E "/dev/sd|/dev/nvme"))
    if [[ ${#DISKS[@]} -eq 0 ]]; then
        usage_error "No disks found."
    fi

    for i in "${!DISKS[@]}"; do
        SIZE=$(lsblk -dn -o SIZE "${DISKS[$i]}")
        echo "$((i+1))) ${DISKS[$i]} - ${SIZE}"
    done

    read -rp "Select a disk to image (1-${#DISKS[@]}): " CHOICE

    if [[ ! "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#DISKS[@]} )); then
        echo "Invalid selection. Exiting."
        exit 1
    fi

    disk=${DISKS[$((CHOICE-1))]}
fi

# Confirm disk is valid
if [[ ! -b "$disk" ]]; then
    usage_error "$disk is not a valid block device."
fi

# Show disk info and ask for confirmation
echo "You selected: $disk"
echo "--------------------------------------------------"
sudo fdisk -l "$disk"

# Set default output name
if [[ -z "$output" ]]; then
    disk_name=$(basename "$disk")
    output="${disk_name}.img"
fi

# Get the last used sector
get_last_sector() {
    local device="$1"
    sudo fdisk -l "$device" 2>/dev/null | grep '^/dev' | tail -n 1 | awk '{print $3}'
}

# Get the sector size
get_sector_size() {
    local device="$1"
    sudo fdisk -l "$device" 2>/dev/null | grep -i "sector size" | awk '{print $4}'
}

last_sector=$(get_last_sector "$disk")
sector_size=$(get_sector_size "$disk")

if [[ -z "$last_sector" || -z "$sector_size" ]]; then
    usage_error "Failed to determine the last used sector or sector size on $disk."
fi

# Calculate total size in bytes
total_bytes=$((last_sector * sector_size))

# Convert bytes to human-readable format
human_readable_size=$(numfmt --to=iec --suffix=B "$total_bytes")

# Print the last sector, sector size, and size in human-readable format
echo ""
echo "Last sector: $last_sector"
echo "Sector size: $sector_size bytes"
echo "Total size: $human_readable_size"
echo "--------------------------------------------------"

# Confirm with user
read -rp "Proceed with imaging this disk? [Y/n]: " CONFIRM

CONFIRM=${CONFIRM:-Y}
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Perform imaging and compress
echo "Creating image of $disk..."
echo "Copying $last_sector sectors ($total_bytes bytes)..."
sudo dd if="$disk" bs=$sector_size count=$last_sector status=progress | xz > "${output}.xz"

echo "Image created and compressed as ${output}.xz"
