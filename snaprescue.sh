#!/bin/bash

# Exit on error, undefined variable, and pipe failure
set -eu
set -o pipefail

# Important Variables
# Find the Project Directory
Project_Dir=$(pwd)
Hook_Dir="/etc/initcpio/hooks"
Install_Dir="/etc/initcpio/install"


# Checking for BTRFS Partition
filesystem=$(findmnt -n -o FSTYPE /)

# Check if the file system is Btrfs
if [[ "$filesystem" == "btrfs" ]]; then
    echo "File system is Btrfs. No action required."
else
    echo "File system is not Btrfs. Exiting script."
    exit 1
fi


# Check for it's  an arch based sytem 
if grep -q "Arch Linux" /etc/os-release; then
    echo "System is Arch based. No action required."
else
    echo "System is not Arch based. Exiting script."
    exit 1
fi

echo "======================================================================================================"
echo "Installing necessary dependencies"
echo "======================================================================================================"

# List of required packages
required_packages=(snapper snap-pac grub-btrfs inotify-tools git)

# Check if all required packages are installed
missing_packages=()
for package in "${required_packages[@]}"; do
    if ! pacman -Qi "$package" &> /dev/null; then
        missing_packages+=("$package")
    fi
done

# Install missing packages if any
if [ ${#missing_packages[@]} -gt 0 ]; then
    echo "Installing missing packages: ${missing_packages[*]}"
    sudo pacman -S "${missing_packages[@]}" --needed --noconfirm || { echo "Failed to install packages. Exiting."; exit 1; }
else
    echo "All required packages are already installed."
fi

#  check for snapper-rollback package in the system
if pacman -Qi snapper-rollback &> /dev/null; then
    echo "snapper-rollback package is already installed."
else
    #Installling snapper-rollback package
    git clone https://aur.archlinux.org/snapper-rollback.git || { echo "Failed to clone snapper-rollback. Exiting."; exit 1; }
    cd snapper-rollback || exit 1
    makepkg -si --noconfirm || { echo "Failed to install snapper-rollback. Exiting."; exit 1; }
    cd .. || exit 1
    rm -rf snapper-rollback || exit 1
fi

echo "======================================================================================================"
echo "                                   Snapper Setup is Starting!"
echo "======================================================================================================"

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

echo "======================================================================================================"
echo "Taking backups of important files"
echo "======================================================================================================"

# take backup of /etc/mkinitcpio.conf and if it already exists then don't take it again
if [ -f "/etc/mkinitcpio.conf" ] && [ -f "/etc/mkinitcpio.conf.bak" ]; then
    echo "/etc/mkinitcpio.conf.bak already exists. Skipping backup."
else
    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak || { echo "Failed to backup /etc/mkinitcpio.conf, Exiting."; exit 1; }
fi

# take backup of /etc/snapper-rollback.conf and if it already exists then don't take it again
if [ -f "/etc/snapper-rollback.conf" ] && [ -f "/etc/snapper-rollback.conf.bak" ]; then
    echo "/etc/snapper-rollback.conf.bak already exists. Skipping backup."
else
    sudo cp /etc/snapper-rollback.conf /etc/snapper-rollback.conf.bak || { echo "Failed to backup /etc/snapper-rollback.conf, Exiting."; exit 1; }
fi

# take backup of /etc/snapper/configs/root and if it already exists then don't take it again
if [ -f "/etc/snapper/configs/root" ] && [ -f "/etc/snapper/configs/root.bak" ]; then
    echo "/etc/snapper/configs/root.bak already exists. Skipping backup."
else
    sudo cp /etc/snapper/configs/root /etc/snapper/configs/root.bak || { echo "Failed to backup /etc/snapper/configs/root, Exiting."; exit 1; }
fi

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
cd "$Project_Dir" || { echo "Failed to change to project directory"; exit 1; }
cd hooks || { echo "Failed to change to hooks directory"; exit 1; }
sudo mkdir -p "$Hook_Dir"
sudo cp -r switchsnaprotorw "$Hook_Dir"
cd .. || { echo "Failed to change to Project directory"; exit 1; }

cd "$Project_Dir"|| { echo "Failed to change to project directory"; exit 1; }
# Now move the script to the /etc/inicpio/install
cd install || { echo "Failed to change to install directory"; exit 1; }
sudo mkdir -p "$Install_Dir"
sudo cp -r switchsnaprotorw "$Install_Dir"
cd .. || { echo "Failed to change to Projecct directory"; exit 1; }

echo "======================================================================================================"
echo "Adding Hook to the grub"
echo "======================================================================================================"

# Adding Hook to the grub
sudo sed -i -E '/^[[:space:]]*HOOKS=/s/\(\s*(.*)\)/(\1 switchsnaprotorw)/' /etc/mkinitcpio.conf

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
echo "dev = /dev/$driver" | sudo tee -a /etc/snapper-rollback.conf



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

