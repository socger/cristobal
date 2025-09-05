#!/bin/bash

# Eliminamos todos los contenedores detenidos (es decir, los que tienen estado exited, dead o que no están en ejecución). 
docker container prune -f


# Fecha y nombre del fichero que guardará los log
FECHA=$(date +%Y%m%d)
LOGFILE="/docker/logs/backup_with_docker_pause_$FECHA.log"

# Ruta del disco USB
DISK_USB="/dev/sdb1"

# Ruta donde se monta el disco USB
MOUNT_DISK_USB="/mnt/mount_disk_usb"

# Ruta donde se guardará la copia de seguridad
DEST_DIR="$MOUNT_DISK_USB/backup"

# Crear punto de montaje si no existe
mkdir -p "$MOUNT_DISK_USB"

# Montar el dispositivo
mount "$DISK_USB" "$MOUNT_DISK_USB"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo montar $DISK_USB" >> "$LOGFILE"
    exit 1
fi

echo "Dispositivo USB montado correctamente." >> "$LOGFILE"

# Crear carpeta de destino si no existe
mkdir -p "$DEST_DIR"

# Ruta de la carpeta a respaldar
SOURCE_DIR="/docker"

# Nombre del archivo de respaldo (con fecha y hora)
BACKUP_FILE="$DEST_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# Hacer mysqldump antes de detener los contenedores

# Obtener el nombre del contenedor que ejecuta la imagen FacturaScripts
MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep '^mysql_mysql' | head -n1)
if [ -z "$MYSQL_CONTAINER" ]; then
    echo "[$(date)] ❌ Contenedor de mySql no encontrado o no está corriendo." >> "$LOGFILE"
    exit 1
fi

MYSQL_USER="root"
MYSQL_PASSWORD="sasa"
DUMP_DIR="$SOURCE_DIR/mysql_dump_temp"
MYSQL_DUMP_FILE="$DUMP_DIR/mysql_dump_$(date +%Y%m%d_%H%M%S).sql"

# Crear carpeta temporal para el dump
mkdir -p "$DUMP_DIR"

echo "Realizando volcado lógico de MySQL desde el contenedor '$MYSQL_CONTAINER'..." >> "$LOGFILE"
docker exec "$MYSQL_CONTAINER" mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --all-databases > "$MYSQL_DUMP_FILE"

if [ $? -eq 0 ]; then
    echo "mysqldump completado: $MYSQL_DUMP_FILE" >> "$LOGFILE"
else
    echo "Error al ejecutar mysqldump" >> "$LOGFILE"
fi

echo "Obteniendo contenedores en ejecución..." >> "$LOGFILE"
RUNNING_CONTAINERS=$(docker ps -q)

if [ -n "$RUNNING_CONTAINERS" ]; then
    echo "Deteniendo contenedores..." >> "$LOGFILE"
    docker stop $RUNNING_CONTAINERS

    echo "Haciendo copia de seguridad de $SOURCE_DIR a $BACKUP_FILE..." >> "$LOGFILE"
    tar -czvf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

    echo "Reiniciando contenedores..." >> "$LOGFILE"
    docker start $RUNNING_CONTAINERS

    # Esperar a que termine la copia
    sync

    echo "Copia completada." >> "$LOGFILE"

    # Eliminar el dump temporal
    rm -rf "$DUMP_DIR"
    echo "Volcado lógico de MySQL eliminado del sistema (incluido en el .tar.gz)" >> "$LOGFILE"

    # Eliminar backups de más de 7 días
    echo "Vamos a eliminar backups de más de 7 días eliminados." >> "$LOGFILE"
    find "$DEST_DIR" -name 'backup_*.tar.gz' -type f -mtime +7 -exec rm -f {} \;
    echo "Backups de más de 7 días eliminados." >> "$LOGFILE"
else
    echo "No hay contenedores en ejecución." >> "$LOGFILE"
    echo "No puedo hacer copia de seguridad." >> "$LOGFILE"
fi

# Desmontar
umount "$MOUNT_DISK_USB"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo desmontar $DISK_USB" >> "$LOGFILE"
    exit 1
fi

echo "Dispositivo USB desmontado correctamente." >> "$LOGFILE"
echo "---------------------------------------------" >> "$LOGFILE"

# 🧹 Borrar solo logs antiguos de facturascripts
# find /docker/logs/ -type f -name "backup_with_docker_pause_*.log" -mtime +2 -delete

# Calcular la fecha de hace dos días en el mismo formato
FECHA_LIMITE=$(date -d "-2 days" +%Y%m%d)

# Borrar archivos cuyo nombre contiene fechas anteriores a FECHA_LIMITE
for file in /docker/logs/backup_with_docker_pause_*.log; do
    # Extraer fecha del nombre del archivo
    filename=$(basename "$file")
    fecha_archivo=$(echo "$filename" | grep -oP '\d{8}')

    # Comparar fechas numéricamente
    if [[ "$fecha_archivo" =~ ^[0-9]{8}$ ]] && [[ "$fecha_archivo" -le "$FECHA_LIMITE" ]]; then
        echo "[$(date)] Borrando log antiguo: $file" >> "$LOGFILE"
        rm "$file"
    fi
done
