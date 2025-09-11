Directorio donde se crearán los .sh usados tanto por los .yml, como por el propio crontab

backup_with_docker_pause.sh ... Copias de seguridad de los volúmenes de los stacks de docker. 
                                Básicamente de todo el contenido del path /docker
                                También hace una copia de todas las BD de mysql.
                                Por supuesto para stacks y los vuelve a levantar durante la copia de seguridad.
                                Se ejecuta desde el cron cada día a las 20:45

facturascripts_cron.sh ........ La app de facturascripts necesita, para tareas de segundo plano, que cada x tiempo se ejecute este .sh. 
                                Lo llamamos desde el crontab cada 5 minutos

init-data.sh .................. Es llamado desde el stack de docker para postgreSQL. 
                                Crea usuarios específicos y sus roles.
                                Pero de momento no he levantado postgresql, por lo que no se está usando este .sh

levantar.sh ................... Levanta todos los stacks que se hayan creado.

fn_msg.sh,
fn_scale_stacks.sh,
fn_scale_services.sh .......... Métodos/funciones llamadas usadas desde backup_with_docker_pause.sh y levantar.sh