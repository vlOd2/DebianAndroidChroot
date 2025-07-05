#!/bin/bash
set -e

IMAGE_NAME="disk/disk.img"
IMAGE_MNT_DIR="disk/disk_mount"

# Ensure a test image has been created
if [[ ! -e "${IMAGE_NAME}" ]]; then
	echo "E: A test image is not present"
	exit 1
fi

# Mount image
echo "I: Mounting image"
mkdir -p "${IMAGE_MNT_DIR}"
sudo mount "${IMAGE_NAME}" "${IMAGE_MNT_DIR}"

# Copy scripts
echo "I: Copying scripts"
sudo cp -a "../android/"* "${IMAGE_MNT_DIR}/"

# Unmount image
echo "I: Unmounting image"
sudo umount "${IMAGE_MNT_DIR}"
rmdir "${IMAGE_MNT_DIR}"