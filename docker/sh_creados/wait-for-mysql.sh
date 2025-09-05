#!/bin/bash

echo "Esperando a que MySQL esté disponible..."

while ! (echo > /dev/tcp/mysql/3306) 2>/dev/null; do
  echo "MySQL no disponible aún, esperando..."
  sleep 5
done

echo "MySQL está disponible. Arrancando FacturaScripts..."
exec apache2-foreground
