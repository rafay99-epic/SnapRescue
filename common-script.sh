#!/bin/sh -e

# Color codes for styling
RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'

command_exists() {
    command -v "$1" >/dev/null 2>&1
}


# Installing Essential Packages and passign everthing to this function
checkEscalationTool() {
    ## Check for escalation tools.
    if [ -z "$ESCALATION_TOOL_CHECKED" ]; then
        ESCALATION_TOOLS='sudo doas'
        for tool in ${ESCALATION_TOOLS}; do
            if command_exists "${tool}"; then
                ESCALATION_TOOL=${tool}
                printf "%b\n" "${CYAN}Using ${tool} for privilege escalation${RC}"
                ESCALATION_TOOL_CHECKED=true
                return 0
            fi
        done

        printf "%b\n" "${RED}Can't find a supported escalation tool${RC}"
        exit 1
    fi
}
# function ofr checking requirements packages
checkCommandRequirements() {
    ## Check for requirements.
    REQUIREMENTS=$1
    for req in ${REQUIREMENTS}; do
        if ! command_exists "${req}"; then
            printf "%b\n" "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
            exit 1
        fi
    done
}
# checking for AUR helper
checkAURHelper() {
    ## Check & Install AUR helper
    if [ "$PACKAGER" = "pacman" ]; then
        if [ -z "$AUR_HELPER_CHECKED" ]; then
            AUR_HELPERS="yay paru"
            for helper in ${AUR_HELPERS}; do
                if command_exists "${helper}"; then
                    # AUR_HELPER=${helper}
                    printf "%b\n" "${CYAN}Using ${helper} as AUR helper${RC}"
                    AUR_HELPER_CHECKED=true
                    return 0
                fi
            done

            printf "%b\n" "${YELLOW}Installing yay as AUR helper...${RC}"
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel git
            cd /opt && "$ESCALATION_TOOL" git clone https://aur.archlinux.org/yay-bin.git && "$ESCALATION_TOOL" chown -R "$USER":"$USER" ./yay-bin
            cd yay-bin && makepkg --noconfirm -si

            if command_exists yay; then
                # AUR_HELPER="yay"
                AUR_HELPER_CHECKED=true
            else
                printf "%b\n" "${RED}Failed to install AUR helper.${RC}"
                exit 1
            fi
        fi
    fi
}

# Checking Package manager
checkPackageManager() {
    ## Check Package Manager
    PACKAGEMANAGER=$1
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists "${pgm}"; then
            PACKAGER=${pgm}
            printf "%b\n" "${CYAN}Using ${pgm} as package manager${RC}"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        printf "%b\n" "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi
}



# Function to check if the root file system is Btrfs
 check_btrfs() {
    fs_type=$(findmnt -n -o FSTYPE /)

    if [ "$fs_type" = "btrfs" ]; then
        echo  "${GREEN}✅ File system is Btrfs. You're good to go!${RC}"
    else
        echo  "${RED}❌ Sorry, file system is not supported. Current file system is $fs_type.${RC}"
        exit 1
    fi
}

# function for checking grub boot loader
check_grub() {
    if grep -q "GRUB" /boot/grub/grub.cfg 2>/dev/null || [ -d /boot/grub ]; then
        printf '%b%s%b\n' "$GREEN" "✔️  GRUB bootloader detected! Good to go!" "$RC"
    else
        printf '%b%s%b\n' "$RED" "❌  GRUB bootloader not found! Exiting..." "$RC"
        exit 1
    fi
}

# rebooting system
prompt_for_reboot() {
    while true; do
        printf "%b\n" "${CYAN}Do you want to reboot your system? (y/n): ${RC}"
        read -r response

        case "$response" in
            [Yy]* )
                printf "%b\n" "${GREEN}Rebooting the system...${RC}"
                sleep 1  # Optional: delay for better user experience
                sudo reboot  # Use sudo to reboot
                break
                ;;
            [Nn]* )
                printf "%b\n" "${YELLOW}No reboot will be performed. Exiting...${RC}"
                break
                ;;
            * )
                printf "%b\n" "${RED}Invalid input. Please enter 'y' or 'n'.${RC}"
                ;;
        esac
    done
}


checkEnv() {
    checkEscalationTool
    checkCommandRequirements "git curl $ESCALATION_TOOL"
    check_grub
    check_btrfs
    checkPackageManager 'nala apt-get dnf pacman zypper'
    checkAURHelper
}