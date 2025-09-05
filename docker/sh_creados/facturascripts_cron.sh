#!/bin/bash

# Obtener fecha actual para el nombre del log (YYYYMMDD)
FECHA=$(date +%Y%m%d)
LOGFILE="/docker/logs/facturascripts_cron_$FECHA.log"

echo "[$(date)] 🔄 Iniciando cron de FacturaScripts..." >> "$LOGFILE"

# Obtener el nombre del contenedor que ejecuta la imagen FacturaScripts
FS_CONTAINER=$(docker ps --format '{{.Names}}' | grep '^facturascripts_facturascripts' | head -n1)

if [ -z "$FS_CONTAINER" ]; then
    echo "[$(date)] ❌ Contenedor de FacturaScripts no encontrado o no está corriendo." >> "$LOGFILE"
else
    echo "[$(date)] ✅ Ejecutando cron en contenedor: $FS_CONTAINER" >> "$LOGFILE"
    docker exec "$FS_CONTAINER" php index.php -cron >> "$LOGFILE" 2>&1
    echo "[$(date)] ✔️ Cron de FacturaScripts finalizado." >> "$LOGFILE"
fi

echo "---------------------------------------------" >> "$LOGFILE"

# 🧹 Borrar logs antiguos (más de 2 días)
FECHA_LIMITE=$(date -d "-2 days" +%Y%m%d)

shopt -s nullglob
for file in /docker/logs/facturascripts_cron_*.log; do
    filename=$(basename "$file")
    fecha_archivo=$(echo "$filename" | grep -oP '\d{8}')

    if [[ "$fecha_archivo" =~ ^[0-9]{8}$ ]] && [[ "$fecha_archivo" -le "$FECHA_LIMITE" ]]; then
        echo "[$(date)] 🗑️ Borrando log antiguo: $file" >> "$LOGFILE"
        rm "$file"
    fi
done
shopt -u nullglob
