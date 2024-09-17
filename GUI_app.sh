#!/bin/bash

# Exit on error, undefined variable, and pipe failure
set -eu
set -o pipefail

# Spinner function with command execution
run_with_spinner() {
    local message=$1
    shift
    local command=("$@")

    local -a spinner=('|' '/' '-' '\\')
    local pid
    "${command[@]}" &  # Run the command in the background
    pid=$!

    # Show the spinner
    while kill -0 "$pid" 2>/dev/null; do
        for i in "${spinner[@]}"; do
            echo -ne "\r$i $message"
            sleep 0.1
        done
    done

    wait "$pid"  # Wait for the command to complete

    if [[ $? -eq 0 ]]; then
        echo -ne "\r✅ $message\n"
    else
        echo -ne "\r❌ $message failed\n"
        exit 1
    fi
}

# TO DO Task
#  1. Add check for installing packages Done
#  2. make user packages all installed,  Done
#  8. Remove AUR helper Done
#  3. agar koi error ho then script exit Done 
#  Checking for Arch Linux only
#  4. check does the system file system btrfs  Done
#  Adding app check for snapper-rollback  

#  5. Place the files first and if there is any error then exit 
#  6. Files temper kar ne hai, tu existing files, ka backup. 
#  7. mkinitcpio file ka be backup. 

# Important Variables
# Find the Project Directory

Project_Dir=$(pwd)
Hook_Dir="/etc/initcpio/hooks"
Install_Dir="/etc/initcpio/install"

echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                       🚀  SnapRescue is Starting! 🚀                        ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

# Checking for BTRFS Partition
filesystem=$(findmnt -n -o FSTYPE /)

# Check if the file system is Btrfs
if [[ "$filesystem" == "btrfs" ]]; then
    echo "File system is Btrfs. No action required."
else
    echo "File system is not Btrfs. Exiting script."
    exit 1
fi

# Check if it's an Arch-based system 
if grep -q "Arch Linux" /etc/os-release; then
    echo "System is Arch based. No action required."
else
    echo "System is not Arch based. Exiting script."
    exit 1
fi

# Move File First

# mkinitcpio backup 
# snapper-rollback backup 


echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                       🚀  Package Check is Starting! 🚀                     ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"


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
    run_with_spinner "Installing missing packages: ${missing_packages[*]}" sudo pacman -S "${missing_packages[@]}" --needed --noconfirm
else
    echo "All required packages are already installed."
fi

# Check for snapper-rollback package in the system
if pacman -Qi snapper-rollback &> /dev/null; then
    echo "snapper-rollback package is already installed."
else
    # Installing snapper-rollback package
    run_with_spinner "Cloning snapper-rollback from AUR" git clone https://aur.archlinux.org/snapper-rollback.git
    cd snapper-rollback || exit 1
    run_with_spinner "Installing snapper-rollback" makepkg -si --noconfirm
    cd .. || exit 1
    rm -rf snapper-rollback || exit 1
fi


echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                       🚀  Mount Check is Starting! 🚀                       ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

# Unmount /.snapshots if mounted
if sudo mountpoint -q /.snapshots; then
    run_with_spinner "Unmounting /.snapshots" sudo umount /.snapshots
else
    echo "/.snapshots is not mounted"
fi

# Deleting old snapshots
cd / || { echo "Failed to change to root directory"; exit 1; }

if [ -d ".snapshots" ]; then
    run_with_spinner "Removing .snapshots folder" sudo rm -rf .snapshots
else
    echo ".snapshots folder does not exist"
fi

echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                       🚀  Snapper Config is Starting! 🚀                    ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

# Creating Snapper config
run_with_spinner "Creating Snapper config" sudo snapper -c root create-config /

# Updating the snapper config
run_with_spinner "Updating Snapper config" bash -c "sudo sed -i 's/^[[:space:]]*ALLOW_GROUPS[[:space:]]*=.*/ALLOW_GROUPS=\"wheel\"/' /etc/snapper/configs/root && \
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_HOURLY[[:space:]]*=.*/TIMELINE_LIMIT_HOURLY=\"5\"/' /etc/snapper/configs/root && \
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_DAILY[[:space:]]*=.*/TIMELINE_LIMIT_DAILY=\"7\"/' /etc/snapper/configs/root && \
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_MONTHLY[[:space:]]*=.*/TIMELINE_LIMIT_MONTHLY=\"0\"/' /etc/snapper/configs/root && \
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_YEARLY[[:space:]]*=.*/TIMELINE_LIMIT_YEARLY=\"0\"/' /etc/snapper/configs/root && \
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_WEEKLY[[:space:]]*=.*/TIMELINE_LIMIT_WEEKLY=\"0\"/' /etc/snapper/configs/root && \
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_QUARTERLY[[:space:]]*=.*/TIMELINE_LIMIT_QUARTERLY=\"0\"/' /etc/snapper/configs/root"



echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                       🚀  Btrfs Setup is Starting! 🚀                       ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"


# Changing BTRFS options
run_with_spinner "Setting default BTRFS subvolume" sudo btrfs subvol set-default 256 /

# Enabling snapper service
run_with_spinner "Enabling Grub-BTRFS and Snapper Services" bash -c "sudo systemctl enable --now grub-btrfsd && \
sudo systemctl enable --now snapper-timeline.timer && \
sudo systemctl enable --now snapper-cleanup.timer"


echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                    🚀  Kernel Level Hooks is Starting 🚀                    ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"


# Moving scripts to /etc/initcpio/hooks and /etc/initcpio/install
cd "$Project_Dir" || { echo "Failed to change to project directory"; exit 1; }
cd hooks || { echo "Failed to change to hooks directory"; exit 1; }
run_with_spinner "Moving hook scripts to $Hook_Dir" sudo mkdir -p "$Hook_Dir" && sudo cp -r switchsnaprotorw "$Hook_Dir"
cd .. || { echo "Failed to change to Project directory"; exit 1; }

cd "$Project_Dir" || { echo "Failed to change to project directory"; exit 1; }
cd install || { echo "Failed to change to install directory"; exit 1; }
run_with_spinner "Moving install scripts to $Install_Dir" sudo mkdir -p "$Install_Dir" && sudo cp -r switchsnaprotorw "$Install_Dir"
cd .. || { echo "Failed to change to Project directory"; exit 1; }


run_with_spinner "Adding Hook to mkinitcpio.conf" sudo sed -i -E '/^[[:space:]]*HOOKS=/s/\(\s*(.*)\)/(\1 switchsnaprotorw)/' /etc/mkinitcpio.conf


echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                       🚀  Building Kernel is Starting! 🚀                   ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"


# Refreshing the initramfs
run_with_spinner "Refreshing initramfs" sudo mkinitcpio -P


echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║              🚀  Renaming Mount File is Starting! 🚀                        ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"


run_with_spinner "Renaming the folder for the sub-volume" sudo sed -i -E '/^[[:space:]]*subvol_snapshots[[:space:]]*=[[:space:]]*@snapshots[[:space:]]*$/s/^[[:space:]]*subvol_snapshots[[:space:]]*=[[:space:]]*@snapshots/subvol_snapshots = @.snapshots/' /etc/snapper-rollback.conf




echo "╔═════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                                                     ║"
echo "║🚀 We have identified the following BTRFS partitions on your system    🚀                            ║"
echo "║🚀 Please select the partition that contains the root, home, and other necessary subvolumes. 🚀      ║"
echo "║🚀 If you are unsure, simply press Enter, and the script will attempt to auto-detect the partition.🚀║"
echo "║🚀 However, please review the output carefully to avoid any potential issues.🚀                      ║"
echo "║                                                                                                     ║"
echo "║🚀    WARNING: Use this script at your own risk. Double-check your selections before proceeding.🚀   ║"
echo "║                                                                                                     ║"
echo "║                                                                                                     ║"
echo "╚═════════════════════════════════════════════════════════════════════════════════════════════════════╝"


# Show available partitions
lsblk


# Detecting BTRFS driver
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

echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║              🚀  Enter Drive Name is Starting! 🚀                           ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

# Enter the driver name into the snapper config
run_with_spinner "Updating snapper config with driver name" bash -c "echo 'dev = /dev/$driver' | sudo tee -a /etc/snapper-rollback.conf"

echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║              🚀  Congratulations! 🚀                                        ║"
echo "║                                                                             ║"
echo "║  All changes have been successfully applied.                                ║"
echo "║  You can choose to reboot your system now or later.                         ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"




echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║              🚀  Snapper Restart is Starting! 🚀                            ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"

# Prompt the user to choose whether to reboot now or later
read -p "Do you want to reboot now? (y/n): " choice || { echo "Invalid input. Exiting script."; exit 1; }

# Handle the user's choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting the system..."
    run_with_spinner "Rebooting system" sudo reboot
else
    echo "You have chosen to reboot later. Please make sure to reboot your system manually to apply the changes."
    echo "Exiting script."
    exit 0
fi

echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║              🚀  Congratulations! 🚀                                        ║"
echo "║                                                                             ║"
echo "║                                                                             ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
