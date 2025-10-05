# Método auxiliar para eliminar archivos por patrón/tipo de nombre de los ficheros a borrar
delete_files() {
    local param_path=$1
    local param_files_to_delete=$2
    local param_cantidad_dias=$3
    local param_log_file=$4

    local fecha_limite=$(date -d "-$param_cantidad_dias days" +%Y%m%d)

    for file in "$param_path"/$param_files_to_delete; do
        # Verificar que el archivo existe (evitar problemas si no hay coincidencias)
        if [ ! -f "$file" ]; then
            continue
        fi

        local filename=$(basename "$file")
        local fecha_archivo=$(echo "$filename" | grep -oP '\d{8}')

        if [[ "$fecha_archivo" =~ ^[0-9]{8}$ ]] && [[ "$fecha_archivo" -le "$fecha_limite" ]]; then
            msg "[$(date)] Deleting old file: $file" "$param_log_file"
            rm "$file"
        fi
    done
}

# Borrado de logs antiguos
delete_logs() {
    local param_cantidad_dias=$1
    if [ -z "$param_cantidad_dias" ]; then
        param_cantidad_dias=2
    fi

    local param_logs_to_delete_1="$2*.log"
    local param_logs_to_delete_2="$2*.log.rclone"

    local param_log_file="$3"
    local param_path="$4"

    delete_files "$param_path" "$param_logs_to_delete_1" "$param_cantidad_dias" "$param_log_file"
    delete_files "$param_path" "$param_logs_to_delete_2" "$param_cantidad_dias" "$param_log_file"
}

# Borrado de backups antiguos
delete_backups() {
    local param_cantidad_dias=$1
    if [ -z "$param_cantidad_dias" ]; then
        param_cantidad_dias=7
    fi

    local param_backups_to_delete="$2*.tar.gz"
    local param_log_file="$3"
    local param_path="$4"

    delete_files "$param_path" "$param_backups_to_delete" "$param_cantidad_dias" "$param_log_file"
}
