#!/bin/bash

LOG_FILE="/var/log/system_monitor.log"
LOG_DIR="/var/log"

mkdir -p "$LOG_DIR"

while true; do
    echo "----------------------------------------" >> "$LOG_FILE"
    echo "$(date): Running system checks..." >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    
    # User monitoring
    echo "User login information:" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    lastlog | column -t >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
    
    # Port monitoring
    echo "Listening ports:" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    lsof -i -P -n | grep -E '^COMMAND|LISTEN' >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
    
    # Docker monitoring
    echo "Docker containers:" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo -e "CONTAINER ID\tIMAGE\t\t\t      STATUS  CREATED\t    PORTS\t\tNAME" >> "$LOG_FILE"
    docker ps -a | awk 'NR>1 {print $1, $2, $7, $8, $9, $10, $12}' | column -t >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
    
    # Nginx monitoring
    echo "Nginx configured domains:" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    COLUMN1_WIDTH=40
    COLUMN2_WIDTH=40

    # Print the header
    printf "%-${COLUMN1_WIDTH}s %-${COLUMN2_WIDTH}s %s\n" "Server Domain" "PROXY" "Configuration File" >> "$LOG_FILE"
    printf "%-${COLUMN1_WIDTH}s %-${COLUMN2_WIDTH}s %s\n" "-------------" "----------" "------------------" >> "$LOG_FILE"

    # Loop through configuration files and print details
    for file in /etc/nginx/sites-enabled/*; do
        server_name=$(grep -m 1 'server_name' "$file" | awk '{print $2}' | sed 's/;//')
        proxy_pass=$(grep -m 1 'proxy_pass' "$file" | awk '{print $2}' | sed 's/;//')
        printf "%-${COLUMN1_WIDTH}s %-${COLUMN2_WIDTH}s %s\n" "$server_name" "$proxy_pass" "$file" >> "$LOG_FILE"
    done
    echo "----------------------------------------" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
    
    echo "$(date): Checks completed." >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    # Sleep for an hour before next check
    sleep 3600
done