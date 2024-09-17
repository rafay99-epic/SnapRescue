#!/bin/bash

# Function to install AUR helper binary
install_aur_helper() {
    local helper=$1
    local repo="https://aur.archlinux.org/${helper}.git"
    git clone "$repo"
    cd "${helper}" || exit 1
    makepkg -si --noconfirm
    cd .. || exit 1
    rm -rf "${helper}"
    echo "${helper} has been installed successfully."
}

echo "======================================================================================================"
echo "                                   Snapper Setup is Starting!"
echo "======================================================================================================"

echo "======================================================================================================"
echo "Checking for AUR Helper"
echo "======================================================================================================"
# Check if an AUR helper is installed
if command -v yay &> /dev/null; then
    aur_helper="yay"
elif command -v paru &> /dev/null; then
    aur_helper="paru"
else
    echo "No AUR helper found. Choose an AUR helper to install:"
    echo "1) yay-bin"
    echo "2) paru-bin"
    read -p "Enter your choice (1 or 2): " choice

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo "Git is required to install the AUR helper. Please install git first."
        exit 1
    fi

    case $choice in
        1) install_aur_helper "yay-bin"; aur_helper="yay" ;;
        2) install_aur_helper "paru-bin"; aur_helper="paru" ;;
        *) echo "Invalid choice. Exiting."; exit 1 ;;
    esac
fi

echo "Using AUR helper: $aur_helper"

# Check if snapper is installed
if ! command -v snapper &> /dev/null; then
    echo "Snapper is not installed."
    $aur_helper -S snapper snapper-rollback snap-pac grub-btrfs inotify-tools --needed --noconfirm
else
    echo "Snapper is installed."
fi


echo "======================================================================================================"
echo "Unmounting /.snapshots if mounted"
echo "======================================================================================================"

# Unmount /.snapshots if mounted
# Move to the above if exist file ssytem exits
if sudo mountpoint -q /.snapshots; then
    sudo umount /.snapshots || { echo "Failed to unmount /.snapshots"; }
else
    echo "/.snapshots is not mounted"
fi

echo "======================================================================================================"
echo "Deleting old snapshots"
echo "======================================================================================================"

# deleting old snapshots
cd / || { echo "Failed to change to root directory"; exit 1; }

if [ -d ".snapshots" ]; then
    sudo rm -rf .snapshots || { echo "Failed to remove .snapshots"; exit 1; }
    echo ".snapshots folder has been removed"
else
    echo ".snapshots folder does not exist"
fi


echo "======================================================================================================"
echo "Creating Snapper config"
echo "======================================================================================================"

# Creating Snapper config
sudo snapper -c root create-config /

# Updating the snapper config

echo "======================================================================================================"
echo "Setting up Snapper Config"
echo "======================================================================================================"

# For ALLOW_GROUPS
sudo sed -i 's/^[[:space:]]*ALLOW_GROUPS[[:space:]]*=.*/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/root

sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_HOURLY[[:space:]]*=.*/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_DAILY[[:space:]]*=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_MONTHLY[[:space:]]*=.*/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_YEARLY[[:space:]]*=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_WEEKLY[[:space:]]*=.*/TIMELINE_LIMIT_WEEKLY="0"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_QUARTERLY[[:space:]]*=.*/TIMELINE_LIMIT_QUARTERLY="0"/' /etc/snapper/configs/root

echo "======================================================================================================"
echo "Setting up BTRFS options"
echo "======================================================================================================"

# changing BTRFS options
sudo btrfs subvol set-default 256 /

echo "======================================================================================================"
echo "Enabling Grub-BTRFSd and Snapper Services"
echo "======================================================================================================"

# enabling snapper service
sudo systemctl enable --now grub-btrfsd
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer


echo "======================================================================================================"
echo "Moving Hooks and Install Scripts"
echo "======================================================================================================"

# Now moving script to the /etc/inicpio/hook
cd hooks || { echo "Failed to change to hooks directory"; exit 1; }
sudo mkdir -p /etc/inicpio/hook
sudo mv switchsnaprotorw /etc/inicpio/hook
cd .. || { echo "Failed to change to root directory"; exit 1; }

# Now move the script to the /etc/inicpio/install
cd install || { echo "Failed to change to install directory"; exit 1; }
sudo mkdir -p /etc/inicpio/install
sudo mv switchsnaprotorw /etc/inicpio/install
cd .. || { echo "Failed to change to root directory"; exit 1; }

echo "======================================================================================================"
echo "Adding Hook to the grub"
echo "======================================================================================================"

# Adding Hook to the grub
sudo sed -i -E '/^[[:space:]]*HOOKS=/s/^[[:space:]]*HOOKS=/HOOKS=/; s/\(\s+/\(/; s/\s+/ /g; s/\s*\)/ switchsnaprotorw)/' /etc/mkinitcpio.conf

echo "======================================================================================================"
echo "Refreshing the initramfs"
echo "======================================================================================================"

# Refreshing the initramfs
sudo mkinitcpio -P

echo "======================================================================================================"
echo "Renaming the folder for the sub-vol"
echo "======================================================================================================"

# Renaming the folder for the sub-vol
sudo sed -i -E '/^[[:space:]]*subvol_snapshots[[:space:]]*=[[:space:]]*@snapshots[[:space:]]*$/s/^[[:space:]]*subvol_snapshots[[:space:]]*=[[:space:]]*@snapshots/subvol_snapshots = @.snapshots/' /etc/snapper-rollback.conf



# Identifying the disks and adding theme into the snapper config
# Telling the user which drivers does this have.
echo "======================================================================================================"
echo "                             BTRFS Partition Detection for Snapper Setup"
echo "======================================================================================================"
echo "We have identified the following BTRFS partitions on your system:"
echo "Please select the partition that contains the root, home, and other necessary subvolumes."
echo "======================================================================================================"
echo "If you are unsure, simply press Enter, and the script will attempt to auto-detect the partition."
echo "However, please review the output carefully to avoid any potential issues."
echo "======================================================================================================"
echo "WARNING: Use this script at your own risk. Double-check your selections before proceeding."
echo "======================================================================================================"

# Show available partitions
lsblk

echo "======================================================================================================"


driver=$(lsblk -f | grep btrfs | awk '{print $1}' | sed 's/[^a-zA-Z0-9]//g')

# Check if a driver was found
if [ -z "$driver" ]; then
    echo "No BTRFS partition Detected. Please enter the driver name:"
    read -r driver
else
    # Prompt the user to confirm the driver
    echo "Found BTRFS partition: $driver. Press Enter to confirm or enter another driver name:"
    read -r input
    # If the user enters something, override the driver with the new input
    if [ -n "$input" ]; then
        driver="$input"
    fi
fi

echo "Selected driver: $driver"

echo "======================================================================================================"
echo "Entering the driver name into the snapper config"
echo "======================================================================================================"

# Enter the driver name into the snapper config
sudo echo "dev = /dev/$driver" >> /etc/snapper-rollback.conf



echo "======================================================================================================"
echo "                                   Snapper Setup is Complete!"
echo "======================================================================================================"
echo "All changes have been successfully applied. You can choose to reboot your system now or later."
echo "======================================================================================================"

# Prompt the user to choose whether to reboot now or later
read -p "Do you want to reboot now? (y/n): " choice || { echo "Invalid input. Exiting script."; exit 1; }

# Handle the user's choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting the system..."
    reboot
else
    echo "You have chosen to reboot later. Please make sure to reboot your system manually to apply the changes."
    echo "Exiting script."
    exit 0
fi

