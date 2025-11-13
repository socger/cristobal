# Agent.md - Sistema de Backup Automatizado

## 📖 **Descripción del Proyecto**

Sistema automatizado de backup para servicios Docker que incluye:
- **Pausa temporal** de stacks Docker durante el backup
- **Backup completo** del directorio `/docker` 
- **Volcado MySQL** incluido en el backup
- **Subida automática** a Google Drive
- **Limpieza automática** de archivos antiguos
- **Logging detallado** de todas las operaciones

## 🏗️ **Arquitectura del Sistema**

### **Componentes Principales:**

#### **Script Principal:**
- `backup_with_docker_pause.sh` - Orquestador principal del sistema

#### **Módulos Funcionales:**
```
fn_load_config.sh           # Carga de configuración y variables
fn_msg.sh                   # Sistema de logging y mensajes
fn_scale_stacks.sh          # Gestión de stacks Docker
fn_scale_services.sh        # Gestión de servicios Docker  
fn_get_date_and_logfile.sh  # Generación de timestamps y logs
fn_montar_hd.sh            # Montaje del dispositivo USB
fn_desmontar_hd.sh         # Desmontaje del dispositivo USB
fn_create_zip_backup.sh    # Creación del archivo de backup
fn_upload_to_gdrive.sh     # Subida a Google Drive
fn_delete_logs.sh          # Limpieza de logs antiguos
fn_verificar_servicios.sh  # Verificación de estado de servicios
fn_controlar_timeout.sh    # Control de timeouts en operaciones
```

#### **Configuración:**
- `.env` - Variables de configuración del sistema
- `load_config.sh` - Carga configuración específica

## ⚙️ **Variables de Configuración**

### **Directorios del Sistema:**
```bash
LOGS_DIR="/docker/logs"                           # Directorio de logs
SCRIPTS_DIR="/docker/sh_creados"                  # Directorio de scripts
SOURCE_DIR="/docker"                              # Directorio fuente a respaldar
LOG_FILE_BASENAME="backup_with_docker_pause_"     # Prefijo de archivos de log
```

### **Configuración USB:**
```bash
DISK_USB="/dev/sdb1"                              # Dispositivo USB
MOUNT_DISK_USB="/mnt/mount_disk_usb"              # Punto de montaje USB
```

### **Configuración MySQL:**
```bash
MYSQL_USER="root"                                 # Usuario MySQL
MYSQL_PASSWORD="sasa"                             # Contraseña MySQL
```

### **Políticas de Retención:**
```bash
BACKUP_RETENTION_DAYS="7"                         # Días para mantener backups
LOG_RETENTION_DAYS="2"                            # Días para mantener logs
```

### **Configuración Google Drive:**
```bash
GDRIVE_REMOTE="gNube:"                            # Configuración rclone
GDRIVE_BACKUP_DIR="backups"                       # Directorio en Drive
GDRIVE_PERMANENT_DELETE="true"                    # Eliminación permanente
```

## 🔄 **Flujo de Ejecución**

### **1. Inicialización**
```bash
1. Cargar configuración desde .env
2. Inicializar variables dinámicas (fecha, logfile)
3. Cargar todos los módulos funcionales
4. Limpiar contenedores Docker detenidos
```

### **2. Preparación del Backup**
```bash
5. Montar dispositivo USB de backup
6. Verificar servicios Docker activos
7. Crear volcado MySQL temporal
8. Pausar stacks Docker (escalar a 0 réplicas)
```

### **3. Proceso de Backup**
```bash
9. Fase 1: Copiar archivos principales (excluyendo logs)
10. Fase 2: Añadir logs al backup
11. Fase 3: Comprimir archivo final (.tar.gz)
12. Verificar integridad del backup creado
```

### **4. Subida a la Nube**
```bash
13. Subir backup a Google Drive usando rclone
14. Verificar que el archivo se subió correctamente
15. Limpiar backups antiguos en Google Drive (>7 días)
16. Eliminación permanente (sin papelera)
```

### **5. Limpieza y Restauración**
```bash
17. Eliminar volcado MySQL temporal
18. Limpiar backups antiguos del USB (>7 días)
19. Limpiar logs antiguos del sistema (>2 días)
20. Restaurar stacks Docker (escalar a réplicas originales)
21. Desmontar dispositivo USB
22. Apagar sistema (poweroff)
```

