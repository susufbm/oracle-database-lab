# Lab 3 — Instalación del entorno Oracle · Respuestas de comprobación

**Estudiante:** Jesús Fernández · **GitHub:** susufbm · **Issue:** #5 · **Branch:** `chore/5-install-oracle-environment`

Las referencias a evidencia apuntan a `docs/bitacora/evidencia/{script,spool,capturas}/`.

## Docker

**1. Imagen frente a contenedor (G2 y G4).**
La imagen es una plantilla de solo lectura, identificada por `nombre:etiqueta` y por su digest. El contenedor es una instancia viva creada a partir de ella, con su propio sistema de archivos temporal encima. En G2, `docker run hello-world` descargó la imagen `hello-world` y creó un contenedor (`suspicious_ride`) que imprimió su mensaje y terminó. En G4, con la misma imagen `alpine:3.20` creé `prueba` y, después, `prueba2`: dos contenedores distintos de una única plantilla. La imagen es la receta; el contenedor, el plato.

**2. ¿Por qué nota.txt desapareció en G5 y no en G6?**
En G5 el archivo se escribió en `/tmp` del sistema de archivos del contenedor `prueba`, que es una capa temporal. Al hacer `docker rm prueba` esa capa se borró, y `prueba2` nació de la plantilla limpia: `cat: can't open '/tmp/nota.txt'`. En G6 se escribió en `/datos`, donde estaba montado el volumen con nombre `datos-prueba`. El volumen vive fuera del contenedor, así que el segundo contenedor, nuevo y con `--rm`, encontró "dato importante".

**3. docker ps frente a docker ps -a; Exited (0).**
`docker ps` lista solo los contenedores en marcha; `docker ps -a` lista todos, también los detenidos. Por eso tras `docker run hello-world` el primero no mostraba nada y el segundo sí. `Exited (0)` significa que el proceso principal terminó con código 0, es decir, sin error. Un `Exited (1)` o mayor indica que terminó con error.

**4. En -p 8181:8181, ¿qué número es de mi equipo? ¿Y -p 80:8080 con nginx?**
El formato es `anfitrión:contenedor`: el primero es el puerto de mi equipo y el segundo el del contenedor. Con `-p 80:8080` publicaría el puerto 80 de mi equipo hacia el 8080 del contenedor, pero nginx escucha en el 80 del contenedor: no habría nadie al otro lado y la página no cargaría. Lo correcto, como hice en G7, es `-p 8080:80`.

**5. ¿Por qué Oracle se queda en marcha y hello-world no?**
Un contenedor vive lo que vive su proceso principal. El de `hello-world` imprime un mensaje y termina, así que el contenedor pasa a `Exited (0)`. El de Oracle arranca la instancia y se queda vigilándola indefinidamente, como en G4, donde `sh` siguió vivo hasta que escribí `exit`. Por eso `oralab-26ai` sigue `Up`.

**6. ¿Qué es el digest y por qué lo registramos usando :latest?**
Es la huella SHA-256 del contenido exacto de la imagen: dos imágenes con el mismo digest son idénticas bit a bit. `:latest` es una etiqueta móvil que apunta a una versión distinta cada vez que Oracle publica una nueva. Registrar el digest (evidencia 04: `sha256:f988b0c04c4c386cd306a2a914c0d7a9702d83acc31b064a28ad8eb6278a8fba`) deja constancia de qué versión exacta instalé, aunque `:latest` cambie mañana (*pin the version*).

**7. ¿Qué comando borraría de verdad los datos de Oracle? ¿Por qué docker rm no?**
`docker volume rm oralab-26ai-data`, o un `docker system prune -a --volumes` con el contenedor parado. Los datafiles viven en el volumen montado en `/opt/oracle/oradata`. `docker rm oralab-26ai` solo borra el contenedor y su capa temporal; el volumen sigue existiendo y un contenedor nuevo montado sobre él encuentra la base intacta, como en G6.

