# Borramos log's antiguos, de más de dos días 
delete_logs() {
  local param_cantidad_dias=$1

  # Calcular la fecha de hace dos días en el mismo formato
  if [ -z "$param_cantidad_dias" ]; then
    param_cantidad_dias=2
  fi

  param_fecha_limite=$(date -d "-$param_cantidad_dias days" +%Y%m%d)

  # Borrar archivos cuyo nombre contiene fechas anteriores a param_fecha_limite
  for file in /docker/logs/backup_with_docker_pause_*.log; do
      # Extraer fecha del nombre del archivo
      filename=$(basename "$file")
      fecha_archivo=$(echo "$filename" | grep -oP '\d{8}')

      # Comparar fechas numéricamente
      if [[ "$fecha_archivo" =~ ^[0-9]{8}$ ]] && [[ "$fecha_archivo" -le "$param_fecha_limite" ]]; then
          msg "[$(date)] Borrando log antiguo: $file" "$LOGFILE"
          rm "$file"
      fi
  done
}


