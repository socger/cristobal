msg() {
  local mensaje=$1
  local logfile=$2

  echo "$mensaje"
  echo "$mensaje" >> "$logfile"
}
