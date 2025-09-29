# Función para cargar configuración del sistema de backup
load_backup_config() {
    local env_file="${1:-.env}"

    # Cargar configuración desde .env si existe
    if [ -f "$env_file" ]; then
        source "$env_file"
        echo "✅ Configuración cargada desde $env_file"
    fi

    # Valores por defecto si no se cargaron desde .env
    export SOURCE_DIR="${SOURCE_DIR:-/docker}"
    export LOGS_DIR="${LOGS_DIR:-/docker/logs}"
    export LOG_FILE_BASENAME="${LOG_FILE_BASENAME:-backup_with_docker_pause_}"

    # Variables adicionales con valores por defecto
    export DISK_USB="${DISK_USB:-/dev/sdb1}"
    export MOUNT_DISK_USB="${MOUNT_DISK_USB:-/mnt/mount_disk_usb}"

    export MYSQL_USER="${MYSQL_USER:-root}"
    export MYSQL_PASSWORD="${MYSQL_PASSWORD:-sasa}"

    export BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
    export LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-2}"

    export GDRIVE_REMOTE="${GDRIVE_REMOTE:-gNube:}"
    export GDRIVE_BACKUP_DIR="${GDRIVE_BACKUP_DIR:-backups}"

    # === DEBUG ===
    export DEBUG_CONFIG="${DEBUG_CONFIG:-false}"

    # Mostrar configuración cargada (opcional)
    if [ "${DEBUG_CONFIG:-false}" = "true" ]; then
        echo "📋 Configuración cargada:"

        echo "  - SOURCE_DIR: $SOURCE_DIR"
        echo "  - LOGS_DIR: $LOGS_DIR"
        echo "  - LOG_FILE_BASENAME: $LOG_FILE_BASENAME"

        echo "  - DISK_USB: $DISK_USB"
        echo "  - MOUNT_DISK_USB: $MOUNT_DISK_USB"

        echo "  - MYSQL_USER: $MYSQL_USER"
        echo "  - MYSQL_PASSWORD: $MYSQL_PASSWORD"

        echo "  - BACKUP_RETENTION_DAYS: $BACKUP_RETENTION_DAYS"
        echo "  - LOG_RETENTION_DAYS: $LOG_RETENTION_DAYS"

        echo "  - GDRIVE_REMOTE: $GDRIVE_REMOTE"
        echo "  - GDRIVE_BACKUP_DIR: $GDRIVE_BACKUP_DIR"

        echo "  - DEBUG_CONFIG: $DEBUG_CONFIG"
    fi

    return 0
}
