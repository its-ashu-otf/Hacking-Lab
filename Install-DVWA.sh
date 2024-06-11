#!/bin/bash

# Function to center text
center_text() {
    local text="$1"
    local line_length="$2"
    local text_length=${#text}
    local padding_before=$(( (line_length - text_length) / 2 ))
    local padding_after=$(( line_length - text_length - padding_before ))
    
    printf "%s%-${padding_before}s%s%-*s%s\n" "║" " " "$text" "$padding_after" " " "║"
}

# Desired line length
line_length=60

# ASCII Art
echo -e "\033[96m\033[1m
                  ██████╗ ██╗   ██╗██╗    ██╗ █████╗                    
                  ██╔══██╗██║   ██║██║    ██║██╔══██╗                   
                  ██║  ██║██║   ██║██║ █╗ ██║███████║                   
                  ██║  ██║╚██╗ ██╔╝██║███╗██║██╔══██║                   
                  ██████╔╝ ╚████╔╝ ╚███╔███╔╝██║  ██║                   
                  ╚═════╝   ╚═══╝   ╚══╝╚══╝ ╚═╝  ╚═╝                   
                                                                        
  ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
  ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
  ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
  ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
  ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝     
\033[0m"
echo
echo -e "\033[92m╓────────────────────────────────────────────────────────────╖"
center_text "Welcome to the DVWA setup!" "$line_length"
center_text "Script Name: Install-DVWA.sh " "$line_length"
center_text "Author: its-ashu-otf " "$line_length"
center_text "Github Repo: https://github.com/its-ashu-otf/Hacking-Lab" "$line_length"
center_text "Installer Version: 1.0.5 " "$line_length"
echo -e "╙────────────────────────────────────────────────────────────╜\033[0m"
echo

# Function to verify the existence of a program
check_program() {
    if ! dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; then
        message=$("\033[91m$1 is not installed. Installing it now...\e[0m")
        echo -e >&2 "$message"
        apt install -y "$1"
    else
        success_message=$( "\033[92m$1 is installed!\033[0m" ")
        echo -e "$success_message"
    fi
}

run_sql_commands() {
    local sql_user
    local sql_password

    while true; do
        echo -e "\n$( "\e[96mDefault credentials:\e[0m")"
        echo -e "Username: \033[93mroot\033[0m"
        echo -e "\n$( "Password: \033[93m[No password just hit Enter]\033[0m")"
        read -p "$( "\e[96mEnter SQL user:\e[0m " )" sql_user
        # The root user is configured as the default user to facilitate unattended installations.
        sql_user=${sql_user:-root}
        read -s -p "$( "\e[96mEnter SQL password (press Enter for no password):\e[96m ")" sql_password
        echo
        # Verify if credentials are valid before executing SQL commands
        if ! mysql -u "$sql_user" -p"$sql_password" -e ";" &>/dev/null; then
            echo -e "\n$( "\e[91mError: Invalid SQL credentials. Please check your username and password. If you are traying to use root user and blank password make sure that you are running the script as root user.\e[0m" "\e[91mError: Credenciales SQL inválidas. Por favor, compruebe su nombre de usuario y contraseña. Si usted estas intentando de utilizar el usuario root y la contraseña en blanco asegúrate de que estas ejecutando el script como usuario root.")"
        else
            break
        fi
    done

    local success=false
    while [ "$success" != true ]; do
        # Execute SQL commands
        sql_commands_output=$(sql_commands "$sql_user" "$sql_password")

        if [ $? -eq 0 ]; then
            echo -e "$( "\033[92mSQL commands executed successfully.\033[0m")"
            success=true
        else
            if [ "$recreate_choice" != "no" ]; then
                break
            fi
        fi
    done
}

sql_commands() {
    local sql_user="$1"
    local sql_password="$2"
    local sql_command="mysql -u$sql_user"

    if [ -n "$sql_password" ]; then
        sql_command+=" -p$sql_password"
    fi

    # Check if the database already exists
    if ! $sql_command -e "CREATE DATABASE IF NOT EXISTS dvwa;"; then
        echo -e "$( "\033[91mAn error occurred while creating the DVWA database.")"
        return 1
    fi

    # Check if the user already exists
    if ! $sql_command -e "CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';"; then
        echo -e "$( "\033[91mAn error occurred while creating the DVWA user.")"
        return 1
    fi

    # Assign privileges to the user
    if ! $sql_command -e "GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost'; FLUSH PRIVILEGES;"; then
        echo -e "$( "\033[91mAn error occurred while granting privileges.")"
        return 1
    fi

    echo 0
}

# Installer startup

# Update repositories
update_message=$( "\e[96mUpdating repositories...\e[0m")
echo -e "$update_message"
apt update

# Check if the dependencies are installed
dependencies_message=$( "\e[96mVerifying and installing necessary dependencies...\e[0m")
echo -e "$dependencies_message"

check_program apache2
check_program mariadb-server
check_program mariadb-client
check_program php
check_program php-mysql
check_program php-gd
check_program libapache2-mod-php
check_program git

# Download DVWA repository from GitHub

# Checking if the folder already exists
if [ -d "/var/www/html/DVWA" ]; then
    # La carpeta ya existe / The folder already exists
    warning_message=$( "\e[91mAttention! The DVWA folder is already created.\e[0m")
    echo -e "$warning_message"

    # Ask the user what action to take
    read -p "$( "\e[96mDo you want to delete the existing folder and download it again (y/n):\e[0m ")" user_response

    if [[ "$user_response" == "s" || "$user_response" == "y" ]]; then
        # Delete existing folder
        rm -rf /var/www/html/DVWA

        #  Download DVWA from GitHub
        download_message=$( "\e[96mDownloading DVWA from GitHub...\e[0m")
        echo -e "$download_message"
        git clone https://github.com/digininja/DVWA.git /var/www/html/DVWA
        sleep 2
    elif [ "$user_response" == "n" ]; then
        # User chooses not to download
        no_download_message=$( "\e[96mContinuing without downloading DVWA.\e[0m")
        echo -e "$no_download_message"
    else
        # Invalid answer
        invalid_message=$( "\e[91mError! Invalid response. Exiting the script.\e[0m")
        echo -e "$invalid_message"
        exit 1
    fi
else
    #  Folder does not exist, download DVWA from GitHub
    download_message=$( "\e[96mDownloading DVWA from GitHub...\e[0m")
    echo -e "$download_message"
    git clone https://github.com/digininja/DVWA.git /var/www/html/DVWA
    sleep 2
fi
# Check if MariaDB is already enabled
if systemctl is-enabled mariadb.service &>/dev/null; then
    mariadb_already_enabled_message=$( "\033[92mMariaDB service is already enabled.\033[0m" )
    echo -e "$mariadb_already_enabled_message"
else
    # Enable Apache
    mariadb_enable_message=$( "\e[96mEnabling MariaDB...\e[0m")
    echo -e "$mariadb_enable_message"
    systemctl enable mariadb.service &>/dev/null
    sleep 2
fi

#  Check if MariaDB is already started
if systemctl is-active --quiet mariadb.service; then
    mariadb_already_started_message=$( "\033[92mMariaDB service is already running.\033[0m")
    echo -e "$mariadb_already_started_message"
else
    #Start MariaDB
    mariadb_start_message=$( "\e[96mStarting MariaDB...\e[0m")
    echo -e "$mariadb_start_message"
    systemctl start mariadb.service
    sleep 2
fi

# Call the function
run_sql_commands
sleep 2

# Coping DVWA folder to /var/www/html
dvwa_config_message=$( "\e[96mConfiguring DVWA...\e[0m")
echo -e "$dvwa_config_message"
cp /var/www/html/DVWA/config/config.inc.php.dist /var/www/html/DVWA/config/config.inc.php
sleep 2

# Assign the appropriate permissions to DVWA
permissions_config_message=$( "\e[96mConfiguring permissions...\e[0m")
echo -e "$permissions_config_message"
chown -R www-data:www-data /var/www/html/DVWA
chmod -R 755 /var/www/html/DVWA
sleep 2

php_config_message=$( "\e[96mConfiguring PHP...\e[0m" )
echo -e "$php_config_message"
#  Trying to find the php.ini file in the Apache folder
php_config_file_apache="/etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini"

# Trying to find the php.ini file in the FPM folder
php_config_file_fpm="/etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/fpm/php.ini"

# Check if the php.ini file exists in the Apache folder and use it if present.
if [ -f "$php_config_file_apache" ]; then
    php_config_file="$php_config_file_apache"
    sed -i 's/^\(allow_url_include =\).*/\1 on/' $php_config_file
    sed -i 's/^\(allow_url_fopen =\).*/\1 on/' $php_config_file
    sed -i 's/^\(display_errors =\).*/\1 on/' $php_config_file
    sed -i 's/^\(display_startup_errors =\).*/\1 on/' $php_config_file
# Check if the php.ini file exists in the FPM folder and use it if present.
elif [ -f "$php_config_file_fpm" ]; then
    php_config_file="$php_config_file_fpm"
    sed -i 's/^\(allow_url_include =\).*/\1 on/' $php_config_file
    sed -i 's/^\(allow_url_fopen =\).*/\1 on/' $php_config_file
    sed -i 's/^\(display_errors =\).*/\1 on/' $php_config_file
    sed -i 's/^\(display_startup_errors =\).*/\1 on/' $php_config_file
else
    #  Warning message if not found in any of the folders
    php_file_message=$( "\e[91mWarning: PHP configuration file not found in Apache or FPM folders.\e[0m")
    echo -e "$php_file_message"
fi
sleep 2

#  Check if Apache is already enabled
if systemctl is-enabled apache2 &>/dev/null; then
    apache_already_enabled_message=$( "\033[92mApache service is already enabled.\033[0m")
    echo -e "$apache_already_enabled_message"
else
    # Enable Apache
    apache_enable_message=$( "\e[96mEnabling Apache...\e[0m" )
    echo -e "$apache_enable_message"
    systemctl enable apache2 &>/dev/null
    sleep 2
fi

# Apache restart
apache_restart_message=$( "\e[96mRestarting Apache...\e[0m")
echo -e "$apache_restart_message"
systemctl enable apache2 &>/dev/null
systemctl restart apache2 &>/dev/null
sleep 2

success_message=$( "\e[92mDVWA has been installed successfully. Access \e[93mhttp://localhost/DVWA\e[0m \e[92mto get started.")
echo -e "$success_message"

#Show user credentials after configuration
credentials_after_setup_message=$( "\e[92mCredentials:\e[0m")
echo -e "$credentials_after_setup_message"
echo -e "Username: \033[93madmin\033[0m"
echo -e "Password: \033[93mpassword\033[0m"

final_message=$( "\033[95mWith ♡ by its-ashu-otf")
echo -e "$final_message"
