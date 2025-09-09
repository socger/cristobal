#!/bin/bash

# ------------------------------------------------- #
# Función para escalar servicios de un stack        #
# ------------------------------------------------- #
scale_services() {
  local stack=$1
  local replicas=$2
  local logfile=$3

  # Obtener todos los servicios del stack
  SERVICES=$(docker stack services "$stack" --format '{{.Name}}')

  if [ -n "$SERVICES" ]; then
    msg " " "$logfile"
    msg "........................................................" "$logfile"
    msg "[$(date)]" "$logfile"
    msg "Escalando a $replicas réplica(s) todos los servicios" "$logfile"
    msg "del stack '$stack'" "$logfile"
    msg " " "$logfile"
    msg "Servicios detectados:" "$logfile"
    msg "$SERVICES" "$logfile"

    for service in $SERVICES; do
      msg " " "$logfile"
      msg "- Escalando servicio $service" "$logfile"
      msg "  a $replicas replica/s." "$logfile"
      docker service scale "$service=$replicas" >> "$logfile"
    done

    msg " " "$logfile"
    msg "[$(date)]" "$logfile"
    msg "Escalados a $replicas replica/s, todos los servicios" "$logfile"
    msg "del stack '$stack'" "$logfile"
    msg "........................................................" "$logfile"
  else
    msg " " "$logfile"
    msg "........................................................" "$logfile"
    msg "[$(date)]" "$logfile"
    msg "No hay servicios para el stack '$stack'." "$logfile"
    msg "Por lo que no puedo escalarlos a $replicas replica/s." "$logfile"
    msg "........................................................" "$logfile"
  fi
}
