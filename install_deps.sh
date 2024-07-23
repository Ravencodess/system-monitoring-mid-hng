#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package
install_package() {
    if ! command_exists "$1"; then
        echo "Installing $1..."
        sudo apt-get install -y "$1"
    else
        echo "$1 is already installed."
    fi
}

# Check if script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Please run again with sudo or as root user."
    exit 1
fi

# Update package lists
echo "Updating package lists..."
apt-get update

# Install necessary packages
install_package "lsof"
install_package "nginx"
install_package "docker.io"
install_package "jq"
install_package "finger"

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Enable and start Nginx service
systemctl enable nginx
systemctl start nginx

echo "All necessary dependencies have been installed and services started."
echo "You can now run the main script."