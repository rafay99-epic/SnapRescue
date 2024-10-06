#!/bin/sh -e

. /common-script.sh
. /snapperconfig.sh


# Remaining Package not found, maybe need to compile from source
# snap-pac
# snapper-rollback


extroRepo(){
    sudo dnf copr enable @neurofedora/neurofedora-extra
    sudo dnf copr enable kylegospo/grub-btrfs
}

installPakageFedora(){
     if ! command_exists sanpper; then
    printf "%b\n" "${YELLOW}Installing Snapper...${RC}"
        case "$PACKAGER" in
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y  snapper
                ;;
                 *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
        esac
    else
        printf "%b\n" "${GREEN} Snapper is already installed.${RC}"
    fi

    if ! command_exists grub-btrfs; then
        printf "%b\n" "${YELLOW}Installing grub-btrfs...${RC}"
            case "$PACKAGER" in
                dnf)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y  grub-btrfs
                    ;;
                *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
            esac
        else
            printf "%b\n" "${GREEN} grub-btrfs is already installed.${RC}"
        fi

    if ! command_exists inotify-tools; then
        printf "%b\n" "${YELLOW}Installing inotify-tools...${RC}"
            case "$PACKAGER" in
                dnf)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y  inotify-tools
                    ;;
                *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
            esac
        else
            printf "%b\n" "${GREEN} ginotify-tools is already installed.${RC}"
        fi

}

fedoraRun(){
    checkEnv
    extroRepo
    installPakageFedora
    SnapperServices
    prompt_for_reboot
}

