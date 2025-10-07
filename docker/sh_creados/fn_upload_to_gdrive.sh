# Function to upload backup to Google Drive using rclone
upload_to_gdrive() {
    local param_backup_file=$1
    local param_logfile=$2

    nube="gNube:"
    nube_path="${nube}backups/"

    msg "[$(date)] 📤 Iniciando subida a Google Drive..." "$param_logfile"

    if command -v rclone >/dev/null 2>&1; then
        # Verificar que el archivo existe
        if [ ! -f "$param_backup_file" ]; then
            msg "[$(date)] ❌ Archivo de backup no encontrado: $param_backup_file" "$param_logfile"
            return 1
        fi

        msg "[$(date)] 📊 Información del archivo a subir:" "$param_logfile"
        ls -lh "$param_backup_file" >> "$param_logfile" 2>&1

        # Verificar conectividad con Google Drive
        msg "[$(date)] 🔍 Verificando conectividad con Google Drive..." "$param_logfile"
        if ! rclone lsd "$nube" >/dev/null 2>&1; then
            msg "[$(date)] ❌ No se puede conectar a Google Drive. Verifica la configuración de rclone." "$param_logfile"
            msg "[$(date)] 🔍 Listando configuraciones disponibles:" "$param_logfile"
            rclone listremotes >> "$param_logfile" 2>&1
            return 1
        fi

        # Verificar/crear directorio de backups
        msg "[$(date)] 📁 Verificando directorio de backups en Google Drive..." "$param_logfile"
        rclone mkdir "${nube}backups/" 2>>"$param_logfile"

        # Listar contenido actual del directorio antes de subir
        msg "[$(date)] 📋 Contenido actual en Google Drive antes de subir:" "$param_logfile"
        rclone ls "${nube}backups/" >> "$param_logfile" 2>&1

        # Subir archivo a Google Drive
        msg "[$(date)] 📤 Subiendo $(basename "$param_backup_file") a Google Drive..." "$param_logfile"
        msg "          Comando que vamos a usar:" "$param_logfile"
        msg "          rclone copy \"$param_backup_file\" \"${nube}backups/\" --progress --log-file=\"$param_logfile.rclone\" --log-level INFO" "$param_logfile"

        # CAMBIO PRINCIPAL: Usar la ruta completa en lugar de variable
        if rclone copy "$param_backup_file" "${nube}backups/" --progress --log-file="$param_logfile.rclone" --log-level INFO; then
            # VERIFICACIÓN CRÍTICA: Comprobar que realmente se subió
            msg "[$(date)] 🔍 Verificando que el archivo se subió correctamente..." "$param_logfile"
            local uploaded_file=$(basename "$param_backup_file")

            if rclone ls "${nube}backups/" | grep -q "$uploaded_file"; then
                msg "[$(date)] ✅ Backup subido y verificado exitosamente en Google Drive" "$param_logfile"

                # Mostrar contenido actualizado
                msg "[$(date)] 📋 Contenido actual en Google Drive después de subir:" "$param_logfile"
                rclone ls "${nube}backups/" >> "$param_logfile" 2>&1

                # Limpiar backups antiguos en Drive
                msg "[$(date)] 🧹 Limpiando backups antiguos en Google Drive (>7 días) - Eliminación permanente..." "$param_logfile"
                
                # Listar archivos que se van a eliminar (para log)
                msg "[$(date)] 📋 Archivos que se eliminarán:" "$param_logfile"
                rclone ls "${nube}backups/" --min-age ${BACKUP_RETENTION_DAYS:-7}d >> "$param_logfile" 2>&1
                
                if [ "${GDRIVE_PERMANENT_DELETE:-true}" = "true" ]; then
                    msg "[$(date)] ⚠️ Eliminación PERMANENTE activada (sin papelera)" "$param_logfile"
                    if rclone delete "${nube}backups/" --min-age ${BACKUP_RETENTION_DAYS:-7}d --drive-use-trash=false --log-file="$param_logfile.rclone" --log-level INFO; then
                        msg "[$(date)] ✅ Archivos antiguos eliminados permanentemente" "$param_logfile"
                    else
                        msg "[$(date)] ⚠️ Error al eliminar archivos antiguos" "$param_logfile"
                    fi
                else
                    msg "[$(date)] ℹ️ Eliminación con papelera (requerirá limpieza manual)" "$param_logfile"
                    if rclone delete "${nube}backups/" --min-age ${BACKUP_RETENTION_DAYS:-7}d --log-file="$param_logfile.rclone" --log-level INFO; then
                        msg "[$(date)] ✅ Archivos antiguos enviados a la papelera" "$param_logfile"
                    else
                        msg "[$(date)] ⚠️ Error al enviar archivos a la papelera" "$param_logfile"
                    fi
                fi

                # Opcional: Limpiar papelera por si había archivos anteriores
                msg "[$(date)] 🗑️ Limpiando papelera de Google Drive..." "$param_logfile"
                rclone cleanup "${nube}" --log-file="$param_logfile.rclone" --log-level INFO 2>/dev/null

                # Mostrar espacio liberado
                msg "[$(date)] 📊 Contenido final en Google Drive:" "$param_logfile"
                rclone ls "${nube}backups/" >> "$param_logfile" 2>&1

                return 0
            else
                msg "[$(date)] ❌ FALLO: El archivo NO está en Google Drive después del comando copy" "$param_logfile"
                msg "[$(date)] 🔍 Contenido actual en Google Drive:" "$param_logfile"
                rclone ls "${nube}backups/" >> "$param_logfile" 2>&1
                return 1
            fi
        else
            msg "[$(date)] ❌ Error al ejecutar comando rclone copy. Ver log: $param_logfile.rclone" "$param_logfile"
            return 1
        fi
    else
        msg "[$(date)] ⚠️ rclone no está instalado. Saltando subida a Google Drive." "$param_logfile"
        return 1
    fi
}