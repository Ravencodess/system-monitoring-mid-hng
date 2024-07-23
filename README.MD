# System Monitoring Tool

This project provides a comprehensive system monitoring tool that tracks user logins, listening ports, Docker containers, and Nginx configurations. It includes scripts for installing dependencies, running the monitoring tool, and setting up a system service for continuous monitoring.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Continuous Monitoring](#continuous-monitoring)
5. [Log Management](#log-management)

## Prerequisites

- A Linux-based system (Ubuntu/Debian recommended)
- Root or sudo access

## Installation

1. Clone this repository or download the scripts to your local machine.

2. Make the installation script executable:

```
   chmod +x install_deps.sh
```

3. Run the installation script with sudo privileges:

```
   sudo ./install_deps.sh
```

This script will:

- Update package lists
- Install necessary packages (lsof, nginx, docker.io, jq, finger)
- Enable and start Docker and Nginx services

## Usage

The main monitoring script (`devopsfetch.sh`) provides various options to check different aspects of your system.

1. Make the script executable:

```
   chmod +x devopsfetch.sh
```

2. Run the script with sudo privileges:

```
   sudo ./devopsfetch.sh [OPTION] [ARGUMENT]
```

Available options:

- `-u, --user [username]`: Display user login information
- `-p, --port [port_number]`: Show listening ports
- `-d, --docker [container_name]`: Display Docker containers and images
- `-n, --nginx [domain]`: Show Nginx configured domains
- `-t, --time [date or range]`: Filter logs by date
- `-h, --help`: Display help information

Examples:

```
   sudo ./devopsfetch.sh --port                # Show all listening ports
   sudo ./devopsfetch.sh -d my_container       # Check details of 'my_container'
   sudo ./devopsfetch.sh --nginx example.com   # Show Nginx config for 'example.com'
   sudo ./devopsfetch.sh -u alice              # Show login events for user 'alice'
   sudo ./devopsfetch.sh -t '2024-07-18'       # Show logs for July 18, 2024
```

## Continuous Monitoring

The project includes a script (`system_monitor.sh`) for continuous monitoring that can be set up as a system service.

1. Make the continuous monitoring script executable:

```
   chmod +x system_monitor.sh
```

2. Create a systemd service file:

```
   sudo vim /etc/systemd/system/system-monitor.service
```

3. Add the following content to the service file:

```
   [Unit]
   Description=System Monitoring Service
   After=network.target

   [Service]
   ExecStart=/path/to/system_monitor.sh
   Restart=always
   User=root

   [Install]
   WantedBy=multi-user.target
```

Replace `/path/to/system_monitor.sh` with the actual path to the script.

4. Save and close the file.

5. Reload the systemd daemon:

```
   sudo systemctl daemon-reload
```

6. Start the service:

```
   sudo systemctl start system-monitor
```

7. Enable the service to start on boot:

```
   sudo systemctl enable system-monitor
```

## Log Management

The continuous monitoring script logs all activities to `/var/log/system_monitor.log`.

1. To view the logs in real-time:

```
   sudo tail -f /var/log/system_monitor.log
```

2. Set up log rotation by creating a new configuration file:

```
   sudo vim /etc/logrotate.d/system-monitor
```

3. Add the following content:

```
   /var/log/system_monitor.log {
       daily
       rotate 7
       compress
       delaycompress
       missingok
       notifempty
       create 0640 root adm
   }
```

This configuration rotates logs daily, keeps 7 days of logs, and compresses old logs.

The system monitoring tool is now set up to continuously monitor your system and manage logs efficiently. You can use the main script for on-demand checks and rely on the system service for ongoing monitoring.
