#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if an escalation tool is available (sudo, doas)
checkEscalationTool() {
    if [ -z "$ESCALATION_TOOL_CHECKED" ]; then
        if [ "$(id -u)" = "0" ]; then
            ESCALATION_TOOL="eval"
            ESCALATION_TOOL_CHECKED=true
            printf "%b\n" "${CYAN}Running as root, no escalation needed${RC}"
            return 0
        fi

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

# Function to check if the current user has the required commands installed
checkCommandRequirements() {
    REQUIREMENTS=$1
    for req in ${REQUIREMENTS}; do
        if ! command_exists "${req}"; then
            printf "%b\n" "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
            exit 1
        fi
    done
}

# Function to check the package manager
checkPackageManager() {
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

# Function to check if the user is in a superuser group
checkSuperUser() {
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep -q "${sug}"; then
            SUGROUP=${sug}
            printf "%b\n" "${CYAN}Super user group ${SUGROUP}${RC}"
            break
        fi
    done

    if [ -z "$SUGROUP" ]; then
        printf "%b\n" "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

# Function to check if the current directory is writable
checkCurrentDirectoryWritable() {
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "$GITPATH" ]; then
        printf "%b\n" "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi
}

# Function to check the distribution
checkDistro() {
    DTYPE="unknown"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DTYPE=$ID
    fi
}

# Function to check if Flatpak is installed and configure it
checkFlatpak() {
    if ! command_exists flatpak; then
        printf "%b\n" "${YELLOW}Installing Flatpak...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm flatpak
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add flatpak
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y flatpak
                ;;
        esac
        printf "%b\n" "${YELLOW}Adding Flathub remote...${RC}"
        "$ESCALATION_TOOL" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        printf "%b\n" "${YELLOW}Applications installed by Flatpak may not appear on your desktop until the user session is restarted...${RC}"
    else
        if ! flatpak remotes | grep -q "flathub"; then
            printf "%b\n" "${YELLOW}Adding Flathub remote...${RC}"
            "$ESCALATION_TOOL" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        else
            printf "%b\n" "${CYAN}Flatpak is installed${RC}"
        fi
    fi
}

# Function to configure Flatpak application symlinks and update the desktop environment
configure_flatpak() {
    printf "%b\n" "${YELLOW}Making Symbolic link to Flatpak Packages...${RC}"

    # Create symlinks for Flatpak applications and icons if not already linked
    if [ ! -L /usr/share/applications/flatpak ]; then
        "$ESCALATION_TOOL" ln -s /var/lib/flatpak/exports/share/applications /usr/share/applications/flatpak
    else
        printf "%b\n" "${YELLOW}/usr/share/applications/flatpak already exists, skipping...${RC}"
    fi

    if [ ! -L ~/.local/share/icons/hicolor ]; then
        "$ESCALATION_TOOL" ln -s /var/lib/flatpak/exports/share/icons/hicolor ~/.local/share/icons/
    else
        printf "%b\n" "${YELLOW}~/.local/share/icons/hicolor already exists, skipping...${RC}"
    fi

    # Update Desktop Database
    printf "%b\n" "${YELLOW}Updating Desktop Database...${RC}"
    if "$ESCALATION_TOOL" update-desktop-database; then
        printf "%b\n" "${YELLOW}Desktop Database updated successfully!${RC}"
    else
        printf "%b\n" "${RED}Failed to update Desktop Database.${RC}"
    fi

    # Add Flatpak directories to XDG_DATA_DIRS
    printf "%b\n" "${YELLOW}Adding Flatpak directories to XDG_DATA_DIRS...${RC}"
    export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:/home/ashu/.local/share/flatpak/exports/share"

    # Final confirmation
    printf "%b\n" "${YELLOW}Configuration complete! Flatpak applications should now appear in the menu.${RC}"
}

# Main execution starts here

checkEscalationTool
checkCommandRequirements "flatpak ln"
checkPackageManager "apt pacman apk"
checkSuperUser
checkFlatpak
configure_flatpak
