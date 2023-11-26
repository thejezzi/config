#!/bin/bash

# Globals
IS_WINDOWS=0
IS_MAC=0
IS_LINUX=0
LINUX_DISTRO=""
CURRENT_SYSTEM=""

MANUAL_INSTALL_LIST=()

# Color variables
BLUE_FG="\e[34m"
RED_FG="\e[31m"
GREEN_FG="\e[32m"
YELLOW_FG="\e[33m"
RESET="\e[0m"

# Text formatting variables
BOLD="\e[1m"
UNDERLINE="\e[4m"

# Functions

# Prints a message in color
print_color() {
    local color="$1"
    local message="$2"
    echo -e -n "${color}"
    echo -e "${message}${RESET}"
}

# Utility functions

# Prompt for a question
question() {
    local prompt="$1"
    echo -e "${BOLD}${BLUE_FG}${prompt}${RESET}"
    read -r -p ">> " LAST_INPUT
}

# Prompt for confirmation (yes/no)
confirmation() {
    local prompt="$1 [y/n]"
    echo -e "${BOLD}${BLUE_FG}${prompt}${RESET}"
    while true; do
        read -r -p ">> " LAST_INPUT
        case $LAST_INPUT in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Set choices for selection
set_choices() {
    CHOICES=("$@")
}

# Prompt for a choice from a list
choice() {
    local prompt="$1"
    echo -e "${BOLD}${BLUE_FG}${prompt}${RESET}"
    select choice in "${CHOICES[@]}"; do
        LAST_INPUT=$choice
        break
    done
}

# Check if the current system is Windows
is_windows() {
    if [ $IS_WINDOWS -eq 0 ]; then
        if [ "$(uname -s)" = "Windows_NT" ]; then
            IS_WINDOWS=1
        else
            IS_WINDOWS=2
        fi
    fi

    if [ $IS_WINDOWS -eq 1 ]; then
        echo 1
    else
        echo 0
    fi
}

# Check if the current system is macOS
is_mac() {
    if [ $IS_MAC -eq 0 ]; then
        if [ "$(uname -s)" = "Darwin" ]; then
            IS_MAC=1
        else
            IS_MAC=2
        fi
    fi

    if [ $IS_MAC -eq 1 ]; then
        echo 1
    else
        echo 0
    fi
}

# Check if the current system is Linux
is_linux() {
    if [ $IS_LINUX -eq 0 ]; then
        if [ "$(uname -s)" = "Linux" ]; then
            IS_LINUX=1
        else
            IS_LINUX=2
        fi
    fi

    if [ $IS_LINUX -eq 1 ]; then
        echo 1
    else
        echo 0
    fi
}

# Get the Linux distribution
get_distro() {
    if [ "$LINUX_DISTRO" = "" ]; then
        LINUX_DISTRO=$(grep -E "^ID=" /etc/*-release | cut -d "=" -f 2)
    fi

    echo "$LINUX_DISTRO"
}

get_current_system() {
    local os=""
    local distro=""

    # Detect the operating system
    if [ "$(uname -s)" = "Linux" ]; then
        os="Linux"

        # Detect the Linux distribution (works for most distributions)
        if [ -f "/etc/os-release" ]; then
            distro=$(grep -E "^ID=" /etc/os-release | cut -d "=" -f 2)
        fi
    elif [ "$(uname -s)" = "Darwin" ]; then
        os="macOS"
    elif [ "$(uname -s)" = "Windows_NT" ]; then
        os="Windows"
    else
        os="Unknown"
    fi

    # Set the CURRENT_SYSTEM variable
    if [ -n "$distro" ]; then
        CURRENT_SYSTEM="$os ($distro)"
    else
        CURRENT_SYSTEM="$os"
    fi
}

# Perform general system checks
general_checks() {
    if [ "$(is_windows)" -eq 1 ]; then
        print_color "$RED_FG" "Windows is not supported yet."
        exit 1
    fi

    if [ "$(is_mac)" -eq 1 ]; then
        print_color "$RED_FG" "macOS is not supported yet."
        exit 1
    fi

    if [ "$(is_linux)" -eq 0 ]; then
        print_color "$RED_FG" "This script only works on Linux."
        exit 1
    fi

    if [ "$(get_distro)" == "arch" ]; then
        print_color "$YELLOW_FG" "It seems you're running this script on $CURRENT_SYSTEM"
        print_color "$YELLOW_FG" "Therefore this script may not work."

        if confirmation "Still want to try it" ; then
            print_color "$GREEN_FG" "Okay, let's go!"
        else
            print_color "$RED_FG" "Okay, bye!"
            exit 1
        fi
    fi

    #check curl
    if ! is_installed "curl"; then
        if confirmation "Should i try to install curl? \n($(print_install_command "curl"))"; then
            install_package "curl"
        else
            MANUAL_INSTALL_LIST+=("curl")
        fi
    fi
}


install_package() {
    local package_manager=""
    local package_name="$1"

    # Check if the system is macOS and Homebrew is available
    if [ "$(uname -s)" = "Darwin" ] && [ -x "$(command -v brew)" ]; then
        package_manager="brew"
    else
        # Check for the package manager based on the Linux distribution
        case "$CURRENT_SYSTEM" in
            "Linux (ubuntu)" | "Linux (debian)")
                package_manager="apt-get"
                ;;
            "Linux (fedora)")
                package_manager="dnf"
                ;;
            "Linux (centos)" | "Linux (rhel)")
                package_manager="yum"
                ;;
            "Linux (arch)")
                package_manager="pacman"
                ;;
            *)
                echo "Unsupported distribution or macOS without Homebrew."
                exit 1
                ;;
        esac
    fi

    # Attempt to install the package using the determined package manager
    if [ "$package_manager" = "brew" ]; then
        brew install "$package_name"
    else
        "$package_manager" install "$package_name"
    fi
}

print_install_command() {
    local package_manager=""
    local package_name="$1"

    # Check if the system is macOS and Homebrew is available
    if [ "$(uname -s)" = "Darwin" ] && [ -x "$(command -v brew)" ]; then
        package_manager="brew"
    else
        # Check for the package manager based on the Linux distribution
        case "$CURRENT_SYSTEM" in
            "Linux (ubuntu)" | "Linux (debian)")
                package_manager="apt-get"
                ;;
            "Linux (fedora)")
                package_manager="dnf"
                ;;
            "Linux (centos)" | "Linux (rhel)")
                package_manager="yum"
                ;;
            "Linux (arch)")
                package_manager="pacman"
                ;;
            *)
                echo "Unsupported distribution or macOS without Homebrew."
                exit 1
                ;;
        esac
    fi

    # Print the command that would be executed for package installation
    if [ "$package_manager" = "brew" ]; then
        echo "Command: brew install $package_name"
    else
        echo "Command: $package_manager install $package_name"
    fi
}

is_installed() {
    local package_name="$1"

    # Check if the binary is in the PATH
    if command -v "$package_name" >/dev/null 2>&1; then
        return 0
    fi

    # Check if the package is installed using the package manager
    local package_manager=""

    # Check if the system is macOS and Homebrew is available
    if [ "$(uname -s)" = "Darwin" ] && [ -x "$(command -v brew)" ]; then
        package_manager="brew"
    else
        # Check for the package manager based on the Linux distribution
        case "$CURRENT_SYSTEM" in
            "Linux (ubuntu)" | "Linux (debian)")
                package_manager="dpkg"
                ;;
            "Linux (fedora)")
                package_manager="rpm"
                ;;
            "Linux (centos)" | "Linux (rhel)")
                package_manager="rpm"
                ;;
            "Linux (arch)")
                package_manager="pacman"
                ;;
            *)
                exit 1
                ;;
        esac
    fi

    # Check if the package is installed using the determined package manager
    if [ "$package_manager" = "brew" ]; then
        if brew list --formula | grep -qFx "$package_name"; then
            echo "Package '$package_name' is already installed."
            return 0
        fi
    else
        if "$package_manager" -q list "$package_name" >/dev/null 2>&1; then
            echo "Package '$package_name' is already installed."
            return 0
        fi
    fi

    echo "Binary or package '$package_name' is not installed."
    return 1
}

# inst_zsh installs zsh depending on the os and distro
inst_zsh() {
    get_current_system

    case $CURRENT_SYSTEM in
        "Linux (ubuntu)"|"Linux (debian)")
            apt install zsh
            ;;
        "Linux (fedora)"|"Linux (rhel)")
            dnf install zsh
            ;;
        "Linux (arch)"|"Linux (manjaro)")
            pacman -S zsh
            ;;
        "Linux (opensuse)")
            zypper install zsh
            ;;
        "macOS")
            brew install zsh
            ;;
        "Windows")
            print_color "$RED_FG" "If you're using windows you should consider using WSL2 and retry."
            ;;
        *)
            print_color "$RED_FG" "It seems your running an OS we don't support, sorry buddy :("
            ;;
    esac
}

print_zsh_cmd() {
    case $CURRENT_SYSTEM in
        "Linux (ubuntu)"|"Linux (debian)")
            echo "apt install zsh"
            ;;
        "Linux (fedora)"|"Linux (rhel)")
            echo "dnf install zsh"
            ;;
        "Linux (arch)"|"Linux (manjaro)")
            echo "pacman -S zsh"
            ;;
        "Linux (opensuse)")
            echo "zypper install zsh"
            ;;
        "macOS")
            echo "brew install zsh"
            ;;
        "Windows")
            print_color "$RED_FG" "If you're using windows you should consider using WSL2 and retry."
            ;;
        *)
            print_color "$RED_FG" "It seems your running an OS we don't support, sorry buddy :("
            ;;
    esac
}

install_ohmyzsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

print_ohmyzsh_cmd() {
    echo "sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
}

# Main

# Perform general system checks
get_current_system
general_checks

# Welcome message
print_color "$BOLD$UNDERLINE" "Welcome to the setup script of thejezzi"
echo "This script tries to install everything you need to get going on a Linux"
echo "system (Zsh, Oh My Zsh, Neovim, completions, autosuggestions, ...)"

if ! is_installed "zsh"; then
    if confirmation "Should i try to install zsh? \n($(print_zsh_cmd "zsh"))"; then
        inst_zsh
    else
        MANUAL_INSTALL_LIST+=("zsh")
    fi
fi

# check if oh-my-zsh file config exists
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    if confirmation "Should i try to install ohmyzsh? \n($(print_ohmyzsh_cmd "ohmyzsh"))"; then
        install_ohmyzsh
    else
        MANUAL_INSTALL_LIST+=("ohmyzsh")
    fi
fi

# rust
if ! is_installed "rustup"; then
    if confirmation "Should i try to install rustup?
        \n(curl --proto '=https' --tlsv1.2 -sSf
        https://sh.rustup.rs | sh(print_rustup_cmd \"rustup\"))"; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    else
        MANUAL_INSTALL_LIST+=("rustup")
    fi
fi

# nodejs
if ! is_installed "node"; then
    if confirmation "Should i try to install nodejs? \n($(print_install_command "nodejs"))"; then
        echo "Huch"
    else
        MANUAL_INSTALL_LIST+=("nodejs")
    fi
fi

if ! is_installed "yarn" && is_installed "npm"; then
    if confirmation "Should i try to install yarn? \n(npm install --global yarn)"; then
        npm i -g yarn
    else
        MANUAL_INSTALL_LIST+=("yarn")
    fi
fi

if ! is_installed "yarn" && ! is_installed "npm"; then
    echo "If you have installed nodejs and want to install yarn make sure to
    reload the shell once and rerun this script and the option to install yarn
    should reveal itself :)"
fi

#------------------------------------------------------------------------------#
#----------------------------------Finished------------------------------------#
#------------------------------------------------------------------------------#

echo ""
print_color "$GREEN_FG$BOLD" "Done! you're good to go I guess :)"

# exit if manual list is emty
if [ ${#MANUAL_INSTALL_LIST[@]} -eq 0 ]; then
    exit 0
fi

echo -e "Now the only thing left is maybe to install the following packages manually:"
for i in "${MANUAL_INSTALL_LIST[@]}"
do
    echo -e "\t- $i"
done
