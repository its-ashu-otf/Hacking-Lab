#!/bin/bash

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

echo "Installing Floorp..."
curl -fsSL https://ppa.ablaze.one/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/Floorp.gpg
sudo curl -sS --compressed -o /etc/apt/sources.list.d/Floorp.list 'https://ppa.ablaze.one/Floorp.list'
sudo apt update && sudo apt install floorp -y

echo "Installing Terminator"
sudo apt-get update && sudo apt-get install terminator -y 

echo "Adding Clipboard Manager Like Windows & Setting up the Shortkey with Windows key + v"
wget -q --show-progress https://raw.githubusercontent.com/its-ashu-otf/Fix-my-Kali/main/add-clipman.sh
bash ./add-clipman.sh
rm add-clipman.sh

echo "Done ! Reboot you're System to see the Changes..."
