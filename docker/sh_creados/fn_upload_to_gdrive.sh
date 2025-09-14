# Function to upload backup to Google Drive using rclone
upload_to_gdrive() {
    local backup_file=$1
    local logfile=$2

    local remote_path="backups/$(basename "$backup_file")"

    msg "[$(date)] 📤 Iniciando subida a Google Drive..." "$logfile"

    if command -v rclone >/dev/null 2>&1; then
        # Subir archivo a Google Drive
        if rclone copy "$backup_file" gdrive:backups/ --progress; then
            msg "[$(date)] ✅ Backup subido exitosamente a Google Drive: $remote_path" "$logfile"

            # Eliminar backups antiguos en Drive (mantener solo últimos 7 días)
            msg "[$(date)] 🧹 Limpiando backups antiguos en Google Drive..." "$logfile"
            rclone delete gdrive:backups/ --min-age 7d --dry-run
            rclone delete gdrive:backups/ --min-age 7d

            return 0
        else
            msg "[$(date)] ❌ Error al subir backup a Google Drive" "$logfile"
            return 1
        fi
    else
        msg "[$(date)] ⚠️ rclone no está instalado. No realizaremos la subida a Google Drive." "$logfile"
        return 1
    fi
}
