#!/bin/bash

# Get list of block devices and mount points
lsblk_output=$(lsblk -o NAME,MOUNTPOINT)

# Function to find the driver by mount point
find_driver() {
    local mount_point=$1
    local driver=$(echo "$lsblk_output" | grep "$mount_point" | awk '{print $1}')
    
    if [[ -z "$driver" ]]; then
        # Ask user for input if the mount point is not found
        echo "No $mount_point found. Please enter the device name for $mount_point (e.g., sda1, nvme0n1p1):"
        read driver
    fi
    
    echo "$driver"
}

# Find drivers for /boot, /root, and /home
boot_driver=$(find_driver "/boot")
root_driver=$(find_driver "/")
home_driver=$(find_driver "/home")

# Store all drivers into a single variable
all_drivers="$boot_driver $root_driver $home_driver"

# Output the drivers
echo "Drivers: $all_drivers"
