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
    echo -e "CONF PATH\t\t\t\tDOMAIN\t\t\t\t\tURL" >> "$LOG_FILE"
    grep -E "\bserver_name\b|\bproxy_pass\b" /etc/nginx/sites-enabled/* | awk '
    /server_name/ {file=$1; gsub(/:$/, "", file); domain=$3; gsub(/;$/, "", domain)}
    /proxy_pass/ {url=$3; gsub(/;$/, "", url); print file, domain, url}' | sort | uniq | column -t >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
    
    echo "$(date): Checks completed." >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    # Sleep for an hour before next check
    sleep 3600
done