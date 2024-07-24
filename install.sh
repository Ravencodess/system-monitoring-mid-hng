#!/bin/bash

# System Monitor Installation Script
# Version 1.0

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Set variables
LOGFILE="/var/log/system_monitor.log"
DEVOPSFETCH_SCRIPT="/usr/local/bin/devopsfetch"
MONITOR_SCRIPT="/usr/local/bin/system_monitor"
SERVICE_FILE="/etc/systemd/system/system_monitor.service"
INSTALL_LOG="/var/log/system_monitor_install.log"

# Array of packages to install
PACKAGES=("lsof" "nginx" "docker.io" "jq" "finger")

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$INSTALL_LOG"
    echo "$1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package
install_package() {
    if ! command_exists "$1"; then
        log_message "Installing $1..."
        sudo apt-get install -y "$1" >> "$INSTALL_LOG" 2>&1
    else
        log_message "$1 is already installed."
    fi
}

# Function to set up files and permissions
setup_files() {
    touch "$LOGFILE"
    chmod 644 "$LOGFILE"

    cp devopsfetch.sh "$DEVOPSFETCH_SCRIPT"
    chmod +x "$DEVOPSFETCH_SCRIPT"

    cp system_monitor.sh "$MONITOR_SCRIPT"
    chmod +x "$MONITOR_SCRIPT"
}

# Function to create service file
create_service_file() {
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=System Monitoring Service
After=network.target

[Service]
ExecStart=$MONITOR_SCRIPT
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF
}

# Function to set up log rotation
setup_log_rotation() {
    cat << EOF > /etc/logrotate.d/system-monitor
/var/log/system_monitor.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
EOF
    chmod 644 /etc/logrotate.d/system-monitor
}

# Main installation process
log_message "Starting installation process..."

# Update package lists
log_message "Updating package lists..."
apt-get update >> "$INSTALL_LOG" 2>&1

# Install necessary packages
for package in "${PACKAGES[@]}"; do
    install_package "$package"
done

# Enable and start services
log_message "Enabling and starting Docker service..."
systemctl enable docker >> "$INSTALL_LOG" 2>&1
systemctl start docker >> "$INSTALL_LOG" 2>&1

log_message "Enabling and starting Nginx service..."
systemctl enable nginx >> "$INSTALL_LOG" 2>&1
systemctl start nginx >> "$INSTALL_LOG" 2>&1

# Set up files and permissions
log_message "Setting up files and permissions..."
setup_files

# Create service file
log_message "Creating service file..."
create_service_file

# Set up log rotation
log_message "Setting up log rotation..."
setup_log_rotation

# Reload systemd, enable and start the monitoring service
log_message "Enabling and starting monitoring service..."
systemctl daemon-reload >> "$INSTALL_LOG" 2>&1
systemctl enable system_monitor.service >> "$INSTALL_LOG" 2>&1
systemctl start system_monitor.service >> "$INSTALL_LOG" 2>&1

# Check if service is running
if systemctl is-active --quiet system_monitor.service; then
    log_message "Installation successful. System monitoring service is active and running."
    log_message "You can now use 'devopsfetch -h' from anywhere in the system."
else
    log_message "Installation completed, but the service failed to start. Please check the logs."
fi

log_message "Installation process completed."
