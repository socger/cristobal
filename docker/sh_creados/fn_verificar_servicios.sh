# Function to verify services of stacks
verificar_servicios() {
    local param_stack=$1
    local param_services=$2
    local param_replicas=$3
    local param_logfile=$4

    # Si estamos levantando servicios (replicas > 0), verificar estado
    if [ "$param_replicas" -gt 0 ]; then
      msg "Verificando estado de los servicios..." "$param_logfile"

      # Esperar un poco para que los servicios se estabilicen
      sleep 10

      # Mostrar estado actual
      msg "Estado actual de los servicios:" "$param_logfile"
      docker stack services "$param_stack" --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}" >> "$param_logfile" 2>&1

      # Verificación específica para MySQL
      if echo "$param_services" | grep -q "mysql"; then
        msg "Realizando verificación específica de MySQL..." "$param_logfile"

        local mysql_ready=false
        local attempts=0
        local max_attempts=12  # 2 minutos (12 x 10s)

        while [ $attempts -lt $max_attempts ] && [ "$mysql_ready" = false ]; do
          local mysql_container=$(docker ps --format '{{.Names}}' | grep 'mysql_mysql' | head -n1)

          if [ -n "$mysql_container" ]; then
            if docker exec "$mysql_container" mysqladmin ping -uroot -psasa >/dev/null 2>&1; then
              msg "  ✅ MySQL está respondiendo correctamente" "$param_logfile"
              mysql_ready=true
            else
              msg "  ⏳ MySQL aún no acepta conexiones (intento $((attempts + 1))/$max_attempts)" "$param_logfile"
              sleep 10
              attempts=$((attempts + 1))
            fi
          else
            msg "  ⏳ Contenedor MySQL aún no está disponible (intento $((attempts + 1))/$max_attempts)" "$param_logfile"
            sleep 10
            attempts=$((attempts + 1))
          fi
        done

        if [ "$mysql_ready" = false ]; then
          msg "  ⚠️ MySQL no respondió en 2 minutos. Continuando de todos modos..." "$param_logfile"
          msg "  ⚠️ El backup podría fallar si MySQL no está operativo" "$param_logfile"
        fi
      fi
    fi
}
