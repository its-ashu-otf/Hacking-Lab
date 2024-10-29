#!/bin/sh

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RC='\033[0m'

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${RC}"
    exit 1
}

# Check if running with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script needs to be run with sudo privileges.${RC}"
    read -p "Do you want to escalate? (y/n): " choice
    if [ "$choice" = "y" ]; then
        exec sudo "$0" "$@"  # Execute this script with sudo
    else
        echo "Script execution aborted."
        exit 1
    fi
fi

echo -e "${GREEN}Running with sudo privileges!${RC}"

# Check if running in WSL
if ! grep -iq "microsoft" /proc/version; then
    handle_error "This script is designed to run within WSL only."
else
    echo -e "${GREEN}WSL Detected.${RC}"
fi

# Environment Checks
checkEnv() {
    # Check for required commands
    REQUIREMENTS='wget curl groups'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            handle_error "To run this script, you need: ${REQUIREMENTS}"
        fi
    done

    # Check for supported package manager
    PACKAGEMANAGER='apt yum dnf pacman zypper emerge xbps-install nix-env'
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            echo -e "${GREEN}Using ${pgm} as package manager.${RC}"
            break
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        handle_error "Can't find a supported package manager."
    fi

    # Check if the current directory is writable
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "${GITPATH}" ]; then
        handle_error "Can't write to ${GITPATH}."
    fi

    # Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    SUGROUP=""
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "${sug}"; then
            SUGROUP="${sug}"
            echo -e "${GREEN}Super user group: ${SUGROUP}.${RC}"
            break
        fi
    done

    # Ensure the user is a member of the superuser group
    if [ -z "${SUGROUP}" ]; then
        handle_error "You need to be a member of the ${SUPERUSERGROUP} group to run this script!"
    fi
}

# Installer for NVIDIA CUDA Drivers for WSL2
nvidia_installer() {
    echo -e "${YELLOW}Fetching The Repos....${RC}"
    wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin || handle_error "Failed to fetch repo."
    
    echo -e "${YELLOW}Adding The Repos to Sources List....${RC}"
    mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600 || handle_error "Failed to move repo file."
    
    echo -e "${YELLOW}Downloading NVIDIA CUDA 12.6 Installer...${RC}"
    wget -q --show-progress https://developer.download.nvidia.com/compute/cuda/12.6.2/local_installers/cuda-repo-wsl-ubuntu-12-6-local_12.6.2-1_amd64.deb || handle_error "Failed to download CUDA installer."
    
    echo -e "${YELLOW}Installing NVIDIA CUDA 12.6....${RC}"
    dpkg -i cuda-repo-wsl-ubuntu-12-6-local_12.6.2-1_amd64.deb || handle_error "Failed to install CUDA package."
    
    echo -e "${YELLOW}Adding CUDA Toolkit Repo to Sources List...${RC}"
    cp /var/cuda-repo-wsl-ubuntu-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/ || handle_error "Failed to add keyring."
    
    echo -e "${YELLOW}Updating The Repos...${RC}"
    apt-get update || handle_error "Failed to update repos."
    
    echo -e "${YELLOW}Installing NVIDIA CUDA Toolkit....${RC}"
    apt-get -y install cuda-toolkit-12-6 || handle_error "Failed to install CUDA Toolkit."
    
    echo -e "${GREEN}NVIDIA CUDA Toolkit installed successfully!${RC}"
}

# Run environment checks and installer
checkEnv
nvidia_installer
