#!/bin/sh -e

. /common-script.sh
. /fedora.sh
. /arch.sh
. /debian.sh


# Function to determine the distribution based on the package manager
detect_distribution() {
    PACKAGER=$1

    case "${PACKAGER}" in
        apt-get | nala)
            printf "%b\n" "${RED}🟢  Detected a Debian-based system Sorry Snapper config is comming soon${RC}"
            exit 1
            ;;
        dnf)
            printf "%b\n" "${RED}🟢  Detected a Fedora-based system${RC}"
            fedoraRun
            ;;
        yum)
            printf "%b\n" "${RED}🟢  Detected a Red Hat-based system (e.g., CentOS, RHEL)${RC}"
            ;;
        pacman)
            printf "%b\n" "${GREEN}🟢  Detected an Arch Linux-based system Sorry arch Based Snapper config is comming soon${RC}"
            exit 1
            ;;
        zypper)
            printf "%b\n" "${GREEN}🟢  Detected an openSUSE-based system, Sorry Snapper config is comming soon${RC}"
             exit 1
            ;;
        *)
            printf "%b\n" "${YELLOW}⚠️  Package manager detected but unable to determine the distribution${RC}"
             exit 1
            ;;
    esac
}

detect_distribution "$PACKAGER"