#!/bin/bash
# ===================================================
# Descripción: Sincroniza imágenes desde una carpeta
# de Google Drive y muestra una presentación de 
# diapositivas con feh.
# Autor: GitHub Copilot
# Versión: 1.1
# ===================================================

# --- MÓDULO DE CONFIGURACIÓN ---
LOCAL_DIR="/docker/images"
NUBE="GNube"
NUBE_PATH="images"
REMOTE="${NUBE}:${NUBE_PATH}"
SYNC_INTERVAL=3600
SLIDE_DELAY=10

# --- MÓDULO DE LIMPIEZA Y SALIDA ---
# Función que se ejecuta al salir del script (Ctrl+C)
cleanup() {
    echo -e "\n[INFO] Saliendo del slideshow..."
    # Verifica si feh está en ejecución antes de intentar matarlo
    if pgrep -x "feh" > /dev/null; then
        echo "[INFO] Deteniendo el proceso 'feh'..."
        pkill feh
    fi
    echo "[INFO] Script finalizado."
    exit 0
}

# Atrapa las señales de interrupción y terminación y llama a la función cleanup
trap cleanup SIGINT SIGTERM

# --- MÓDULO DE SINCRONIZACIÓN ---
sync_images() {
    echo "[INFO] Sincronizando carpeta remota $REMOTE con $LOCAL_DIR ..."
    rclone sync "$REMOTE" "$LOCAL_DIR" --update --verbose --drive-chunk-size 64M
}

# --- FLUJO PRINCIPAL ---
echo "=== Iniciando Slideshow desde Google Drive ==="
sync_images

while true; do
    # Verifica si hay imágenes antes de lanzar feh
    if [ -n "$(find "$LOCAL_DIR" -maxdepth 1 -type f)" ]; then
        echo "[INFO] Lanzando presentación de imágenes..."
        feh -Z -z -F -D $SLIDE_DELAY --hide-pointer --auto-rotate "$LOCAL_DIR"
    else
        echo "[WARN] No se encontraron imágenes en $LOCAL_DIR. Esperando para re-sincronizar."
    fi

    echo "[INFO] Esperando $SYNC_INTERVAL segundos antes de la próxima sincronización..."
    sleep $SYNC_INTERVAL

    sync_images
done