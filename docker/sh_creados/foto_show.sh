#!/bin/bash
# ===================================================
# Descripción: Sincroniza imágenes desde una carpeta
# de Google Drive y muestra una presentación de 
# diapositivas con feh.
# ===================================================

# Carpeta local donde se guardan las imágenes
LOCAL_DIR="/docker/images"

# Nombre del remoto configurado en rclone
NUBE="GNube"

# Ruta dentro del remoto
NUBE_PATH="images"

# Carpeta en tu Drive
REMOTE="${NUBE}:${NUBE_PATH}"

# Tiempo entre sincronizaciones 1 hora (en segundos)
SYNC_INTERVAL=3600

# Tiempo de visualización de cada imagen (en segundos)
SLIDE_DELAY=10

# Comando feh base
FEH_CMD="feh -Z -z -F -D $SLIDE_DELAY --hide-pointer --auto-rotate $LOCAL_DIR"

# Guardar comando en variable
RCLONE_SYNC_CMD="rclone sync \"$REMOTE\" \"$LOCAL_DIR\" --update --verbose --drive-chunk-size 64M"

echo "=== Iniciando Slideshow desde Google Drive ==="
echo "Sincronizando carpeta remota $REMOTE con $LOCAL_DIR ..."
eval $RCLONE_SYNC_CMD

while true; do
    echo "Lanzando presentación de imágenes..."
    $FEH_CMD

    echo "Esperando $SYNC_INTERVAL segundos antes de la próxima sincronización..."
    sleep $SYNC_INTERVAL

    echo "Actualizando imágenes desde Drive..."
    eval $RCLONE_SYNC_CMD
done
