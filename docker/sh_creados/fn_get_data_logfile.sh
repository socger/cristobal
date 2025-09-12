# Function to get date and log file
get_date_and_logfile() {
    local fecha=$(date +%Y%m%d)
    local logfile="/docker/logs/backup_with_docker_pause_${fecha}.log"

    # Create logs directory if it doesn't exist
    mkdir -p "$(dirname "$logfile")"

    echo "$fecha $logfile"
}