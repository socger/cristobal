# Función para escalar servicios de un stack        #
scale_services() {
  local param_stack=$1
  local param_replicas=$2
  local param_logfile=$3

  # Obtener todos los servicios del stack
  SERVICES=$(docker stack services "$param_stack" --format '{{.Name}}')

  if [ -n "$SERVICES" ]; then
    msg " " "$param_logfile"
    msg "........................................................" "$param_logfile"
    msg "[$(date)]" "$param_logfile"
    msg "Escalando a $param_replicas réplica(s) todos los servicios" "$param_logfile"
    msg "del stack '$param_stack'" "$param_logfile"
    msg " " "$param_logfile"
    msg "Servicios detectados:" "$param_logfile"
    msg "$SERVICES" "$param_logfile"

    for service in $SERVICES; do
      msg " " "$param_logfile"
      msg "- Escalando servicio $service" "$param_logfile"
      msg "  a $param_replicas replica/s." "$param_logfile"

      # Añadir timeout al comando docker service scale por si se cuelta algún servicio mientras lo escalamos
      timeout 60 docker service scale "$service=$param_replicas" >> "$param_logfile" 2>&1

      local exit_code=$?
      if [ $exit_code -eq 0 ]; then
        msg "  ✅ Servicio $service escalado correctamente" "$param_logfile"
      elif [ $exit_code -eq 124 ]; then
        controlar_timeout "$service" "$param_stack" "$param_logfile"
      else
        msg "  ❌ Error al escalar servicio $service (código: $exit_code)" "$param_logfile"
      fi
    done

    msg " " "$param_logfile"
    msg "[$(date)]" "$param_logfile"
    msg "Escalado completado para el stack '$param_stack'" "$param_logfile"

    verificar_servicios "$param_stack" "$SERVICES" "$param_replicas" "$param_logfile"

    msg "........................................................" "$param_logfile"
  else
    msg " " "$param_logfile"
    msg "........................................................" "$param_logfile"
    msg "[$(date)]" "$param_logfile"
    msg "No hay servicios para el stack '$param_stack'." "$param_logfile"
    msg "Por lo que no puedo escalarlos a $param_replicas replica/s." "$param_logfile"
    msg "........................................................" "$param_logfile"
  fi
}
