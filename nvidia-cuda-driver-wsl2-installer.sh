#!/bin/sh

# Check if running with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run with sudo privileges."
    read -p "Do you want to escalate? (y/n): " choice
    if [ "$choice" == "y" ]; then
        sudo "$0" "$@"  # Execute this script with sudo
    else
        echo "Script execution aborted."
        exit 1
    fi
fi

echo "Running with sudo privileges!"

# Enviroment Checks

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='wget curl groups sudo'
    if ! command_exists ${REQUIREMENTS}; then
        echo -e "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
        exit 1
    fi

    ## Check Package Handeler
    PACKAGEMANAGER='apt yum dnf pacman zypper emerge xbps-install nix-env'
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists ${pgm}; then
            PACKAGER=${pgm}
            echo -e "Using ${pgm}"
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo -e "${RED}Can't find a supported package manager"
        exit 1
    fi

    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi

    echo "Using ${SUDO_CMD} as privilege escalation software"
    
    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(realpath "$0")")"
    if [[ ! -w ${GITPATH} ]]; then
        echo -e "${RED}Can't write to ${GITPATH}${RC}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep ${sug}; then
            SUGROUP=${sug}
            echo -e "Super user group ${SUGROUP}"
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep ${SUGROUP} >/dev/null; then
        echo -e "${RED}You need to be a member of the sudo group to run me!"
        exit 1
    fi

}

# Installer for Nvidia Cuda Drivers for WSL2

nvidia_installer() (

	echo "Fetching The Repos...."
	wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
 	echo " "
	echo "Adding The Repos to Sources List...."
	sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
 	echo " "
	echo "Downloading NVIDIA Cuda 12.6 Installer"
	wget -q --show-progress https://developer.download.nvidia.com/compute/cuda/12.6.2/local_installers/cuda-repo-wsl-ubuntu-12-6-local_12.6.2-1_amd64.deb
	echo " "
	echo "Installing NVIDIA Cuda 12.6...."
	sudo dpkg -i cuda-repo-wsl-ubuntu-12-6-local_12.6.2-1_amd64.deb
	echo " "
	echo "Adding Cuda Toolkit Repo to Sources List..."
	sudo cp /var/cuda-repo-wsl-ubuntu-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
	echo " "
	echo "Updating The Repos..."
	sudo apt-get update
	echo "Done !"
	echo " "
	echo "Installing Nvidia Cuda Toolkit...."
	sudo apt-get -y install cuda-toolkit-12-6
	echo "Done !"
)
