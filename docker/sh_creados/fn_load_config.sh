# Función para cargar configuración del sistema de backup
load_backup_config() {
    local env_file="${1:-.env}"
    
    # Cargar configuración desde .env si existe
    if [ -f "$env_file" ]; then
        source "$env_file"
        echo "✅ Configuración cargada desde $env_file"
    fi

    # Valores por defecto si no se cargaron desde .env
    export LOGS_DIR="${LOGS_DIR:-/docker/logs}"
    export SCRIPTS_DIR="${SCRIPTS_DIR:-/docker/sh_creados}"
    export SOURCE_DIR="${SOURCE_DIR:-/docker}"
    export LOG_FILE_BASENAME="${LOG_FILE_BASENAME:-backup_with_docker_pause_}"
    
    # Variables adicionales con valores por defecto
    export DISK_USB="${DISK_USB:-/dev/sdb1}"
    export MOUNT_DISK_USB="${MOUNT_DISK_USB:-/mnt/mount_disk_usb}"
    export MYSQL_USER="${MYSQL_USER:-root}"
    export MYSQL_PASSWORD="${MYSQL_PASSWORD:-sasa}"
    export BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
    export LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-2}"
    
    # Mostrar configuración cargada (opcional)
    if [ "${DEBUG_CONFIG:-false}" = "true" ]; then
        echo "📋 Configuración cargada:"
        echo "  - LOGS_DIR: $LOGS_DIR"
        echo "  - SCRIPTS_DIR: $SCRIPTS_DIR"
        echo "  - SOURCE_DIR: $SOURCE_DIR"
        echo "  - DISK_USB: $DISK_USB"
        echo "  - MOUNT_DISK_USB: $MOUNT_DISK_USB"
    fi
    
    # Cambiar al directorio de scripts
    if [ -d "$SCRIPTS_DIR" ]; then
        cd "$SCRIPTS_DIR"
        echo "📁 Cambiado al directorio: $SCRIPTS_DIR"
    else
        echo "❌ Error: Directorio de scripts no encontrado: $SCRIPTS_DIR"
        return 1
    fi
    
    return 0
}
