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

 ██████╗ ██╗     ██╗      █████╗ ███╗   ███╗ █████╗ 
██╔═══██╗██║     ██║     ██╔══██╗████╗ ████║██╔══██╗
██║   ██║██║     ██║     ███████║██╔████╔██║███████║
██║   ██║██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║
╚██████╔╝███████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║
 ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝
                                                    
    ███████╗███████╗████████╗██╗   ██╗██████╗       
    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗      
    ███████╗█████╗     ██║   ██║   ██║██████╔╝      
    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝       
    ███████║███████╗   ██║   ╚██████╔╝██║           
    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝           
                                                           
\033[0m"
echo
echo -e "\033[92m╓────────────────────────────────────────────────────────────╖"
center_text "Welcome to the OLLAMA setup!" "$line_length"
center_text "Script Name: ollama-wsl-setup.sh " "$line_length"
center_text "Author: its-ashu-otf " "$line_length"
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

check_program ollama
check_program docker-ce 
check_program docker-ce-cli 
check_program containerd.io 
check_program docker-buildx-plugin 
check_program docker-compose-plugin
check_program pyenv
check_program make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev git

# Installing Ollama

install_ollama() {
  echo -e "\033[96mDownloading and Installing Ollama...\033[0m"
  sudo apt-get install curl -y
  curl -fsSL https://ollama.com/install.sh | sh
  echo -e "\033[96mFetching Latest llama3.1 (8B)\033[0m"
  ollama pull llama3.1:8b
  echo -e "\033[96mDone ! (8B)\033[0m"
}

install_docker() {
    
    # Adding Docker GPG Key 
    echo -e "\033[96mAdding Docker's Official GPG Key to your Repository....\033[0m"
    sudo apt-get update
    sudo apt-get install ca-certificates -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo -e "\033[96mAdding Docker's Official Repository....\033[0m"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    
    # Installing Docker
    echo -e "\033[96mInstalling Docker...\033[0m"
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Installing OPENUI Web Docker
    echo -e "\033[96mInstalling Open WebUI Docker Container now....\033[0m"
    sudo docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
    echo -e "\033[96mDone !\033[0m"
    
    }

install_stable_diffusion() {
    
    echo -e "\033[96mChecking for PreRequisites....\033[0m"
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev git

    echo -e "\033[96mInstalling PyENV....\033[0m"
    curl https://pyenv.run | bash

    echo -e "\033[96mInstalling Python 3.10 and making it global....\033[0m"
    pyenv install 3.10
    pyenv global 3.10

    echo -e "\033[96mInstalling Stable Diffusion for Image Generation....\033[0m"
    mkdir stablediff
    cd stablediff
    wget -q https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh
    chmod +x webui.sh

    # Display success message
    echo -e "\033[92m Ollama has been installed successfully with llama3.1 LLM and OpenWebUI. Access OpenWEBUI\033[93mhttp://localhost:8080/\033[0m \033[92mto get started.\033[0m"
}

# Function Calls
check_program
install_ollama
install_docker
install_stable_diffusion

# Final message
echo -e "\033[95m Made with ♡ by its-ashu-otf\033[0m"

