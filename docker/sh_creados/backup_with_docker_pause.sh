#!/bin/bash

# Cargamos función para imprimir mensajes en logs y terminal
source fn_msg.sh

# Cargamos funciones para escalar servicios de stacks
source fn_scale_stacks.sh
source fn_scale_services.sh

# Cargamos función para obtener fecha y archivo de log
source fn_get_data_logfile.sh

# Load function to unmount the USB backup device
source fn_desmontar_hd.sh

# Load function to upload backup to Google Drive using rclone
source fn_upload_to_gdrive.sh

# Eliminamos todos los contenedores detenidos, (es decir, los que tienen estado exited, dead o que no están en ejecución).
docker container prune -f

# Preparamos algunas variables y creamos directorios necesarios
# Obtenemos fecha actual del sistema y nombre del fichero ue guardará los log
read FECHA LOGFILE <<< "$(get_date_and_logfile)"

# Ruta del disco USB
DISK_USB="/dev/sdb1"

# Ruta donde se monta el disco USB
MOUNT_DISK_USB="/mnt/mount_disk_usb"

# Ruta donde se guardará la copia de seguridad
DEST_DIR="$MOUNT_DISK_USB/backup"

msg "---------------------------------------------" "$LOGFILE"
msg "- INICIO DE LA COPIA                        -" "$LOGFILE"
msg "---------------------------------------------" "$LOGFILE"

# Obtener todos los stacks levantados
STACKS=$(docker stack ls --format '{{.Name}}')

