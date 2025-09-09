#!/bin/bash

scale_stacks() {
  local stacks=$1
  local replicas=$2
  local logfile=$3

  msg " " "$logfile"
  msg "--------------------------------------------------------" "$logfile"
  msg "[$(date)]" "$logfile"
  msg "Escalando servicios a $replicas replica/s de los stacks:" "$logfile"
  msg "$stacks" "$logfile"
  msg "--------------------------------------------------------" "$logfile"

  # Escalar todos los servicios de todos los stacks a 0 (pausar)
  for stack in $stacks; do
    scale_services "$stack" "$replicas" "$logfile"
  done

  msg " " "$logfile"
  msg "--------------------------------------------------------" "$logfile"
  msg "[$(date)]" "$logfile"
  msg "Los servicios de todos los stacks:" "$logfile"
  msg "$stacks" "$logfile"
  msg " " "$logfile"
  msg "... todos están escalados a $replicas replica/s." "$logfile"
  msg "--------------------------------------------------------" "$logfile"
  msg " " "$logfile"
}
