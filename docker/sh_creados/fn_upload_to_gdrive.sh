# Function to upload backup to Google Drive using rclone
upload_to_gdrive() {
    local param_backup_file=$1
    local param_logfile=$2

    nube="gNube:"
    nube_path='"$nube"backups/'

    msg "[$(date)] 📤 Iniciando subida a Google Drive..." "$param_logfile"

    if command -v rclone >/dev/null 2>&1; then
        # Verificar que el archivo existe
        if [ ! -f "$param_backup_file" ]; then
            msg "[$(date)] ❌ Archivo de backup no encontrado: $param_backup_file" "$param_logfile"
            return 1
        fi

        # Verificar conectividad con Google Drive
        if ! rclone lsd "$nube" >/dev/null 2>&1; then
            msg "[$(date)] ❌ No se puede conectar a Google Drive. Verifica la configuración de rclone." "$param_logfile"
            return 1
        fi

        # Crear directorio de backups si no existe
        rclone mkdir "$nube_path" 2>/dev/null

        # Subir archivo a Google Drive
        msg "[$(date)] 📤 Subiendo $(basename "$param_backup_file") a Google Drive..." "$param_logfile"

        if rclone copy "$param_backup_file" "$nube_path" --progress --log-file="$param_logfile.rclone" --log-level INFO; then
            msg "[$(date)] ✅ Backup subido exitosamente a Google Drive: $nube_path" "$param_logfile"

            # Limpiar backups antiguos en Drive (mantener últimos 7 días)
            msg "[$(date)] 🧹 Limpiando backups antiguos en Google Drive (>7 días)..." "$param_logfile"
            rclone delete "$nube_path" --min-age 7d --log-file="$param_logfile.rclone" --log-level INFO

            return 0
        else
            msg "[$(date)] ❌ Error al subir backup a Google Drive. Ver log: $param_logfile.rclone" "$param_logfile"
            return 1
        fi
    else
        msg "[$(date)] ⚠️ rclone no está instalado. Saltando subida a Google Drive." "$param_logfile"
        return 1
    fi
}

