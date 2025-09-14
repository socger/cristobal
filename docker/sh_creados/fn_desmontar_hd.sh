# Function to unmount the USB backup device
desmontar_hd() {
    local mount_disk_usb=$1
    local disk_usb=$2
    local logfile=$2

    # Unmount the USB backup device
    umount "$mount_disk_usb"

    if [ $? -ne 0 ]; then
        msg "[$(date)] Error: No se pudo desmontar $mount_disk_usb" "$logfile"
        msg "Vamos a obligar su desmontaje con el comando ... sudo umount '$disk_usb'" "$logfile"
        sudo umount "$disk_usb"
    fi

    msg "[$(date)] Dispositivo USB desmontado correctamente." "$logfile"
}
