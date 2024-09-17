#!/bin/bash

# Check if an AUR helper (yay) is installed
if ! command -v yay &> /dev/null; then
    echo "AUR helper (yay) is not installed. Installing yay..."

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo "Git is required to install yay. Please install git first."
        exit 1
    fi

    # Install yay
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit 1
    makepkg -si --noconfirm
    cd .. || exit 1
    rm -rf yay

    echo "yay has been installed successfully."
else
    echo "AUR helper (yay) is already installed."
fi

# Check if snapper is installed
if ! command -v snapper &> /dev/null; then
    echo "Snapper is not installed."
    yay -S snapper snapper-rollback snap-pac grub-btrfs inotify-tools --needed --noconfirm
else
    echo "Snapper is installed."
fi

# Unmount /.snapshots if mounted
# Move to the above if exist file ssytem exits
if mountpoint -q /.snapshots; then
    umount /.snapshots || { echo "Failed to unmount /.snapshots"; }
else
    echo "/.snapshots is not mounted"
fi

# deleting old snapshots
cd / || { echo "Failed to change to root directory"; exit 1; }

if [ -d ".snapshots" ]; then
    rm -rf .snapshots || { echo "Failed to remove .snapshots"; exit 1; }
    echo ".snapshots folder has been removed"
else
    echo ".snapshots folder does not exist"
fi


# Creating Snapper config
sudo snapper -c root create-config /

# Updating the snapper config

# For ALLOW_GROUPS
sudo sed -i 's/^[[:space:]]*ALLOW_GROUPS[[:space:]]*=.*/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/root

sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_HOURLY[[:space:]]*=.*/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_DAILY[[:space:]]*=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_MONTHLY[[:space:]]*=.*/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_YEARLY[[:space:]]*=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_WEEKLY[[:space:]]*=.*/TIMELINE_LIMIT_WEEKLY="0"/' /etc/snapper/configs/root
sudo sed -i 's/^[[:space:]]*TIMELINE_LIMIT_QUARTERLY[[:space:]]*=.*/TIMELINE_LIMIT_QUARTERLY="0"/' /etc/snapper/configs/root



# changing BTRFS options
sudo btrfs subvol set-default 256 /

# enabling snapper service
sudo systemctl enable --now grub-btrfsd
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer


# Now moving script to the /etc/inicpio/hook
cd hooks || { echo "Failed to change to hooks directory"; exit 1; }
sudo mv switchsnaprotorw /etc/inicpio/hook
cd .. || { echo "Failed to change to root directory"; exit 1; }

# Now move the script to the /etc/inicpio/install
cd install || { echo "Failed to change to install directory"; exit 1; }
sudo mv switchsnaprotorw /etc/inicpio/install
cd .. || { echo "Failed to change to root directory"; exit 1; }

# Adding Hook to the grub
sed -i -E '/^[[:space:]]*HOOKS=/s/^[[:space:]]*HOOKS=/HOOKS=/; s/\(\s+/\(/; s/\s+/ /g; s/\s*\)/ switchsnaprotorw)/' /etc/mkinitcpio.conf


# Refreshing the initramfs
sudo mkinitcpio -P

# Renaming the folder for the sub-vol
sudo sed -i -E '/^[[:space:]]*subvol_snapshots[[:space:]]*=[[:space:]]*@snapshots[[:space:]]*$/s/^[[:space:]]*subvol_snapshots[[:space:]]*=[[:space:]]*@snapshots/subvol_snapshots = @.snapshots/' /etc/snapper-rollback.conf


# Identifying the disks and adding theme into the snapper config
# Telling the user which drivers does this have.

lsblk