## Git, organización y evidencia

**8. ¿Por qué dentro del repositorio, con Issue, branch y PR?**
Porque instalar un entorno es un cambio de infraestructura más:
- **Reproducible:** con los scripts se reconstruye el entorno en una hora.
- **Verificable:** el reviewer ve los scripts y la salida real, no tiene que fiarse de que "funcionó".
- **Trazable:** el Issue #5 explica el porqué y el PR lo revisa otra persona.

En una carpeta aparte se perdería el historial, la protección de `main` y la revisión, y el resultado sería un *snowflake server* que nadie sabe reconstruir.

**9. source frente a bash con 00-config.sh.**
`bash 00-config.sh` lo ejecuta en una shell hija: las variables y la función `ts` mueren con ella. `source` lo ejecuta en mi shell actual, así que `CONT_NAME`, `EVID`, `ts`, etc. quedan disponibles para los comandos siguientes. Por eso se carga con `source` en cada terminal nueva.

**10. Partes del nombre 20260915T091230Z_02-docker.script.log.**
- `20260915T091230Z`: fecha y hora UTC en ISO 8601 compacto (año, mes, día, `T`, hora, minuto, segundo; `Z` = UTC). Ordena cronológicamente y no depende de la zona horaria.
- `02`: número del paso, que enlaza con `02-verificar-docker.sh` y con la Parte F.
- `docker`: descripción en kebab-case.
- `.script.log`: tipo de evidencia, salida de terminal (`.spool.log` sería SQL y `.png`, una captura).

**11. ¿Para qué sirve .gitattributes?**
Declara en el repositorio que `.sh`, `.sql` y `.md` se guardan con finales de línea LF (`eol=lf`), sea cual sea el sistema de quien edita. Evita que un script con CRLF de Windows falle en Linux con `$'\r': command not found` y que los diffs se llenen de cambios invisibles.

**12. ¿Por qué merge commit y no squash?**
Porque cada commit de este PR corresponde a una Parte (requisitos, Docker, práctica, imagen, contenedor, migraciones…) y tiene valor propio: se ve cuándo y cómo se verificó cada herramienta, con su evidencia. Un squash lo fundiría todo en un único commit y se perdería ese historial paso a paso.

## Seguridad

**13. Las cuatro capas de la Parte D y qué pasa si te saltas la primera.**
1. **`.gitignore` primero:** `config/.env` y `backups/` se ignoran antes de que exista el archivo con secretos.
2. **Plantilla versionada sin secretos:** `config/.env.example`, que documenta qué variables existen.
3. **Archivo real local:** `config/.env`, copiado de la plantilla, con las contraseñas reales y comprobado con `git check-ignore -v`.
4. **Leer sin teclear:** `set -a; source config/.env; set +a`, para que los scripts usen `"$ORACLE_PWD"` sin escribir nunca el valor.

Si me salto la primera, un `git add .` o `git add config/` metería la contraseña en un commit y quedaría para siempre en el historial.

**14. ¿Por qué no escribir la contraseña en docker run aunque el script no se suba?**
Todo lo que se teclea queda en texto plano en `~/.bash_history`. Además, la línea de comandos es visible para otros procesos (`ps -ef`) mientras se ejecuta. Con `"$ORACLE_PWD"` en el historial solo queda el nombre de la variable.

**15. Si la contraseña está en un commit publicado, ¿basta con borrarla?**
No: sigue en el historial y cualquiera puede recuperarla con `git log -p`, además de que GitHub la habrá escaneado. Hay que darla por comprometida y **rotarla**: cambiarla en `config/.env` y recrear o actualizar las cuentas afectadas. Después se limpia la rama o el historial si la política lo exige, y se avisa al docente. En una empresa sería un incidente de seguridad formal.

## Oracle y herramientas