if [ -n "$STACKS" ]; then
    # Crear punto de montaje, si no existe, para el dispositivo usb de copias
    mkdir -p "$MOUNT_DISK_USB"

    # Lo desmontamos por si estuviera montado por otra app o usuario el disco usb
    desmontar_hd "$MOUNT_DISK_USB" "$DISK_USB" "$LOGFILE"

    # Montar el dispositivo
    if mount | grep "$MOUNT_DISK_USB" > /dev/null; then
        msg "[$(date)] Dispositivo ya montado en $MOUNT_DISK_USB" "$LOGFILE"
    else
        mount "$DISK_USB" "$MOUNT_DISK_USB"
        if [ $? -ne 0 ]; then
            msg "[$(date)] Error: No se pudo montar $DISK_USB" "$LOGFILE"
            exit 1
        else
            msg "[$(date)] Dispositivo USB montado correctamente." "$LOGFILE"
        fi
    fi

    # Levantamos los stacks, contenedores y sus servicios. Por si no se hubieran quedado levantados desde la última copia
    # o por si alguno estuviera parado manualmente.
    scale_stacks "$STACKS" 1 "$LOGFILE"

    # Crear carpeta de destino si no existe
    mkdir -p "$DEST_DIR"

    # Ruta de la carpeta a respaldar
    SOURCE_DIR="/docker"

    # Nombre del archivo de respaldo (con fecha y hora)
    BACKUP_FILE="$DEST_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    # Hacer mysqldump antes de detener los contenedores #

    # Obtener el nombre del contenedor que ejecuta la imagen FacturaScripts
    # La línea siguiente busca contenedores cuyo nombre comienza con 'mysql_mysql'
    # MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep '^mysql_mysql' | head -n1)

    # Pero mi contenedor empieza por '002-mysql_mysql_1', así que uso la línea siguiente que busca el contenedor que contenga 'mysql_mysql'
    MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep 'mysql_mysql' | head -n1)
    if [ -z "$MYSQL_CONTAINER" ]; then
        msg "[$(date)] ❌ Contenedor de mySql no encontrado o no está corriendo." "$LOGFILE"
        exit 1
    fi

    MYSQL_USER="root"
    MYSQL_PASSWORD="sasa"
    DUMP_DIR="$SOURCE_DIR/mysql_dump_temp"
    MYSQL_DUMP_FILE="$DUMP_DIR/mysql_dump_$(date +%Y%m%d_%H%M%S).sql"

    # Crear carpeta temporal para el dump
    mkdir -p "$DUMP_DIR"

    msg "[$(date)] Realizando volcado lógico de MySQL desde el contenedor '$MYSQL_CONTAINER'..." "$LOGFILE"
    docker exec "$MYSQL_CONTAINER" mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --all-databases > "$MYSQL_DUMP_FILE"

    if [ $? -eq 0 ]; then
        msg "[$(date)] mysqldump completado: $MYSQL_DUMP_FILE" "$LOGFILE"
    else
        msg "[$(date)] Error al ejecutar mysqldump" "$LOGFILE"
        exit 1
    fi

    # Paramos stacks, contenedores y sus servicios para realizar sus copias 
    scale_stacks "$STACKS" 0 "$LOGFILE"

    msg ". " "$LOGFILE"
    msg "[$(date)] Haciendo copia de seguridad de $SOURCE_DIR a $BACKUP_FILE ..." "$LOGFILE"
    msg ". " "$LOGFILE"

    # Crear la copia de seguridad
    tar -czvf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
    if [ $? -eq 0 ]; then
        msg "[$(date)] ✅ Copia de seguridad creada exitosamente en $BACKUP_FILE" "$LOGFILE"

        # NUEVA FUNCIÓN: Subir a Google Drive
        upload_to_gdrive "$BACKUP_FILE" "$LOGFILE"
    else
        msg "[$(date)] ❌ Error al crear la copia de seguridad" "$LOGFILE"

        # Levantamos los stacks, contenedores y sus servicios
        scale_stacks "$STACKS" 1 "$LOGFILE"

        # Desmontamos el dispositivo usb de copias 
        desmontar_hd "$MOUNT_DISK_USB" "$DISK_USB" "$LOGFILE"

        exit 1
    fi

    # Esperar a que termine la copia
    sync

    # Eliminar el dump temporal
    rm -rf "$DUMP_DIR"
    msg "[$(date)] Volcado lógico de MySQL eliminado del sistema (incluido en el .tar.gz)" "$LOGFILE"

    # Eliminar backups de más de 7 días
    msg "[$(date)] Vamos a eliminar backups de más de 7 días eliminados." "$LOGFILE"
    find "$DEST_DIR" -name 'backup_*.tar.gz' -type f -mtime +7 -exec rm -f {} \;
    msg "[$(date)] Backups de más de 7 días eliminados." "$LOGFILE"

    # Levantamos los stacks, contenedores y sus servicios
    scale_stacks "$STACKS" 1 "$LOGFILE"

    # Desmontamos el dispositivo usb de copias 
    desmontar_hd "$MOUNT_DISK_USB" "$DISK_USB" "$LOGFILE"

    # Borramos log's antiguos, de más de dos días 
    # Calcular la fecha de hace dos días en el mismo formato
    FECHA_LIMITE=$(date -d "-2 days" +%Y%m%d)

    # Borrar archivos cuyo nombre contiene fechas anteriores a FECHA_LIMITE
    for file in /docker/logs/backup_with_docker_pause_*.log; do
        # Extraer fecha del nombre del archivo
        filename=$(basename "$file")
        fecha_archivo=$(echo "$filename" | grep -oP '\d{8}')

        # Comparar fechas numéricamente
        if [[ "$fecha_archivo" =~ ^[0-9]{8}$ ]] && [[ "$fecha_archivo" -le "$FECHA_LIMITE" ]]; then
            msg "[$(date)] Borrando log antiguo: $file" "$LOGFILE"
            rm "$file"
        fi
    done
else
    msg ". " "$LOGFILE"
    msg "[$(date)] No hay stacks creados. Por lo que no puedo hacer copia de ellos." "$LOGFILE"
    msg ". " "$LOGFILE"
fi

msg "---------------------------------------------" "$LOGFILE"
msg "- FIN DE LA COPIA                           -" "$LOGFILE"
msg "---------------------------------------------" "$LOGFILE"

# sudo poweroff
