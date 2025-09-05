#!/bin/bash

# ------------------------------------------------- #
# Función para escalar servicios de un stack        #
# ------------------------------------------------- #
scale_stack_services() {
  local stack=$1
  local replicas=$2

  echo "Escalando servicios del stack '$stack' a $replicas réplica(s)..."

  # Obtener todos los servicios del stack
  SERVICES=$(docker stack services "$stack" --format '{{.Name}}')

  for service in $SERVICES; do
    echo "  Escalando servicio $service a $replicas..."
    docker service scale "$service=$replicas"
  done
}

# ------------------------------------------------- #
# Paramos stacks y contenedores y realizamos copia  #
# ------------------------------------------------- #
# Obtener todos los stacks levantados
STACKS=$(docker stack ls --format '{{.Name}}')
if [ -n "$STACKS" ]; then
    echo "Stacks detectados: $STACKS"


    # Escalar todos los servicios de todos los stacks a 0 (pausar)
    for stack in $STACKS; do
      scale_stack_services "$stack" 1
    done

    echo "Todos los servicios escalados a 1."
else
    echo "No hay stacks en ejecución." >> "$LOGFILE"
    echo "No puedo hacer copia de seguridad." >> "$LOGFILE"
fi
