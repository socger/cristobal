# Function to mount the USB backup device
montar_hd() {
    local mount_disk_usb=$1
    local disk_usb=$2
    local logfile=$3

    # Mount the USB backup device
    if mount | grep "$mount_disk_usb" > /dev/null; then
        msg "[$(date)] Dispositivo ya montado en $mount_disk_usb" "$logfile"
        return 0
    else
        # Intentar montaje con NTFS primero (más probable en USB)
        if mount -t ntfs-3g "$disk_usb" "$mount_disk_usb" 2>/dev/null; then
            msg "[$(date)] Dispositivo USB montado correctamente (NTFS)." "$logfile"
            return 0
        elif mount "$disk_usb" "$mount_disk_usb" 2>/dev/null; then
            msg "[$(date)] Dispositivo USB montado correctamente." "$logfile"
            return 0
        else
            msg "[$(date)] Error: No se pudo montar $disk_usb" "$logfile"
            msg "[$(date)] Intentando reparar el sistema de archivos..." "$logfile"

            # Intentar reparación automática
            if command -v ntfsfix >/dev/null 2>&1; then
                ntfsfix "$disk_usb" >> "$logfile" 2>&1
                # Reintentar montaje después de la reparación
                if mount -t ntfs-3g "$disk_usb" "$mount_disk_usb" 2>/dev/null; then
                    msg "[$(date)] Dispositivo USB reparado y montado correctamente." "$logfile"
                    return 0
                else
                    msg "[$(date)] Error: No se pudo montar $disk_usb incluso después de la reparación" "$logfile"
                    return 1
                fi
            else
                msg "[$(date)] ntfsfix no disponible. No se pudo reparar automáticamente." "$logfile"
                return 1
            fi
        fi
    fi
}
