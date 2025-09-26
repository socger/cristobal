# Borramos log's antiguos, de más de dos días 
delete_logs() {
  local param_cantidad_dias=$1

  if [ -z "$param_cantidad_dias" ]; then
    param_cantidad_dias=2
  fi

  param_fecha_limite=$(date -d "-$param_cantidad_dias days" +%Y%m%d)

  # Usar variable de configuración
  local logs_dir="${LOGS_DIR:-/docker/logs}"
  
  for file in "$logs_dir"/backup_with_docker_pause_*.log; do
      filename=$(basename "$file")
      fecha_archivo=$(echo "$filename" | grep -oP '\d{8}')

      if [[ "$fecha_archivo" =~ ^[0-9]{8}$ ]] && [[ "$fecha_archivo" -le "$param_fecha_limite" ]]; then
          msg "[$(date)] Borrando log antiguo: $file" "$LOGFILE"
          rm "$file"
      fi
  done
}
