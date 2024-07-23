#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 {-p|--port <port_number>} {-d|--docker <container_name>} {-n|--nginx <domain>} {-u|--users <username>} {-t|--time <date or range>} {-h|--help}"
    exit 1
}

# Function to display help
handle_help() {
    echo "This script monitors system events like User info and login time, Listening Ports, Docker containers|images information, Nginx domain configurations"
    echo ""
    echo "Usage:"
    echo "  $0 {-p|--port} {-d|--docker} {-n|--nginx} {-u|--users} {-t|--time <date or range>} [-h|--help]"
    echo ""
    echo "Options:"
    echo "  -p, --port       Monitor listening ports on the system. This will provide information on which ports are open and which services are using them."
    echo "  -d, --docker     Monitor Docker containers and images. This includes checking the status of containers and managing Docker images on your system."
    echo "  -n, --nginx      Monitor changes to Nginx domain configurations. This tracks modifications to the Nginx configuration files related to domain setups."
    echo "  -u, --users      Monitor user login events. This will display information about user logins, including timestamps and user details."
    echo "  -t, --time       Filter logs based on a specific date or date range. Use this option to view logs that fall within a particular time period. Format: 'YYYY-MM-DD' or 'YYYY-MM-DD YYYY-MM-DD'"
    echo "  -h, --help       Display this help message and exit. Provides an overview of all available options and their usage."
    echo ""
    echo "Examples:"
    echo "  $0 --port               Monitor all listening ports."
    echo "  $0 -d                   Check Docker containers and images."
    echo "  $0 --nginx              Track changes in Nginx domain configurations."
    echo "  $0 -u                   Review user login events."
    echo "  $0 --time '2024-07-18'  Filter logs to show entries for July 18, 2024."
    echo "  $0 --time '2024-07-18 2024-07-19' Filter logs to show entries between July 18, 2024 and July 19, 2024."
    echo ""

    echo "Detailed Usage:"
    echo "  $0 {-p|--port <port_name>} {-d|--docker <container_name|image_name>} {-n|--nginx <domain_name>} {-u|--users <username>} {-t|--time <date or range>} [-h|--help]"
    echo ""
    echo "Options with Detailed Usage:"
    echo "  -p, --port <port_name>       Monitor a specific listening port. Replace <port_name> with the actual port number or name to get detailed information about that port."
    echo "  -d, --docker <container_name|image_name>   Monitor a specific Docker container or image. Replace <container_name|image_name> with the actual name to check the status and details."
    echo "  -n, --nginx <domain_name>    Monitor Nginx domain configuration changes for a specific domain. Replace <domain_name> with the actual domain name to get details."
    echo "  -u, --users <username>       Monitor user login events for a specific user. Replace <username> with the actual username to review login details."
    echo "  -t, --time <date or range>   Filter logs by a specific date or range. Use 'YYYY-MM-DD' for a single day or 'YYYY-MM-DD YYYY-MM-DD' for a range."
    echo "  -h, --help                   Display this help message and exit. Provides an overview of available options and their usage."
    echo ""
    echo "Examples with Detailed Usage:"
    echo "  $0 --port 80                Monitor port 80 for details about its status."
    echo "  $0 -d my_container          Check the status and details of 'my_container'."
    echo "  $0 --nginx example.com      Track changes in Nginx configuration for 'example.com'."
    echo "  $0 -u alice                 Review login events for user 'alice'."
    echo "  $0 --time '2024-07-18'      Filter logs to show entries for July 18, 2024."
    echo "  $0 --time '2024-07-18 2024-07-19'  Filter logs to show entries between July 18, 2024 and July 19, 2024."
    echo ""
}

# Function to dislplay all users and their last login
handle_user() {
    echo "Displaying Users and their last login"
    lastlog | column -t
}

# Function to display detailed info about a user
handle_user_details() {
    local user="$1"
    echo "Displaying details for user: $user"
    finger "$user" | head -n -3

}

# Function to display listening ports
handle_port() {
    echo "Displaying Listening Ports"
    lsof -i -P -n | grep -E '^COMMAND|LISTEN'
}

