#!/bin/bash

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    if ! command_exists ${REQUIREMENTS}; then
        echo -e "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
        exit 1
    fi

    ## Check Package Handeler
    PACKAGEMANAGER='apt yum dnf pacman zypper'
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

cd /var/www/html

echo "Fetching Latest bWAPP from the Repo..."
wget -q --show-progress https://raw.githubusercontent.com/its-ashu-otf/Hacking-Lab/main/bWAPP.zip
unzip -o bWAPP.zip
rm bWAPP.zip

# Function to run SQL commands
run_sql_commands() {
    create user
    local sql_user
    local sql_password

    echo -e "Creating a new user by name 'user' "
    sudo mysql
    create user 'user'@'localhost' identified by 'pass';
    exit;
    
    while true; do
        echo -e "\n\e[96mDefault credentials:\e[0m"
        echo -e "Username: \e[93mroot\e[0m"
        echo -e "\nPassword: \e[93m[No password, just hit Enter]\e[0m"
        read -p $'\e[96mEnter SQL user:\e[0m ' sql_user
        # The root user is configured as the default user to facilitate unattended installations.
        sql_user=${sql_user:-user}
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
     if ! $sql_command -e "create user 'user'@'localhost' identified by 'pass';"; then
        echo -e "\e[91mAn error occurred while creating the user.\e[0m"
        return 1
    fi

     if ! $sql_command -e "GRANT ALL PRIVILEGES ON bWAPP. * to 'user'@'localhost' identified by 'pass'; FLUSH PRIVILEGES;"; then
        echo -e "\e[91mAn error occurred while granting user on the bWAPP database.\e[0m"
        return 1
    fi
    
    if ! $sql_command -e "CREATE DATABASE IF NOT EXISTS bWAPP;"; then
        echo -e "\e[91mAn error occurred while creating the bWAPP database.\e[0m"
        return 1
    fi

    # Check if the user already exists
    if ! $sql_command -e "CREATE USER IF NOT EXISTS 'user'@'localhost' IDENTIFIED BY 'pass';"; then
        echo -e "\e[91mAn error occurred while creating the bWAPP user.\e[0m"
        return 1
    fi

    return 0
}


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


# Check if Apache is already enabled
if systemctl is-enabled apache2 &>/dev/null; then
    echo -e "\033[92mApache service is already enabled.\033[0m"
else
    # Enable Apache
    echo -e "\033[96mEnabling Apache...\033[0m"
    systemctl enable apache2 &>/dev/null
    sleep 2
fi

# Restart Apache
echo -e "\033[96mRestarting Apache...\033[0m"
systemctl restart apache2 &>/dev/null
sleep 2

# Display success message
echo -e "\033[92mbWAPP has been installed successfully. Access \033[93mhttp://localhost/bWAPP\033[0m \033[92mto get started.\033[0m"

# Show user credentials after configuration
echo -e "\033[92mCredentials:\033[0m"
echo -e "Username: \033[93mbee\033[0m"
echo -e "Password: \033[93mbug\033[0m"

# Final message
echo -e "\033[95m Made with ♡ by its-ashu-otf\033[0m"

# Function Call
checkEnv
