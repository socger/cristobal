# Function to get date and log file
get_date_and_logfile() {
    param_logs_dir=$1
    param_log_file_basename=$2

    # LOGS_DIR="${LOGS_DIR:-/docker/logs}"
    # LOG_FILE_BASENAME="${LOG_FILE_BASENAME:-backup_with_docker_pause_}"

    local fecha=$(date +%Y%m%d)

    # local logfile="/docker/logs/backup_with_docker_pause_${fecha}.log"
    local logfile="${param_logs_dir}/${param_log_file_basename}${fecha}.log"

    # Create logs directory if it doesn't exist
    mkdir -p "$(dirname "$logfile")"

    echo "$fecha $logfile"
}