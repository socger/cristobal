# Proyecto Cristobal

## Descripción
Sistema de gestión con Docker que incluye Traefik, mySQL, FacturaScripts y Portainer
Con tareas automatizadas de backup.

## Estructura del proyecto
- `/crontab/` - Configuración de tareas programadas
- `/docker/` - Se ha creado una estructura/esqueleto de los volúmenes usados por los stacks (.yml).
- `/docker/portainer/stacks` - Stacks/scripts (.yml) que se levantarán en un Docker Swarm
- `TODO` - Lista de tareas pendientes

## Características
- Backup automático diario a las 20:45
- Tareas de mantenimiento de FacturaScripts cada 5 minutos
- Gestión mediante contenedores Docker

## Instalación
[Instrucciones de instalación aquí]

## Uso
[Instrucciones de uso aquí]