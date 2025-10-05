# Function to get date and log file
get_date_and_logfile() {
    param_logs_path=$1
    param_log_file_basename=$2

    local fecha=$(date +%Y%m%d)
    local logfile="${param_logs_path}/${param_log_file_basename}${fecha}.log"

    # Create logs directory if it doesn't exist
    mkdir -p "$(dirname "$logfile")"

    echo "$fecha $logfile"
}