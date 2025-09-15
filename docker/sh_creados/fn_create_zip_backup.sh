# Function to create the new backup zip file
create_zip_backup() {
    local param_mount_disk_usb=$1
    local param_disk_usb=$2
    local param_logfile=$3
    local param_source_dir=$4
    local param_dest_dir=$5
    local param_backup_file=$6
    local param_stacks=$7

    msg ". " "$param_logfile"
    msg "[$(date)] Haciendo copia de seguridad de $param_source_dir a $param_backup_file ..." "$param_logfile"
    msg ". " "$param_logfile"

    # Crear la copia de seguridad
    msg "[$(date)] Iniciando compresión de archivos (progreso visible)..." "$param_logfile"
    msg "[$(date)] Fase 1: Copiando archivos principales (excluyendo logs)..." "$param_logfile"

    # CAMBIO: Crear archivo .tar SIN comprimir primero
    file_tar="$param_dest_dir/backup_$(date +%Y%m%d_%H%M%S).tar"

    tar -cvf "$file_tar" -C "$(dirname "$param_source_dir")" \
        --exclude="docker/logs" \
        --exclude="docker/logs/*" \
        "$(basename "$param_source_dir")" \
        2>&1 | tee -a "$param_logfile"

    # Capturar el código de salida del tar (no del tee)
    tar_exit_code=${PIPESTATUS[0]}

    if [ $tar_exit_code -eq 0 ]; then
        msg "[$(date)] ✅ Fase 1 completada: Archivos principales copiados" "$param_logfile"

        # Fase 2: Añadir los logs al archivo .tar
        msg "[$(date)] Fase 2: Añadiendo logs al backup..." "$param_logfile"

        tar -rvf "$file_tar" -C "$(dirname "$param_source_dir")" "docker/logs" >/dev/null 2>&1
        tar_logs_exit_code=$?

        if [ $tar_logs_exit_code -eq 0 ]; then
            msg "[$(date)] ✅ Fase 2 completada: Logs añadidos al backup" "$param_logfile"
        else
            msg "[$(date)] ⚠️ Warning: Error al añadir logs (código: $tar_logs_exit_code)" "$param_logfile"
            msg "[$(date)] ✅ Backup principal completado, continuando sin logs..." "$param_logfile"
        fi

        # Fase 3: Comprimir el archivo final
        msg "[$(date)] Fase 3: Comprimiendo archivo final..." "$param_logfile"

        if gzip "$file_tar"; then
            # gzip automáticamente renombra .tar a .tar.gz Y elimina el .tar original
            msg "[$(date)] ✅ Archivo comprimido exitosamente" "$param_logfile"
            msg "[$(date)] ✅ Copia de seguridad creada exitosamente en $param_backup_file" "$param_logfile"

            # NUEVA FUNCIÓN: Subir a Google Drive
            upload_to_gdrive "$param_backup_file" "$param_logfile"
        else
            msg "[$(date)] ❌ Error al comprimir el archivo .tar" "$param_logfile"
            msg "[$(date)] 🧹 Eliminando archivo .tar temporal..." "$param_logfile"
            rm -f "$file_tar"

            # Levantamos los stacks, contenedores y sus servicios
            scale_stacks "$param_stacks" 1 "$param_logfile"

            # Desmontamos el dispositivo usb de copias 
            desmontar_hd "$param_mount_disk_usb" "$param_disk_usb" "$param_logfile"

            exit 1
        fi

    else
        msg "[$(date)] ❌ Error al crear la copia de seguridad (código: $tar_exit_code)" "$param_logfile"

        # Limpiar archivo temporal si existe
        if [ -f "$file_tar" ]; then
            msg "[$(date)] 🧹 Eliminando archivo .tar temporal..." "$param_logfile"
            rm -f "$file_tar"
        fi

        # Levantamos los stacks, contenedores y sus servicios
        scale_stacks "$param_stacks" 1 "$param_logfile"

        # Desmontamos el dispositivo usb de copias 
        desmontar_hd "$param_mount_disk_usb" "$param_disk_usb" "$param_logfile"

        exit 1
    fi

    # Esperar a que termine la copia
    sync
}
