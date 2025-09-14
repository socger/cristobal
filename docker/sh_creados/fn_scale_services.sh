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
      
      # CAMBIO PRINCIPAL: Añadir timeout al comando docker service scale
      timeout 60 docker service scale "$service=$replicas" >> "$logfile" 2>&1
      
      local exit_code=$?
      if [ $exit_code -eq 0 ]; then
        msg "  ✅ Servicio $service escalado correctamente" "$logfile"
      elif [ $exit_code -eq 124 ]; then
        msg "  ⚠️ TIMEOUT: Servicio $service tardó más de 60s en escalar" "$logfile"
        msg "  ⚠️ Continuando con el siguiente servicio..." "$logfile"
      else
        msg "  ❌ Error al escalar servicio $service (código: $exit_code)" "$logfile"
      fi
    done

    msg " " "$logfile"
    msg "[$(date)]" "$logfile"
    msg "Escalado completado para el stack '$stack'" "$logfile"
    
    # Si estamos levantando servicios (replicas > 0), verificar estado
    if [ "$replicas" -gt 0 ]; then
      msg "Verificando estado de los servicios..." "$logfile"
      
      # Esperar un poco para que los servicios se estabilicen
      sleep 10
      
      # Mostrar estado actual
      msg "Estado actual de los servicios:" "$logfile"
      docker stack services "$stack" --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}" >> "$logfile" 2>&1
      
      # Verificación específica para MySQL
      if echo "$SERVICES" | grep -q "mysql"; then
        msg "Realizando verificación específica de MySQL..." "$logfile"
        
        local mysql_ready=false
        local attempts=0
        local max_attempts=12  # 2 minutos (12 x 10s)
        
        while [ $attempts -lt $max_attempts ] && [ "$mysql_ready" = false ]; do
          local mysql_container=$(docker ps --format '{{.Names}}' | grep 'mysql_mysql' | head -n1)
          
          if [ -n "$mysql_container" ]; then
            if docker exec "$mysql_container" mysqladmin ping -uroot -psasa >/dev/null 2>&1; then
              msg "  ✅ MySQL está respondiendo correctamente" "$logfile"
              mysql_ready=true
            else
              msg "  ⏳ MySQL aún no acepta conexiones (intento $((attempts + 1))/$max_attempts)" "$logfile"
              sleep 10
              attempts=$((attempts + 1))
            fi
          else
            msg "  ⏳ Contenedor MySQL aún no está disponible (intento $((attempts + 1))/$max_attempts)" "$logfile"
            sleep 10
            attempts=$((attempts + 1))
          fi
        done
        
        if [ "$mysql_ready" = false ]; then
          msg "  ⚠️ MySQL no respondió en 2 minutos. Continuando de todos modos..." "$logfile"
          msg "  ⚠️ El backup podría fallar si MySQL no está operativo" "$logfile"
        fi
      fi
    fi
    
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