## 🛠️ **Funcionalidades Avanzadas**

### **Gestión Inteligente de MySQL:**
- **Timeout handling:** Si MySQL tarda en escalar, reinicia el stack completo
- **Stack restart:** Equivalente a Stop→Start en Portainer
- **Health checks:** Verificación de estado antes de continuar

### **Sistema de Logging Robusto:**
- **Logs detallados** de cada operación
- **Timestamps** en todas las entradas
- **Logging separado** para rclone
- **Rotación automática** de logs antiguos

### **Verificaciones de Integridad:**
- **Verificación de archivos** antes de subir
- **Confirmación de subida** a Google Drive
- **Validación de compresión** exitosa
- **Checks de montaje** de dispositivos

### **Manejo de Errores:**
- **Restauración automática** de servicios en caso de error
- **Limpieza de archivos temporales** en fallos
- **Logging de errores** detallado
- **Exit codes** apropiados

## 📊 **Métricas y Monitoreo**

### **Información de Backup:**
- **Tamaño del archivo** generado
- **Tiempo de compresión** y subida
- **Velocidad de transferencia** a Google Drive
- **Archivos eliminados** en limpieza

### **Estado de Servicios:**
- **Servicios pausados** y restaurados
- **Timeouts** en escalado de servicios
- **Errores de MySQL** y reintentos
- **Estado final** de todos los stacks

## 🔧 **Comandos de Mantenimiento**

### **Verificar Estado:**
```bash
# Ver logs del último backup
tail -f /docker/logs/backup_with_docker_pause_$(date +%Y%m%d).log

# Verificar configuración de rclone
rclone config show

# Listar backups en Google Drive
rclone ls gNube:backups/

# Verificar espacio en USB
df -h /mnt/mount_disk_usb
```

### **Operaciones Manuales:**
```bash
# Probar conectividad con Google Drive
rclone lsd gNube:

# Limpiar papelera de Google Drive
rclone cleanup gNube:

# Verificar servicios Docker
docker stack ls
docker service ls
```

## 🚨 **Resolución de Problemas**

### **Problemas Comunes:**

#### **MySQL no escala correctamente:**
- **Síntoma:** Timeout en escalado de servicios
- **Solución:** El sistema reinicia automáticamente el stack completo

#### **Error de subida a Google Drive:**
- **Síntoma:** "didn't find section in config file"
- **Solución:** Verificar configuración de rclone con `rclone config`

#### **USB no monta:**
- **Síntoma:** Error en montaje del dispositivo
- **Solución:** Verificar que el dispositivo esté conectado y `DISK_USB` sea correcto

#### **Archivos no se eliminan de Google Drive:**
- **Síntoma:** El espacio no se libera después de limpieza
- **Solución:** Usar `--drive-use-trash=false` para eliminación permanente

## 📅 **Estado Actual del Proyecto**

### **✅ Implementado:**
- [x] Sistema de backup completo funcional
- [x] Subida automática a Google Drive
- [x] Limpieza automática de archivos antiguos
- [x] Gestión robusta de servicios Docker
- [x] Sistema de logging detallado
- [x] Configuración modular con .env

### **🔄 En Seguimiento:**
- [ ] Verificar limpieza automática (USB y Google Drive)
- [ ] Validar integridad de backups descargados
- [ ] Monitoreo a largo plazo del sistema

### **🚀 Mejoras Futuras:**
- [ ] Notificaciones por email/Slack en fallos
- [ ] Dashboard web para monitoreo
- [ ] Backup incremental para optimizar tiempo
- [ ] Múltiples destinos de backup (redundancia)

## 📞 **Contacto y Soporte**

- **Desarrollador:** Sistema desarrollado para entorno Docker personalizado
- **Logs:** Ubicados en `/docker/logs/`
- **Configuración:** Archivo `.env` en directorio de scripts
- **Documentación:** Este archivo Agent.md

---

**Última actualización:** $(date +%Y-%m-%d)
**Versión:** 1.0
**Estado:** Producción - Funcional