# Function to display detailed info about a port
handle_port_details() {
    local port="$1"
    echo "Displaying details for port: $port"
    echo -e "SERVICE\t   PID    USER    TYPE\tNODE PORTS  STATE"
    lsof -i -n -P | awk 'NR>2 {print $1, $2, $3, $5, $8, $9, $10}' | grep ":$port" | column -t
}

# Function to display Nginx configured domains
handle_nginx() {
    echo "Displaying Nginx Configured Domains"
    # grep -E "\bserver_name\b|\bproxy_pass\b" /etc/nginx/sites-enabled/* | awk '
    # /server_name/ {file=$1; gsub(/:$/, "", file); domain=$3; gsub(/;$/, "", domain)}
    # /proxy_pass/ {url=$3; gsub(/;$/, "", url); print file, domain, url}' | sort | uniq | column -t
    COLUMN1_WIDTH=40
    COLUMN2_WIDTH=40

    # Print the header
    printf "%-${COLUMN1_WIDTH}s %-${COLUMN2_WIDTH}s %s\n" "Server Domain" "PROXY" "Configuration File"
    printf "%-${COLUMN1_WIDTH}s %-${COLUMN2_WIDTH}s %s\n" "-------------" "----------" "------------------"

    # Loop through configuration files and print details
    for file in /etc/nginx/sites-enabled/*; do
        server_name=$(grep -m 1 'server_name' "$file" | awk '{print $2}' | sed 's/;//')
        proxy_pass=$(grep -m 1 'proxy_pass' "$file" | awk '{print $2}' | sed 's/;//')
        printf "%-${COLUMN1_WIDTH}s %-${COLUMN2_WIDTH}s %s\n" "$server_name" "$proxy_pass" "$file"
    done

}

# Function to Provide detailed configuration information for a specific domain
handle_nginx_details() {
    local domain="$1"
    echo "Displaying details for domain: $domain"

    # Extracting relevant lines from nginx.conf
    # grep -E -A 8 "\b$domain\b" /etc/nginx/nginx.conf | awk 'NR>2 {print $2, $3, $4}'
    grep -E -A 8 "\b$domain\b" /etc/nginx/sites-enabled/* | awk 'NR>2 {print $2, $3, $4}'
}

# Function to display Docker containers and images
handle_docker() {
    echo "Displaying Docker Containers and Images"
    echo -e "CONTAINER ID\tIMAGE\t\t\t      STATUS  CREATED\t    PORTS\t\tNAME"
    docker ps -a | awk 'NR>1 {print $1, $2, $7, $8, $9, $10, $12}' | column -t
}

# Function to display detailed information about a Docker container or image
handle_docker_details() {
    local container_or_image="$1"
    echo "Displaying details for $container_or_image"
    docker inspect prod-next-prod-frontend-2-1 | jq '.[] | {Name: .Name, State: .State, Config: .Config}'
}

# Function to display system logs based on a specific date or date range
handle_time() {
    local start_date="$1"
    local end_date="$2"

    if [ -z "$end_date" ]; then
        echo "Displaying system information for $start_date"
        journalctl --since "$start_date 00:00:00" --until "$start_date 23:59:59" | less
    else
        echo "Displaying system information from $start_date to $end_date"
        journalctl --since "$start_date 00:00:00" --until "$end_date 23:59:59" | less
    fi
}


# Check if the script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Please run again with sudo or as root user."
    exit 1
fi

# Main script    
case "$1" in
    -u|--user)
        if [ -z "$2" ]; then
            handle_user
        else
            handle_user_details "$2"
        fi
    ;;
    -p|--port)
        if [ -z "$2" ]; then
            handle_port
        else
            handle_port_details "$2"
        fi
    ;;
    -n|--nginx)
        if [ -z "$2" ]; then
            handle_nginx
        else
            handle_nginx_details "$2"
        fi
    ;;
    -d|--docker)
        if [ -z "$2" ]; then
            handle_docker
        else
            handle_docker_details "$2"
        fi
    ;;
    -t|--time)
        if [ -z "$2" ]; then
            echo "Required: date (YYYY-MM-DD) or date range (YYYY-MM-DD YYYY-MM-DD). Use -h|--help to see valid arguements"
        else
            handle_time "$2" "$3"
        fi
    ;;
    -h|--help)
        handle_help
    ;;
    *)
        echo "Invalid option: $1"
        usage
    ;;
esac