**16. ¿Por qué no SPOOL ni @archivo.sql con sqlplus dentro del contenedor?**
Porque `sqlplus` corre dentro del contenedor: un SPOOL escribiría en el sistema de archivos del contenedor, no en mi repositorio, y `@archivo.sql` buscaría el archivo dentro del contenedor, donde no existe (SP2-0310). En su lugar envié el `.sql` del repositorio por la entrada estándar (`docker exec -i … sqlplus -s … < archivo.sql`) y capturé la salida en mi equipo con `tee` (evidencias 07 y 08).

**17. WHENEVER SQLERROR EXIT SQL.SQLCODE en V000 y V001.**
Hace que, ante el primer error SQL, sqlplus se detenga y devuelva el código de error. `08-aplicar-migraciones.sh` lo detecta (con `pipefail`) y no ejecuta V001 sobre un V000 fallido. Sin esa línea, sqlplus seguiría con las sentencias siguientes sobre un estado a medias (tablas sin usuario, usuarios sin tablespace) y el script terminaría como si todo hubiera ido bien.

**18. ¿Qué es una migración y por qué V000 y V001 no se editan?**
Es un script SQL versionado y numerado que lleva la base de un estado al siguiente, y que se aplica en orden (V000, V001…), como hacen Flyway o Liquibase. Una vez aplicada, es historia: si la edito, el repositorio ya no describe lo que se ejecutó, y quien reconstruya el entorno obtendrá una base distinta de la de sus compañeros. Las correcciones se hacen con una migración nueva.

**19. ¿Por qué FREEPDB1 en SQL Developer y no FREE ni un SID?**
La base es multitenant. El servicio `FREE` (o el SID `FREE`) conecta al contenedor raíz `CDB$ROOT`, que no es donde trabajamos. `FREEPDB1` es la PDB donde viven los 5 esquemas de negocio. Además, el listener anuncia servicios, no SIDs, así que con SID o con `FREE` se llega a la raíz o la conexión falla (ORA-12505).

**20. SQLcl frente a SQL*Plus.**
SQLcl se instala en mi equipo (Java), así que SPOOL escribe directamente en el repositorio. Además ofrece autocompletado, historial, formato automático (`SET SQLFORMAT ansiconsole`), conexiones guardadas (`CONNECT -save`, `CONNMGR`) e integración con Liquibase. SQL*Plus, en cambio, existe en cualquier servidor Oracle desde 1982: cuando solo tienes una terminal en el servidor de producción, es lo que hay. Un DBA necesita las dos.

## Entorno de trabajo

**21. ¿Por qué pasar de Git Bash a Ubuntu en WSL 2?**
Porque Oracle, Docker y los servidores de producción son Linux, y WSL 2 es un Linux real (kernel `microsoft-standard-WSL2`, evidencia 01), no una emulación. Problemas concretos de Git Bash que desaparecen:
- convierte rutas `/opt/...` a rutas de Windows y rompe argumentos de Docker;
- `docker run -it` falla con "not a TTY" y exige trucos como `winpty`; en mi grabación de la Parte G hay 0 errores de TTY;
- le faltan `free`, `ss`, `htop` y otras utilidades de administración;
- las herramientas Java tienen problemas al pedir contraseñas.

**22. ¿Por qué clonar en ~/oracle-database-lab y no en /mnt/c? ¿Y por qué bash y no zsh?**
- **Clonar en `~`:** en `/mnt/c` cada operación cruza entre dos sistemas de archivos, así que Git y Docker van varias veces más lentos, no se conservan los permisos de Linux (como el de ejecución) y vuelven los problemas de CRLF. Además, tener dos copias activas del repo lleva a cambios perdidos.
- **bash para los scripts:** es la shell que existe en todos los servidores. Un script bash funciona en cualquier sitio, mientras que zsh tiene diferencias sutiles (arrays, globbing, expansión) y no suele estar instalado en un servidor. zsh puede servir para el uso interactivo, pero los scripts compartidos se escriben en bash.
