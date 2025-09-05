#!/bin/bash

# ------------------------------------------------- #
# Eliminamos todos los contenedores detenidos, (es  #
# decir, los que tienen estado exited, dead o que   #
# no están en ejecución).
# ------------------------------------------------- #
docker container prune -f

# ------------------------------------------------- #
# Preparamos algunas variables y creaos directorios #
# ------------------------------------------------- #
# Fecha y nombre del fichero que guardará los log
FECHA=$(date +%Y%m%d)
LOGFILE="/docker/logs/backup_with_docker_pause_$FECHA.log"

# Ruta del disco USB
DISK_USB="/dev/sdb1"

# Ruta donde se monta el disco USB
MOUNT_DISK_USB="/mnt/mount_disk_usb"

# Ruta donde se guardará la copia de seguridad
DEST_DIR="$MOUNT_DISK_USB/backup"

# ------------------------------------------------- #
# Montamos el dispositivo usb de copias             #
# ------------------------------------------------- #
# Crear punto de montaje si no existe
mkdir -p "$MOUNT_DISK_USB"

# Montar el dispositivo
if mount | grep "$MOUNT_DISK_USB" > /dev/null; then
    echo "[$(date)] Dispositivo ya montado en $MOUNT_DISK_USB" >> "$LOGFILE"
else
    mount "$DISK_USB" "$MOUNT_DISK_USB"
    if [ $? -ne 0 ]; then
        echo "[$(date)] Error: No se pudo montar $DISK_USB" >> "$LOGFILE"
        exit 1
    else
        echo "[$(date)] Dispositivo USB montado correctamente." >> "$LOGFILE"
    fi
fi


# ------------------------------------------------- #
# Creamos carpeta y fichero de copias               #
# ------------------------------------------------- #
# Crear carpeta de destino si no existe
mkdir -p "$DEST_DIR"

# Ruta de la carpeta a respaldar
SOURCE_DIR="/docker"

# Nombre del archivo de respaldo (con fecha y hora)
BACKUP_FILE="$DEST_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# ------------------------------------------------- #
# Hacer mysqldump antes de detener los contenedores #
# ------------------------------------------------- #
# Obtener el nombre del contenedor que ejecuta la imagen FacturaScripts
# La línea siguiente busca contenedores cuyo nombre comienza con 'mysql_mysql'
# MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep '^mysql_mysql' | head -n1)
# Pero mi contenedor empieza por '002-mysql_mysql_1', así que uso la línea siguiente que busca el contenedor que contenga 'mysql_mysql'
MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep 'mysql_mysql' | head -n1)
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

echo "[$(date)] Realizando volcado lógico de MySQL desde el contenedor '$MYSQL_CONTAINER'..." >> "$LOGFILE"
docker exec "$MYSQL_CONTAINER" mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --all-databases > "$MYSQL_DUMP_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date)] mysqldump completado: $MYSQL_DUMP_FILE" >> "$LOGFILE"
else
    echo "[$(date)] Error al ejecutar mysqldump" >> "$LOGFILE"
fi

# ------------------------------------------------- #
# Función para escalar servicios de un stack        #
# ------------------------------------------------- #
scale_stack_services() {
  local stack=$1
  local replicas=$2
  local logfile=$3

  echo "[$(date)] Escalando servicios del stack '$stack' a $replicas réplica(s)..." >> "$logfile"

  # Obtener todos los servicios del stack
  SERVICES=$(docker stack services "$stack" --format '{{.Name}}')

  for service in $SERVICES; do
    echo "  [$(date)] Escalando servicio $service a $replicas..." >> "$logfile"
    docker service scale "$service=$replicas"
  done
}

# ------------------------------------------------- #
# Paramos stacks y contenedores y realizamos copia  #
# ------------------------------------------------- #
# Obtener todos los stacks levantados
STACKS=$(docker stack ls --format '{{.Name}}')
if [ -n "$STACKS" ]; then
    echo "[$(date)] Stacks detectados: $STACKS"

    # Escalar todos los servicios de todos los stacks a 0 (pausar)
    for stack in $STACKS; do
      scale_stack_services "$stack" 0 "$LOGFILE"
    done
    echo "[$(date)] Todos los servicios escalados a 0." >> "$LOGFILE"

    echo "[$(date)] Haciendo copia de seguridad de $SOURCE_DIR a $BACKUP_FILE..." >> "$LOGFILE"
    if tar -czvf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"; then
        echo "[$(date)] Copia completada." >> "$LOGFILE"
    else
        echo "[$(date)] Error durante la copia de seguridad." >> "$LOGFILE"
        exit 1
    fi

    # Esperar a que termine la copia
    sync

    # Eliminar el dump temporal
    rm -rf "$DUMP_DIR"
    echo "[$(date)] Volcado lógico de MySQL eliminado del sistema (incluido en el .tar.gz)" >> "$LOGFILE"

    # Eliminar backups de más de 7 días
    echo "[$(date)] Vamos a eliminar backups de más de 7 días eliminados." >> "$LOGFILE"
    find "$DEST_DIR" -name 'backup_*.tar.gz' -type f -mtime +7 -exec rm -f {} \;
    echo "[$(date)] Backups de más de 7 días eliminados." >> "$LOGFILE"

    # Escalar todos los servicios de todos los stacks a 1 (levantar stacks/servicios/contenedores)
    for stack in $STACKS; do
      scale_stack_services "$stack" 1 "$LOGFILE"
    done
    echo "[$(date)] Todos los servicios escalados a 1." >> "$LOGFILE"
else
    echo "[$(date)] No hay stacks en ejecución." >> "$LOGFILE"
    echo "[$(date)] No puedo hacer copia de seguridad." >> "$LOGFILE"
fi

# ------------------------------------------------- #
# Desmontamos el dispositivo usb de copias          #
# ------------------------------------------------- #
umount "$MOUNT_DISK_USB"
if [ $? -ne 0 ]; then
    echo "[$(date)] Error: No se pudo desmontar $DISK_USB" >> "$LOGFILE"
    exit 1
fi

echo "[$(date)] Dispositivo USB desmontado correctamente." >> "$LOGFILE"
echo "---------------------------------------------" >> "$LOGFILE"

# ------------------------------------------------- #
# Borramos log's antiguos, de más de dos días       #
# ------------------------------------------------- #
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

sudo poweroff
