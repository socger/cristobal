#!/bin/bash

# Obtener el directorio donde está ubicado este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Cargar configuración del sistema
source fn_load_config.sh
load_backup_config

# Cargamos función para imprimir mensajes en logs y terminal
source fn_msg.sh

# Cargamos funciones para escalar servicios de stacks
source fn_scale_stacks.sh
source fn_scale_services.sh

# Cargamos función para obtener fecha y archivo de log
source fn_get_date_and_logfile.sh

# Load function to unmount the USB backup device
source fn_desmontar_hd.sh

# Load function to mount the USB backup device
source fn_montar_hd.sh

# Load function to upload backup to Google Drive using rclone
source fn_upload_to_gdrive.sh

# Load function to create the zip backup
source fn_create_zip_backup.sh

# Cargamos función para verificar servicios de stacks
source fn_verificar_servicios.sh

# Cargamos función para controlar timeout al escalar servicios
source fn_controlar_timeout.sh

# Cargamos función para borrar logs antiguos
source fn_delete_logs.sh

# Eliminamos todos los contenedores detenidos
docker container prune -f

# Preparamos variables dinámicas (que dependen de la fecha/hora actual)
read FECHA LOGFILE <<< "$(get_date_and_logfile "$LOGS_DIR" "$LOG_FILE_BASENAME")"

# Ruta donde se guardará la copia de seguridad
DEST_DIR="$MOUNT_DISK_USB/backup"

# Nombre del archivo de respaldo (con fecha y hora)
BACKUP_FILE="$DEST_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# Variables para mysql dump
DUMP_DIR="$SOURCE_DIR/mysql_dump_temp"
MYSQL_DUMP_FILE="$DUMP_DIR/mysql_dump_$(date +%Y%m%d_%H%M%S).sql"

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
    montar_hd "$MOUNT_DISK_USB" "$DISK_USB" "$LOGFILE"

    # Levantamos los stacks, contenedores y sus servicios. Por si no se hubieran quedado levantados desde la última copia
    # o por si alguno estuviera parado manualmente.
    scale_stacks "$STACKS" 1 "$LOGFILE"

    # Crear carpeta de destino si no existe
    mkdir -p "$DEST_DIR"

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

    # Creamos la copia de seguridad en el disco USB
    create_zip_backup "$MOUNT_DISK_USB" "$DISK_USB" "$LOGFILE" "$SOURCE_DIR" "$DEST_DIR" "$BACKUP_FILE" "$STACKS"

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
    # delete_logs 2 "$LOG_FILE_BASENAME" "$LOGFILE"
    delete_logs "$LOG_RETENTION_DAYS" "$LOG_FILE_BASENAME" "$LOGFILE"
else
    msg ". " "$LOGFILE"
    msg "[$(date)] No hay stacks creados. Por lo que no puedo hacer copia de ellos." "$LOGFILE"
    msg ". " "$LOGFILE"
fi

msg "---------------------------------------------" "$LOGFILE"
msg "- FIN DE LA COPIA                           -" "$LOGFILE"
msg "---------------------------------------------" "$LOGFILE"

sudo poweroff
