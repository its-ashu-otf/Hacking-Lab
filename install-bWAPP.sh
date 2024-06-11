#!/bin/bash

cd /var/www/html

echo "Fetching Latest bWAPP from the Repo..."
wget -q --show-progress https://github.com/its-ashu-otf/Hacking-Lab/raw/main/bWAPP_latest.zip

# Function to run SQL commands
run_sql_commands() {
    local sql_user
    local sql_password

    while true; do
        echo -e "\n\e[96mDefault credentials:\e[0m"
        echo -e "Username: \e[93mroot\e[0m"
        echo -e "\nPassword: \e[93m[No password, just hit Enter]\e[0m"
        read -p $'\e[96mEnter SQL user:\e[0m ' sql_user
        # The root user is configured as the default user to facilitate unattended installations.
        sql_user=${sql_user:-root}
        read -s -p $'\e[96mEnter SQL password (press Enter for no password):\e[0m ' sql_password
        echo
        # Verify if credentials are valid before executing SQL commands
        if ! mysql -u "$sql_user" -p"$sql_password" -e ";" &>/dev/null; then
            echo -e "\n\e[91mError: Invalid SQL credentials. Please check your username and password. If you are trying to use the root user with a blank password, make sure that you are running the script as the root user.\e[0m"
        else
            break
        fi
    done

    # Execute SQL commands
    if sql_commands "$sql_user" "$sql_password"; then
        echo -e "\e[92mSQL commands executed successfully.\e[0m"
    fi
}

# Function to execute SQL commands
sql_commands() {
    local sql_user="$1"
    local sql_password="$2"
    local sql_command="mysql -u$sql_user"

    if [ -n "$sql_password" ]; then
        sql_command+=" -p$sql_password"
    fi

    # Check if the database already exists
    if ! $sql_command -e "CREATE DATABASE IF NOT EXISTS dvwa;"; then
        echo -e "\e[91mAn error occurred while creating the DVWA database.\e[0m"
        return 1
    fi

    # Check if the user already exists
    if ! $sql_command -e "CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';"; then
        echo -e "\e[91mAn error occurred while creating the DVWA user.\e[0m"
        return 1
    fi

    # Assign privileges to the user
    if ! $sql_command -e "GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost'; FLUSH PRIVILEGES;"; then
        echo -e "\e[91mAn error occurred while granting privileges.\e[0m"
        return 1
    fi

    return 0
}


# Updating repositories
echo -e "\033[96mUpdating repositories...\033[0m"
apt update

# Checking and installing necessary dependencies
echo -e "\033[96mVerifying and installing necessary dependencies...\033[0m"

check_program apache2
check_program mariadb-server
check_program mariadb-client
check_program php
check_program php-mysql
check_program php-gd
check_program libapache2-mod-php
check_program git

# Downloading DVWA repository from GitHub

# Checking if the folder already exists
if [ -d "/var/www/html/DVWA" ]; then
    # Ask the user what action to take
    read -p $'\033[96mDo you want to delete the existing folder and download it again (y/n):\033[0m ' user_response

    if [[ "$user_response" == "y" ]]; then
        rm -rf /var/www/html/DVWA >> install_log.txt 2>&1

        # Download DVWA from GitHub
        echo -e "\033[96mDownloading DVWA from GitHub...\033[0m"
        git clone https://github.com/digininja/DVWA.git /var/www/html/DVWA >> install_log.txt 2>&1
        sleep 2
    elif [ "$user_response" == "n" ]; then
        echo -e "\033[96mContinuing without downloading DVWA.\033[0m"
    else
        echo -e "\033[91mError! Invalid response. Exiting the script.\033[0m"
        exit 1
    fi
else
    # Folder does not exist, download DVWA from GitHub
    echo -e "\033[96mDownloading DVWA from GitHub...\033[0m"
    git clone https://github.com/digininja/DVWA.git /var/www/html/DVWA >> install_log.txt 2>&1
    sleep 2
fi


# Check if MariaDB is already enabled
if systemctl is-enabled mariadb.service &>/dev/null; then
    echo -e "\033[92mMariaDB service is already enabled.\033[0m"
else
    # Enable MariaDB
    echo -e "\033[96mEnabling MariaDB...\033[0m"
    systemctl enable mariadb.service &>/dev/null
    sleep 2
fi

# Check if MariaDB is already started
if systemctl is-active --quiet mariadb.service; then
    echo -e "\033[92mMariaDB service is already running.\033[0m"
else
    # Start MariaDB
    echo -e "\033[96mStarting MariaDB...\033[0m"
    systemctl start mariadb.service
    sleep 2
fi

# Call the function to run SQL commands
run_sql_commands
sleep 2
