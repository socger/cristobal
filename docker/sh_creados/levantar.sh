#!/bin/bash

# ------------------------------------------------- #
# Función para imprimir mensajes en logs y terminal #
# ------------------------------------------------- #
source fn_msg.sh

# ------------------------------------------------- #
# Funciones para escalar servicios de stacks        #
# ------------------------------------------------- #
source fn_scale_stacks.sh
source fn_scale_services.sh

# ------------------------------------------------- #
# Preparamos algunas variables y creaos directorios #
# ------------------------------------------------- #
# Fecha y nombre del fichero que guardará los log
FECHA=$(date +%Y%m%d)
LOGFILE="/docker/logs/backup_with_docker_pause_$FECHA.log"

# Obtener todos los stacks existentes. Levantados o no levantados.
STACKS=$(docker stack ls --format '{{.Name}}')

msg " " "$LOGFILE"
msg " " "$LOGFILE"
msg "*******************************************************" "$LOGFILE"
msg "[$(date)]" "$LOGFILE"
msg "INICIO - LEVANTANDO SERVICIOS DE STACKS" "$LOGFILE"
msg "*******************************************************" "$LOGFILE"

# ------------------------------------------------- #
# Recorremos los stacks y se escalan a 1 servicio   #
# ------------------------------------------------- #
if [ -n "$STACKS" ]; then
    scale_stacks "$STACKS" 1 "$LOGFILE"
else
    msg "No hay stacks creados. Por lo que no puedo levantar ninguno." "$LOGFILE"
fi

msg " " "$logfile"
msg "*********************************************" "$LOGFILE"
msg "[$(date)]" "$LOGFILE"
msg "- FIN - LEVANTANDO SERVICIOS DE STACKS       " "$LOGFILE"
msg "*********************************************" "$LOGFILE"

