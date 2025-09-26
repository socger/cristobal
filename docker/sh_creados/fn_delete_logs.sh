# Método auxiliar para eliminar archivos de log por patrón
delete_log_files_by_pattern() {
    local logs_dir=$1
    local pattern=$2
    local fecha_limite=$3
    local logfile=$4
    
    for file in "$logs_dir"/$pattern; do
        # Verificar que el archivo existe (evitar problemas si no hay coincidencias)
        if [ ! -f "$file" ]; then
            continue
        fi
        
        filename=$(basename "$file")
        fecha_archivo=$(echo "$filename" | grep -oP '\d{8}')

        if [[ "$fecha_archivo" =~ ^[0-9]{8}$ ]] && [[ "$fecha_archivo" -le "$fecha_limite" ]]; then
            msg "[$(date)] Borrando log antiguo: $file" "$logfile"
            rm "$file"
        fi
    done
}

# Método principal modificado
delete_logs() {
    local param_cantidad_dias=$1

    local param_logs_to_delete_1="$2*.log"
    local param_logs_to_delete_2="$2*.log.rclone"

    local param_log_file="$3"
    
    if [ -z "$param_cantidad_dias" ]; then
        param_cantidad_dias=2
    fi

    param_fecha_limite=$(date -d "-$param_cantidad_dias days" +%Y%m%d)

    # Usar variable de configuración
    local logs_dir="${LOGS_DIR:-/docker/logs}"
    
    # Llamar al método auxiliar con el patrón como parámetro
    delete_log_files_by_pattern "$logs_dir" "$param_logs_to_delete_1" "$param_fecha_limite" "$LOGFILE"
    delete_log_files_by_pattern "$logs_dir" "$param_logs_to_delete_2" "$param_fecha_limite" "$param_log_file"
}