# Función para escalar servicios de un stack        #
controlar_timeout() {
    local param_service=$1
    local param_stack=$2
    local param_logfile=$3

    # msg "  ⚠️ TIMEOUT: Servicio $param_service tardó más de 60s en escalar" "$param_logfile"
    # msg "  ⚠️ Continuando con el siguiente servicio..." "$param_logfile"

    msg "  ⚠️ TIMEOUT: Servicio $param_service tardó más de 60s en escalar" "$param_logfile"

    # Si es MySQL y estamos levantando (replicas > 0), hacer restart completo del stack
    if echo "$param_service" | grep -q "mysql" && [ "$replicas" -gt 0 ]; then
        msg "  🔄 Intentando restart completo del stack MySQL..." "$param_logfile"

        # Parar completamente el stack
        msg "  📤 Parando stack $param_stack..." "$param_logfile"
        docker stack rm "$param_stack" >> "$param_logfile" 2>&1

        # Esperar a que se elimine completamente
        msg "  ⏳ Esperando eliminación completa del stack..." "$param_logfile"
        local wait_attempts=0

        while docker stack ls --format '{{.Name}}' | grep -q "^${stack}$" && [ $wait_attempts -lt 30 ]; do
            sleep 2
            wait_attempts=$((wait_attempts + 1))
        done

        if [ $wait_attempts -ge 30 ]; then
            msg "  ⚠️ Stack tardó demasiado en eliminarse, continuando..." "$param_logfile"
        else
            msg "  ✅ Stack eliminado correctamente" "$param_logfile"
        fi

        # Redeploy del stack desde el archivo YAML
        local yaml_file=""
        if [ -f "/docker/portainer/stacks/${stack}.yaml" ]; then
            yaml_file="/docker/portainer/stacks/${stack}.yaml"
        elif [ -f "/home/socger/trabajo/socger/cristobal/docker/portainer/stacks/${stack}.yaml" ]; then
            yaml_file="/home/socger/trabajo/socger/cristobal/docker/portainer/stacks/${stack}.yaml"
        fi

        if [ -n "$yaml_file" ] && [ -f "$yaml_file" ]; then
            msg "  🚀 Redesplegar stack desde: $yaml_file" "$param_logfile"
            docker stack deploy -c "$yaml_file" "$param_stack" >> "$param_logfile" 2>&1

            if [ $? -eq 0 ]; then
                msg "  ✅ Stack $param_stack redesplegar correctamente" "$param_logfile"

                # Esperar a que el servicio esté disponible
                msg "  ⏳ Esperando a que el servicio esté disponible..." "$param_logfile"
                sleep 15

                # Verificar que el servicio está corriendo
                local service_status=$(docker service ls --format '{{.Name}} {{.Replicas}}' --filter "name=$param_service")
                msg "  📊 Estado del servicio: $service_status" "$param_logfile"
            else
                msg "  ❌ Error al redesplegar stack $param_stack" "$param_logfile"
            fi
        else
            msg "  ❌ No se encontró archivo YAML para el stack $param_stack" "$param_logfile"
            msg "  📝 Buscado en: /docker/portainer/stacks/${stack}.yaml" "$param_logfile"
            msg "  📝 Buscado en: /home/socger/trabajo/socger/cristobal/docker/portainer/stacks/${stack}.yaml" "$param_logfile"
        fi
    else
        msg "  ⚠️ Continuando con el siguiente servicio..." "$param_logfile"
    fi
}
