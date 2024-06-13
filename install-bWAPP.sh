#!/bin/bash

checkEnv() {
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

    # check for sudo privileges
    if [ "$EUID" -ne 0 ]; then
        error_message=$(get_language_message "\e[91mThis script must be run by the root user.\e[0m" "\e[91mEste script debe ejecutarse como usuario root.\e[0m")
        echo -e "$error_message"
        exit 1
    fi
}

# Function to center text
center_text() {
    local text="$1"
    local line_length="$2"
    local text_length=${#text}
    local padding_before=$(( (line_length - text_length) / 2 ))
    local padding_after=$(( line_length - text_length - padding_before ))
    
    printf "%s%-${padding_before}s%s%-*s%s\n" "║" " " "$text" "$padding_after" " " "║"
}

# ASCII Art
echo -e "\033[96m\033[1m

                ██████╗ ██╗    ██╗ █████╗ ██████╗ ██████╗             
                ██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔══██╗            
                ██████╔╝██║ █╗ ██║███████║██████╔╝██████╔╝            
                ██╔══██╗██║███╗██║██╔══██║██╔═══╝ ██╔═══╝             
                ██████╔╝╚███╔███╔╝██║  ██║██║     ██║                 
                ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝                 
                                                                      
██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
                                                                      
\033[0m"
echo
echo -e "\033[92m╓────────────────────────────────────────────────────────────╖"
center_text "Welcome to the bWAPP setup!" "$line_length"
center_text "Script Name: Install-bWAPP.sh " "$line_length"
center_text "Author: its-ashu-otf " "$line_length"
center_text "Github Repo: https://github.com/its-ashu-otf/Hacking-Lab" "$line_length"
center_text "Installer Version: 1.0.0 " "$line_length"
echo -e "╙────────────────────────────────────────────────────────────╜\033[0m"
echo


# Updating repositories
echo -e "\033[96mUpdating repositories...\033[0m"
apt update

# Function to verify the existence of a program
check_program() {
    if ! dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; then
        message="\033[91m$1 is not installed. Installing it now...\033[0m"
        echo -e >&2 "$message"
        apt install -y "$1"
    else
        success_message="\033[92m$1 is installed!\033[0m"
        echo -e "$success_message"
    fi
}

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


# Downloading bWAPP repository from GitHub

# Checking if the folder already exists
if [ -d "/var/www/html/bWAPP" ]; then
    # Ask the user what action to take
    read -p $'\033[96mDo you want to delete the existing folder and download it again (y/n):\033[0m ' user_response

    if [[ "$user_response" == "y" ]]; then
        rm -rf /var/www/html/bWAPP >> install_log.txt 2>&1

        # Download bWAPP from GitHub
        echo -e "\033[96mDownloading bWAPP from GitHub...\033[0m"
        cd /var/www/html
        wget -q --show-progress https://raw.githubusercontent.com/its-ashu-otf/Hacking-Lab/main/bWAPP.zip
        unzip -o bWAPP.zip
        rm bWAPP.zip
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
    cd /var/www/html
    wget -q --show-progress https://raw.githubusercontent.com/its-ashu-otf/Hacking-Lab/main/bWAPP.zip >> install_log.txt 2>&1
    unzip -o bWAPP.zip
    rm bWAPP.zip
    sleep 2
fi

# Assign appropriate permissions to DVWA
echo -e "\033[96mConfiguring permissions...\033[0m"
chown -R www-data:www-data /var/www/html/bWAPP
chmod -R 755 /var/www/html/bWAPP
sleep 2

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
 # Check if the user already exists
    if ! $sql_command -e "CREATE USER IF NOT EXISTS 'user'@'localhost' IDENTIFIED BY 'pass';"; then
        echo -e "\e[91mAn error occurred while creating the bWAPP user.\e[0m"
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
echo -e "\033[92mbWAPP has been installed successfully. Access \033[93mhttp://localhost/bWAPP/install.php\033[0m \033[92mto get started.\033[0m"

# Show user credentials after configuration
echo -e "\033[92mCredentials:\033[0m"
echo -e "Username: \033[93mbee\033[0m"
echo -e "Password: \033[93mbug\033[0m"

# Final message
echo -e "\033[95m Made with ♡ by its-ashu-otf\033[0m"

# Function Call
checkEnv
