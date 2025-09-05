#!/bin/bash

# Obtener fecha actual para el nombre del log (YYYYMMDD)
FECHA=$(date +%Y%m%d)
LOGFILE="/docker/logs/facturascripts_cron_$FECHA.log"

echo "[$(date)] Iniciando cron de FacturaScripts..." >> "$LOGFILE"

FS_CONTAINER="facturascripts-facturascripts-1"
docker exec "$FS_CONTAINER" php index.php -cron >> "$LOGFILE" 2>&1

echo "[$(date)] Cron de FacturaScripts finalizado." >> "$LOGFILE"
echo "---------------------------------------------" >> "$LOGFILE"

# 🧹 Borrar solo logs antiguos de facturascripts
# find /docker/logs/ -type f -name "facturascripts_cron_*.log" -mtime +2 -delete

# Calcular la fecha de hace dos días en el mismo formato
FECHA_LIMITE=$(date -d "-2 days" +%Y%m%d)

# Borrar archivos cuyo nombre contiene fechas anteriores a FECHA_LIMITE
for file in /docker/logs/facturascripts_cron_*.log; do
    # Extraer fecha del nombre del archivo
    filename=$(basename "$file")
    fecha_archivo=$(echo "$filename" | grep -oP '\d{8}')

    # Comparar fechas numéricamente
    if [[ "$fecha_archivo" =~ ^[0-9]{8}$ ]] && [[ "$fecha_archivo" -le "$FECHA_LIMITE" ]]; then
        echo "[$(date)] Borrando log antiguo: $file" >> "$LOGFILE"
        rm "$file"
    fi
done
