#!/bin/sh -e

. /common-script.sh

RC='\033[0m'        # Reset color
RED='\033[31m'      # Red
YELLOW='\033[33m'   # Yellow
CYAN='\033[36m'     # Cyan
GREEN='\033[32m'    # Green


mountUnmountSnapper(){
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

}

deletingOldSnapshots(){
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

}

creatingSnapperConfig(){
    echo "======================================================================================================"
    echo "Creating Snapper config"
    echo "======================================================================================================"

    # Creating Snapper config
    sudo snapper -c root create-config /
}

mkinitcpioHook(){
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

}

injectingHook(){

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

}

btrfsSubvol(){
    echo "======================================================================================================"
    echo "Setting up BTRFS options"
    echo "======================================================================================================"

    # changing BTRFS options
    sudo btrfs subvol set-default 256 /
}

SnapperServices(){
    echo "======================================================================================================"
    echo "Enabling Grub-BTRFSd and Snapper Services"
    echo "======================================================================================================"

    # enabling snapper service
    sudo systemctl enable --now grub-btrfsd
    sudo systemctl enable --now snapper-timeline.timer
    sudo systemctl enable --now snapper-cleanup.timer
}

MovingFileHook(){

    Project_Dir=$(pwd)
    Hook_Dir="/etc/initcpio/hooks"
    Install_Dir="/etc/initcpio/install"


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

}

grubHook(){
    echo "======================================================================================================"
    echo "Adding Hook to the grub"
    echo "======================================================================================================"

    # Adding Hook to the grub
    sudo sed -i -E '/^[[:space:]]*HOOKS=/s/\(\s*(.*)\)/(\1 switchsnaprotorw)/' /etc/mkinitcpio.conf
}

refreshMkinitcpio(){

    echo "======================================================================================================"
    echo "Refreshing the initramfs"
    echo "======================================================================================================"

    # Refreshing the initramfs
    sudo mkinitcpio -P

}

subVolRename(){
    echo "======================================================================================================"
    echo "Renaming the folder for the sub-vol"
    echo "======================================================================================================"

    # Renaming the folder for the sub-vol
    sudo sed -i -E '/^[[:space:]]*subvol_snapshots[[:space:]]*=[[:space:]]*@snapshots[[:space:]]*$/s/^[[:space:]]*subvol_snapshots[[:space:]]*=[[:space:]]*@snapshots/subvol_snapshots = @.snapshots/' /etc/snapper-rollback.conf

}

driveDection(){
    # Identifying the disks and adding theme into the snapper config
    # Telling the user which drivers does this have.

    printf "%s\n" "======================================================================================================"
    printf '%b%s%b\n' "$YELLOW" "🔍 BTRFS Partition Detection for Snapper Setup" "$RC"
    printf "%s\n" "======================================================================================================"
    printf '%b%s%b\n' "$CYAN" "We have detected the following BTRFS partitions on your system:" "$RC"
    printf "%s\n" "Please select the partition that contains your root, home, and other necessary subvolumes."
    printf "%s\n" "------------------------------------------------------------------------------------------------------"
    printf '%b%s%b\n' "$GREEN" "If you're unsure, simply press Enter, and the script will attempt to auto-detect the correct partition." "$RC"
    printf "%s\n" "However, carefully review the output to avoid any potential issues."
    printf "%s\n" "------------------------------------------------------------------------------------------------------"
    printf '%b%s%b\n' "$RED" "⚠️  WARNING: Use this script at your own risk!" "$RC"
    printf '%b%s%b\n' "$RED" "Ensure you double-check your selections before proceeding to prevent any unintended changes." "$RC"
    printf "%s\n" "======================================================================================================"

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


}

# Main Running Function
SnapperServices(){

# Snapper Configuration All Functions 
mountUnmountSnapper
deletingOldSnapshots
creatingSnapperConfig
mkinitcpioHook
injectingHook
btrfsSubvol
SnapperServices
MovingFileHook
grubHook
refreshMkinitcpio
subVolRename
driveDection
}


