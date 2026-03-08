#!/bin/bash

# Prepara rutas para el volcado lógico de MySQL.
prepare_mysql_dump_paths() {
  local source_path=$1

  DUMP_DIR="$source_path/mysql_dump_temp"
  MYSQL_DUMP_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
}

# Sanitiza nombres para construir rutas de archivo seguras.
sanitize_for_filename() {
  local value=$1
  echo "$value" | tr -c '[:alnum:]_.-' '_'
}

# Realiza un dump por cada contenedor de servicios MySQL en ejecución.
run_mysql_dump() {
  local mysql_user=$1
  local mysql_password=$2
  local logfile=$3
  local found_any=false
  local line=""
  local container_name=""
  local stack_name=""
  local service_name=""
  local safe_stack_name=""
  local safe_service_name=""
  local dump_file=""

  mkdir -p "$DUMP_DIR"

  while IFS='|' read -r container_name stack_name service_name; do
    # Filtrar solo servicios/contendores que correspondan a mysql.
    if [[ "$container_name" != *mysql* && "$service_name" != *mysql* && "$stack_name" != *mysql* ]]; then
      continue
    fi

    found_any=true
    safe_stack_name=$(sanitize_for_filename "$stack_name")
    safe_service_name=$(sanitize_for_filename "$service_name")
    dump_file="$DUMP_DIR/mysql_dump_${safe_stack_name}_${safe_service_name}_${MYSQL_DUMP_TIMESTAMP}.sql"

    msg "[$(date)] Realizando volcado lógico de MySQL desde '$container_name' (stack: '$stack_name', servicio: '$service_name')..." "$logfile"
    if docker exec "$container_name" mysqldump -u"$mysql_user" -p"$mysql_password" --all-databases > "$dump_file"; then
      msg "[$(date)] mysqldump completado: $dump_file" "$logfile"
    else
      msg "[$(date)] ❌ Error al ejecutar mysqldump en '$container_name'" "$logfile"
      return 1
    fi
  done < <(docker ps --format '{{.Names}}|{{.Label "com.docker.stack.namespace"}}|{{.Label "com.docker.swarm.service.name"}}')

  if [ "$found_any" = false ]; then
    msg "[$(date)] ❌ No se encontraron contenedores MySQL en ejecución." "$logfile"
    return 1
  fi

  return 0
}

# Elimina el directorio temporal usado para el dump.
cleanup_mysql_dump() {
  local dump_dir=$1
  local logfile=$2

  rm -rf "$dump_dir"
  msg "[$(date)] Volcado lógico de MySQL eliminado del sistema (incluido en el .tar.gz)" "$logfile"
}
