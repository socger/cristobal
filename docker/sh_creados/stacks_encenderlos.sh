#!/bin/bash

# Cargamos función para imprimir mensajes en logs y terminal
source fn_msg.sh

# Cargamos funciones para escalar servicios de stacks
source fn_scale_stacks.sh
source fn_scale_services.sh

# Cargamos función para obtener fecha y archivo de log
source fn_get_date_and_logfile.sh

# Preparamos algunas variables y creamos directorios necesarios
# Obtenemos fecha actual del sistema y nombre del fichero que guardará los log
read FECHA LOGFILE <<< "$(get_date_and_logfile "$LOGS_DIR" "$LOG_FILE_BASENAME")"

# Obtener todos los stacks existentes. Levantados o no levantados.
STACKS=$(docker stack ls --format '{{.Name}}')

msg " " "$LOGFILE"
msg " " "$LOGFILE"
msg "*******************************************************" "$LOGFILE"
msg "[$(date)]" "$LOGFILE"
msg "INICIO - ENCENDIENDO SERVICIOS DE STACKS" "$LOGFILE"
msg "*******************************************************" "$LOGFILE"

# Recorremos los stacks y se escalan a 1 servicio
if [ -n "$STACKS" ]; then
    scale_stacks "$STACKS" 1 "$LOGFILE"
else
    msg "NO HAY STACKS CREADOS. Por lo que no puedo levantar ninguno." "$LOGFILE"
fi

msg " " "$LOGFILE"
msg "*********************************************" "$LOGFILE"
msg "[$(date)]" "$LOGFILE"
msg "- FIN - ENCENDIENDO SERVICIOS DE STACKS       " "$LOGFILE"
msg "*********************************************" "$LOGFILE"

