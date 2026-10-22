# Lab 4 v3 — Oracle DBA Workflow I · Respuestas

**Estudiante:** Jesús Fernández · **GitHub:** susufbm · **Issue:** #7 · **Branch:** `chore/7-oracle-dba-workflow-i`

Evidencias en `docs/bitacora/lab4/evidencia/{script,spool,config}/` (ejecución del 2026-10-22, UTC). Cuando digo "evidencia NN" me refiero al archivo `*_NN-*` correspondiente.

---

## Puntos de control

**A.4 — Archivos FUERA.** En el paso 3 de la copia (evidencia 00) salieron **0 archivos FUERA** (`archivos_fuera_del_volumen=0` en el manifiesto). Los cinco datafiles de negocio (`academia01.dbf` … `fintech01.dbf`) se crearon en `$ORACLE_HOME/dbs` porque V000 usó rutas relativas y `db_create_file_dest` estaba vacío (evidencia 01, bloque 5: "vacío: sin OMF"). Pero en la imagen oficial `$ORACLE_HOME/dbs` es un enlace simbólico al volumen: `/opt/oracle/product/26ai/dbhomeFree/dbs -> /opt/oracle/oradata/dbconfig/FREE/dbs` (evidencia 01, bloque B). Por eso `readlink -f` los da como "dentro". El diagnóstico lo confirma: "DENTRO del volumen, pero en carpeta no estándar". Sobrevivían a `docker rm`, pero en una carpeta donde ningún DBA los buscaría y dependiendo de un enlace que una actualización de la imagen podría cambiar. La corrección (Parte C) fue la misma: llevarlos a `FREE/FREEPDB1`.

**E.3 — ORA-01507 y ORA-01219.**
- **ORA-01507 en NOMOUNT:** `v$database` lee el control file, que todavía no está abierto. `v$parameter` sí responde, porque los parámetros ya se leyeron del SPFILE y están en memoria (`spfile` y `control_files` aparecen en la evidencia 06).
- **ORA-01219 en MOUNT:** `dba_tables` es una vista del diccionario, que vive en el tablespace SYSTEM, y ese datafile sigue cerrado. Solo funcionan las vistas fijas (V$/X$).
- **Total System Global Area = 1 603 398 928 bytes**, la suma de Fixed 5 033 232 + Variable 436 207 616 + Database Buffers 1 157 627 904 + Redo 4 530 176. Coincide con `v$sga` de la evidencia 08: 4,8 + 432 + 1088 + 4,3 MB.
- FREEPDB1 se abrió sola: "abierta sola en READ WRITE: el estado guardado funciona", con `dba_pdb_saved_states = FREEPDB1 · FREE · OPEN`.

**G.2 — Caché.** En la ronda 1 hubo **357 lecturas lógicas y 261 físicas**; en la ronda 2, **247 y 0**. `v$bh` deja 245 bloques en caché (evidencia 08-experimento-cache).
- **Por qué hay más lógicas en la ronda 1:** además de los bloques de la tabla, la primera ejecución analizó la sentencia y lanzó consultas recursivas al diccionario, que también cuentan como lecturas de la sesión. En la ronda 2 el cursor ya estaba compilado y solo quedan las 247 de la tabla. Que en las dos haya lecturas lógicas es porque toda lectura física termina en una lógica: el bloque se trae a la caché y se lee desde ahí.
- **Por qué hay 261 físicas para 244 bloques:** 244 bloques de la tabla + la cabecera del segmento = 245 (los 245 de `v$bh`), y el resto son bloques del diccionario leídos por esas consultas recursivas.
- **Tasa de acierto:** ronda 2 = 1 − 0/247 = **100 %**; ronda 1 = 1 − 261/357 ≈ **26,9 %**.

**G.4 — PGA.** Ordenar las 60 000 matrículas requería ~**2675 KB** (KB_OPTIMO):
- **Con PGA automática:** OPTIMAL, 2377 KB usados, 0 KB en TEMP, 20 ms.
- **Con 64 KB manuales:** Oracle usó 65 KB, escribió **2048 KB en TEMP** y releyó **6 veces** (`6 PASSES`), en 150 ms: 7,5 veces más lento con una tabla pequeña.

En mi ejecución `maximum PGA allocated` (428,1 MB) **no** llegó a superar `pga_aggregate_target` (512 MB). Aun así es un objetivo, no un límite: el límite duro es `pga_aggregate_limit` = 2G (ORA-04036). El histograma de la instancia dice 3084 óptimas / 0 de una pasada / **2 de varias pasadas**, y esas 2 son las de mi experimento con 64 KB.

**I.2 — Contenedores.**
- **Por qué `V$LOG` sale con CON_ID 0** (3 filas, una por grupo de redo): el redo es de toda la CDB, con una instancia y un único juego de redo compartido por todas las PDB. No pertenece a ningún contenedor concreto.
- **Qué ve C##LAB4_AUDITOR:** 93 sesiones con CON_ID 0 y 1 con CON_ID 1, pero ninguna de FREEPDB1, porque le falta CONTAINER_DATA. Lo cambiaría `ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;`.
- **Con `SELECT ANY TABLE`:** LAB4_ANALISTA habría podido leer también ADMIN_CLINICA (datos de pacientes) y cualquier otro esquema de la PDB. El privilegio de esquema lo limitó a ADMIN_ACADEMIA (ORA-00942 en `admin_clinica.cli_pacientes`).

**J.3 — Archivos.**
- **Por qué el password file es "relacionado":** guarda credenciales de usuarios administrativos (`v$pwfile_users`: solo SYS, con SYSDBA y SYSOPER), no datos. Sin él la base abre y funciona, y SYSDBA local por autenticación del SO sigue funcionando. Solo se pierde SYSDBA por red.
- **A dónde apuntan SPFILE y password file:** aparecen en `$ORACLE_HOME/dbs`, que en esta imagen es un enlace entero a `/opt/oracle/oradata/dbconfig/FREE/dbs`. Viven en el volumen y sobreviven a `docker rm` y a cambiar la imagen.
- **Por qué TEMP no se respalda:** solo contiene datos de trabajo de las sesiones (ordenaciones, hash). No hay nada que recuperar; si se pierde, se recrea vacío.

**K.4 — Volcado del bloque 781.**
- **`avsp = fseo − fsbo`:** 0x427 − 0xc6 = **0x361**; en decimal, 1063 − 198 = **865** bytes ✔. Coincide con `tosp`.
- **Fecha de registro de la fila 101** (col 6, Typ=180): bytes `78 7e 0a 16 12 10 21`. Siglo 0x78 − 100 = 20; año 0x7e − 100 = 26 → 2026. Mes 0x0a = 10; día 0x16 = 22. Hora 0x12 − 1 = 17; minuto 0x10 − 1 = 15; segundo 0x21 − 1 = 32. Resultado: **2026-10-22 17:15:32**, el momento en que apliqué V002. Los 4 bytes siguientes son las fracciones de segundo.
- **Qué pasaría con un UPDATE de la fila 101:** usaría la **ranura libre 0x02** de la ITL. La 0x01 es de una transacción ya confirmada (Flag `--U-`). Al tocar el bloque, Oracle comprobaría en el undo que esa transacción terminó y haría la *delayed block cleanout*: pondría a 0 el `Lck 90` y los `lb` de las filas. Por eso un DML, e incluso un SELECT, puede generar redo de limpieza.

---

## 8. Preguntas de comprobación

### 8.1 Respaldo y diagnóstico (A)

**1. ¿Por qué la copia es consistente? ¿Y con la base abierta?**
Se tomó tras `SHUTDOWN IMMEDIATE` y `docker stop` (evidencia 00: "Database closed / dismounted / ORACLE instance shut down"). El cierre limpio hace un checkpoint final: todos los datafiles comparten el mismo SCN de checkpoint, coherente con el control file, y no queda redo pendiente. Restaurada, abre directamente sin recuperación. Con la base abierta, DBWn seguiría escribiendo durante el `tar`, y los archivos tendrían SCN distintos y bloques a medias (copia inconsistente o *fuzzy*). Mi base está en ARCHIVELOG (`log_mode=ARCHIVELOG` en el inventario), así que en teoría se podría recuperar con redo archivado y RMAN. Pero una copia con `tar` de una base abierta no es una copia válida de RMAN, y no hay garantía de tener todo el redo necesario.

**2. manifiesto.txt, SHA256SUMS y qué comprueba restaurar-estado.sh.**
`manifiesto.txt` dice qué es la copia: `etiqueta=lab3-final`, `fecha_utc=20261022T171331Z`, contenedor, volumen, imagen, `git_commit=1a74a9b`, tipo (copia en frío consistente) y `archivos_fuera_del_volumen=0`. `SHA256SUMS` guarda la huella de cada archivo; la verifiqué con `sha256sum --check` y salió íntegra. Antes de tocar nada, `restaurar-estado.sh` comprueba que Docker responde y ejecuta `sha256sum --check`: si un byte cambió, se detiene. Después exige escribir el nombre del volumen (salvo `--si`).

**3. RPO y RTO con mi copia.**
- **RPO:** todo lo hecho desde `20261022T171212Z_lab3-final` (490 MB comprimidos de un volumen de 4742 MB). Restaurar me devuelve al final del Lab 3: se pierde el Lab 4.
- **RTO:** no he hecho todavía el simulacro (es del Lab 5). Mi estimación, con datos medidos: descomprimir 490 MB más el arranque. En la copia, la base pasó de arrancada a `READWRITE/READWRITE` en ~10 s, y el reinicio completo de la Parte E tardó 7,6 s. Calculo **alrededor de un minuto**, como en el entorno de pruebas del curso.

### 8.1.1 Correcciones del Lab 3 (C, D)

**4. ¿Dónde creó Oracle los datafiles de V000 y por qué? ¿Qué parámetro lo habría evitado?**
En `$ORACLE_HOME/dbs` (evidencia 01, bloque 4: `/opt/oracle/product/26ai/dbhomeFree/dbs/academia01.dbf`, files 16–20). V000 usó rutas relativas y sin `DB_CREATE_FILE_DEST` Oracle las resuelve desde `$ORACLE_HOME/dbs`; en esta imagen eso cae en `/opt/oracle/oradata/dbconfig/FREE/dbs`, una carpeta no estándar. Lo habría evitado **`DB_CREATE_FILE_DEST`** (OMF) apuntando al volumen, o escribir rutas absolutas. Lo dejé aplicado en el reto C: un `CREATE TABLESPACE tbs_x;` se creó en `/opt/oracle/oradata/FREE/55E54F21…/datafile/o1_mf_tbs_x_….dbf`.

**5. ¿Por qué RENAME DATAFILE no basta?**
Porque solo cambia la ruta guardada en el control file: no mueve nada en disco. `03-reubicar-datafiles.sh` lo hace en orden: tablespace OFFLINE NORMAL (checkpoint), `cp -p` del archivo, RENAME, ONLINE (Oracle valida la cabecera) y, solo entonces, borra el original. El método online (`MOVE DATAFILE`) no existe en Free.

**6. ¿Por qué no se edita V000 y por qué invalidar es mejor que borrar?**
Una migración aplicada es historia: quien reconstruya el entorno con V000…V003 debe llegar al mismo estado (*forward-only migrations*), así que la corrección es una migración nueva. Borrar la contraseña del archivo no la quita del historial de Git (`git log -p`). Invalidarla (`ALTER USER … NO AUTHENTICATION`, V003) hace que no sirva aunque alguien la conozca. Comprobado: `admin_academia/"Academia_2026_*"` da **ORA-01017**, y las cinco cuentas ADMIN_* muestran `AUTHENTICATION_TYPE = NONE`.

**7. ¿Qué demuestra la prueba de persistencia y por qué va después de reubicar?**
Que toda la base vive en el volumen. Borré `oralab-26ai`, lo recreé con `05` v2 y siguen los 5 tablespaces en `/opt/oracle/oradata/FREE/FREEPDB1/` y los 5 esquemas con 3/3/2/3/3 tablas (evidencia 03, ANTES/DESPUÉS). El `HOST_NAME` cambió de `33d8e3c19409` a `e93aa02e2502`, porque es otro contenedor sobre la misma base, y `docker port` ya solo publica 1521. Va después de reubicar porque, con los archivos fuera del volumen, `docker rm` los habría destruido. En mi caso estaban dentro gracias al enlace, pero el orden protege del caso general.

### 8.1.2 Instancia, arranque y parámetros (E, F)

**8. Tres datos de la instancia y tres de la base.**
Fuente: evidencias 05 y 15.
- **Instancia:**
  - `STARTUP_TIME` 2026-10-22 17:15:16, que cambió a 17:16 tras el reinicio de la Parte E;
  - `HOST_NAME` `e93aa02e2502`, el contenedor, que cambió en la Parte C;
  - SGA de 1536 MB y 63 procesos `db_*_FREE`.
- **Base de datos:**
  - `DBID` 1509902213, que no cambió al recrear el contenedor;
  - `CREATED` 2026-07-05, cuando se construyó la imagen;
  - `LOG_MODE ARCHIVELOG` y sus archivos: 16 datafiles (3944 MB), 2 control files y 3 miembros de redo.

**9. Qué lee Oracle en cada etapa.**
- **NOMOUNT:** lee el SPFILE, reserva la SGA y arranca los procesos. `v$database` da **ORA-01507**.
- **MOUNT:** lee los control files de `control_files` y conoce los 16 datafiles y el redo sin abrirlos. `dba_tables` da **ORA-01219**.
- **OPEN:** abre datafiles y redo, con recuperación de instancia si hace falta. En el alert log: "Crash Recovery excluding pdb 2/3 which was cleanly closed", "Thread 1 opened at log sequence 2".

**10. v$parameter frente a v$spparameter con db_files.**
`v$parameter` muestra el valor en memoria; `v$spparameter`, lo escrito en el SPFILE. En la evidencia 07: tras `SET db_files=300 SCOPE=SPFILE`, memoria **200** y SPFILE **300**, un cambio pendiente del próximo arranque. Tras `RESET db_files SCOPE=SPFILE`, memoria 200 y SPFILE **(no especificado)**: vuelve a su valor por defecto. `16-verificacion-final` confirma `db_files_spfile = FALSE`.

**11. ¿Por qué PROCESSES rechaza el cambio en memoria aunque v$parameter diga IMMEDIATE?**
Porque dimensiona estructuras de la SGA que se reservan al arrancar, y de él se derivan SESSIONS (322) y otros. En la evidencia 07, bloque 4, sale **ORA-02097 + ORA-02095** aunque la evidencia 07-lectura muestra `SYS_MOD = IMMEDIATE`. En la práctica es estático: se cambia con `SCOPE=SPFILE` y un reinicio.

### 8.1.3 Memoria y procesos (G, H)

**12. Modelo de gestión de memoria.**
**ASMM** (evidencia 08-memoria):
- `memory_target = 0` y `memory_size = 0`: no es AMM.
- `sga_target = 1536M`: Oracle reparte la SGA (buffer cache 1008 MB y shared pool 400 MB, con 1 ajuste cada uno en `v$sga_dynamic_components`).
- `pga_aggregate_target = 512M` con `pga_aggregate_limit = 2G`: la PGA va aparte.

`db_cache_size = 0` y `shared_pool_size = 0` significan "sin mínimo fijado".

**13. Experimento de caché.**
`ACA_ESTUDIANTES` = 244 bloques. Ronda 1, caché fría: 357 lógicas y 261 físicas. Ronda 2: 247 lógicas y **0 físicas**, con 245 bloques en `v$bh`. Tasa de acierto de la ronda 2 = 100 %; la de la ronda 1, ≈ 27 %. La diferencia entre rondas está explicada en el punto de control G.2.

**14. Literales frente a variables de enlace.**
Evidencia 08-parse-y-pga:

| | Literales | `:id` |
|---|---|---|
| Análisis totales | 1051 | 1 |
| Análisis duros | 1008 | 1 |
| CPU de análisis | 570 ms | 0 ms |
| Tiempo total | 630 ms | 10 ms |
| Cursores en V$SQL | 587 (de 1000; el resto, expulsados) | 1, con 1000 ejecuciones |
| Shared pool | 21 419 KB | 39 KB |

Con literales, cada texto es una sentencia nueva: 1000 análisis duros, más 8 recursivos. El 90 % del tiempo se fue en analizar, no en ejecutar, y se usó ~550 veces más shared pool. Con `:id` hay un cursor compartido que PL/SQL mantiene abierto (session cursor cache): 1 análisis. Mi reto G (`08-reto-literales.sql`) encuentra esa sentencia agrupando por `force_matching_signature`: **501** cursores distintos con la misma firma.

**15. SPID de LGWR frente a /proc y docker top.**
`09-procesos.sql` da LGWR con **SPID 739**, y `09-procesos-so.sh 739` muestra `739  103  db_lgwr_FREE` leyendo `/proc` dentro del contenedor: es el mismo proceso. `docker top` da otros números (por ejemplo PMON 6985 en el anfitrión frente a 688 dentro, evidencias 05-so y 09-so) porque muestra el PID del **anfitrión**. El contenedor tiene su propio *PID namespace* y Oracle guarda el PID visto desde dentro. Además, `v$process` cuenta 91 procesos de fondo frente a 58 PIDs Linux: algunos procesos Oracle son hilos dentro de un mismo proceso.

### 8.1.4 Contenedores (I)

**16. 16 datafiles desde la raíz y 9 desde FREEPDB1.**
Evidencia 10-que-ve-cada-usuario:
- **Desde CDB$ROOT**, las V$ no se filtran: CON_ID 1 → 4, CON_ID 2 → 3 y CON_ID 3 → 9, en total 16.
- **Dentro de FREEPDB1** todo se filtra por el contenedor actual: solo los 9 de CON_ID 3, y `CDB_TABLESPACES` = `DBA_TABLESPACES` = 10.

**17. ¿Por qué ORA-00942 y no "privilegios insuficientes" en DBA_TABLES?**
Porque Oracle no revela la existencia de objetos que no puedes ver: sin privilegio sobre `SYS.DBA_TABLES` responde lo mismo que si no existiera. Pasó igual con `V_$SESSION` y con `ADMIN_ACADEMIA.ACA_ESTUDIANTES`. Cuando el objeto sí es visible y falta la acción, 23ai es explícito: el UPDATE dio **ORA-41900: missing UPDATE privilege**. Y la operación sin privilegio (`ALTER SESSION SET CONTAINER`) dio **ORA-01031**.

**18. C##LAB4_AUDITOR frente a C##OPS_RO.**
Los dos son comunes y tienen `CREATE SESSION`, `SET CONTAINER` y `SELECT_CATALOG_ROLE`. Solo C##OPS_RO tiene el atributo **CONTAINER_DATA = ALL** (`cdb_container_data`: `C##OPS_RO · Y · Y`; el auditor no aparece). Por eso, desde la raíz, el auditor solo ve 5 tablespaces (CON_ID 1), mientras que C##OPS_RO ve 15 (5 + 10). Los igualaría `ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;`.

**19. GRANT READ ANY TABLE ON SCHEMA: ventaja y riesgo.**
- **Ventaja:** un único GRANT da lectura de las 3 tablas de ADMIN_ACADEMIA (20 000 estudiantes) y de las que se creen después, y de ningún otro esquema. Además es READ: no permite `SELECT … FOR UPDATE` ni DML (ORA-41900).
- **Riesgo:** también cubre tablas futuras, quizá sensibles, que nadie revisó, y no permite excluir tablas ni columnas. Hay que auditarlo y revocarlo al terminar.

**20. COMMON_USER_PREFIX y el bloque 3a.**
En mi base vale **C##** (imagen oficial). Por eso `CREATE USER lab4_local` en la raíz falló con **ORA-65096: common user or role name must start with prefix C##**. En la raíz solo se crean usuarios comunes, que deben llevar el prefijo. El 3b dio ORA-65094 (C## desde una PDB) y el 3c creó LAB4_LOCAL como local en FREEPDB1.

### 8.1.5 Archivos (J)

**21. Clasificación de la evidencia 11.**
- **Son la base:** 16 datafiles (3944 MB), 3 tempfiles (60 MB, que no se copian), 2 control files (36 MB) y 3 grupos de redo online de un miembro (600 MB).
- **Relacionados:** SPFILE, password file (formato 12, solo SYS), ADR (`diagnostic_dest=/opt/oracle`) y **1 redo archivado de 66 MB**, porque la base está en ARCHIVELOG.

El password file va en **relacionados**: guarda credenciales administrativas, no datos.

**22. ¿Por qué academia01.dbf mide 104 865 792 bytes?**
100 MB = 104 857 600 bytes, más 8192 bytes del bloque 0 (la cabecera del archivo, que Oracle no cuenta como espacio útil): 104 857 600 + 8192 = **104 865 792** (evidencia 11-archivos-so). Lo mismo con el redo: `redo01.log` = 209 715 712 = 200 MB + 512 bytes, porque su bloque es de 512 bytes.

**23. Dos puntos únicos de fallo.**
1. **Los dos control files están en la misma carpeta** (`/opt/oracle/oradata/FREE/control01.ctl` y `control02.ctl`): un fallo de ese disco o carpeta se lleva los dos.
2. **Un solo miembro por grupo de redo** (3 grupos de 200 MB): si se daña el miembro CURRENT, se pierden cambios confirmados.

Además, la base archiva pero **sin FRA** (`db_recovery_file_dest` vacío): los archivados no tienen destino gestionado ni límite de espacio.

**24. ¿Por qué el ADR fuera del volumen es un problema?**
`11-archivos-so`, bloque 4: "NO: /opt/oracle/diag vive en la capa del contenedor". Recrear el contenedor no pierde datos, pero borra el alert log (102 KB) y las 218 trazas (29 MB de ADR), justo la historia que necesita un postmortem. De hecho, el alert log que leí tras la Parte C empieza en el arranque de ese contenedor nuevo.

### 8.1.6 Bloque y fila (K)

**25. ROWID del estudiante 101.**
`AAAR2kAAAAAAAMNAAF` = OOOOOO FFF BBBBBB RRR (A=0…Z=25, a=26…z=51, 0=52…9=61):
- **Objeto** `AAAR2k` = 17·64² + 54·64 + 36 = **73 124** = `DATA_OBJECT_ID` de ACA_ESTUDIANTES ✔.
- **Archivo** `AAA` = 0: en BIGFILE no hay archivo relativo. El real es `ROWID_TO_ABSOLUTE_FNO` = **16** (`academia01.dbf`, relative_fno 1024).
- **Bloque** `AAAAMN` = 12·64 + 13 = **781** = `ROWID_BLOCK_NUMBER(rowid,'BIGFILE')` ✔. Está en la extensión 0, bloques 776–783.
- **Fila** `AAF` = **5**, la sexta ranura ✔.

**26. nrow, fsbo, fseo y avsp.**
- `nrow = 90`: filas en el bloque.
- `fsbo = 0xc6`: inicio del hueco libre, tras el directorio de filas.
- `fseo = 0x427`: fin del hueco, donde empiezan las filas, que crecen hacia atrás.
- `avsp = 0x361`: espacio disponible.

Comprobación: 0x427 − 0xc6 = 0x361 → 1063 − 198 = **865** = avsp ✔.

**27. ITL con Lck = 90 y Flag --U-.**
La ranura 0x01 registra la transacción que cargó las 90 filas (V002): Xid `0x0003.01b.00000225`, su Uba de undo y el flag **U** (*upper bound commit*: confirmada). Sigue marcando las 90 filas (`Lck 90`, `lb: 0x1` en la fila 101). Es la **limpieza diferida de bloques**: para que el COMMIT sea instantáneo, Oracle no recorre los bloques modificados. La próxima sesión que toque el bloque verá en el undo que la transacción terminó y lo limpiará. En mi reto K, el bloque 1166 tiene **la misma Xid** con `Lck 85`: misma transacción, misma limpieza pendiente.

**28. Los 78 bytes de la fila 101.**
3 bytes de cabecera (`fb`, `lb`, `cc`) + 7 bytes de longitud (uno por columna) + 68 bytes de datos (3 + 9 + 9 + 11 + 19 + 6 + 11) = **78** = `tl: 78` ✔. Con los 2 bytes de su entrada en el directorio ocupa 80 bytes en el bloque. AVG_ROW_LEN (76) no cuenta el directorio.

### 8.1.7 Capacidad y coste (L)

**29. bfr y b de ACA_ESTUDIANTES.**
Con la fórmula de la Unidad 3: bfr = floor((8192 − 96) · 0,9 / 76) = **95**, así que b = ceil(20 000 / 95) = **211**. Con la versión Oracle (H = 122, R + 2): bfr 93, b 216. La tabla real tiene **244** bloques bajo la HWM (evidencia 13) porque:
- la cabecera real incluye ITL, y cada fila ocupa 2 bytes más de directorio;
- las filas varían: el factor medido va de 68 a 95, con media 86,6, en 231 bloques con filas;
- quedan 13 bloques casi vacíos (FS4) al final del segmento, bajo la HWM (evidencia 12, `DBMS_SPACE`).

Asignados hay 256, porque el espacio se reserva por extensiones.

**30. Coste de cada lectura.**
- **Lógica:** **1,48 µs** (5a: 590 ms de CPU / 400 000 lecturas, a 4 por búsqueda).
- **Física aleatoria:** **6,4 µs** (5b: 35 ms / 5464 lecturas).
- **Secuencial:** **~4,4 µs** por bloque (5c: 20,1 ms / 4595 bloques, ~87 bloques por petición, Bw 1790 MB/s).

Media de la instancia: `db file sequential read` 33 µs y `db file scattered read` 37 µs.

**31. Umbral con HDD (Bw = 150 MB/s, lat = 5 ms).**
c_sec = 8192 B / (150 · 1 048 576 B/s) ≈ **52 µs** por bloque, y c_aleat = **5000 µs**, así que el cociente es ≈ **0,0104**. Umbral k/r < (1/86) · 0,0104 ≈ **0,012 %** de las filas. En mi contenedor salió 0,79 % (cociente 0,682).

**32. ¿Por qué la "lectura física" sale en µs? ¿Invalida el método?**
`FLUSH BUFFER_CACHE` vacía la caché de Oracle, no la caché de páginas de Linux: muchas "físicas" se sirven desde RAM. **No invalida el método**: las fórmulas y las medidas son las mismas, y solo cambian los valores del hardware. Con disco real (0,1–10 ms) el umbral baja dos órdenes de magnitud (pregunta 31), y por eso se mide en cada sistema.

### 8.1.8 Filas migradas y encadenadas (M)

**33. Migración frente a encadenamiento.**

| | Migración | Encadenamiento |
|---|---|---|
| Causa | Un UPDATE agranda una fila que ya no cabe en su bloque. En MIGRA, 1 de cada 5 filas pasó de 1 a 300 bytes con PCTFREE 0 | La fila es mayor que un bloque: ANCHA, de ~12 000 bytes, en bloques de 8 KB |
| Qué queda en el bloque original | La cabeza (`fb: --H-----`, `cc: 0`) con `nrid: 0x00001623.25a` | La primera pieza, enlazada con las demás |
| Detección | `ANALYZE … COMPUTE STATISTICS` (CHAIN_CNT 1000 = 20 %), `LIST CHAINED ROWS` (1000 filas) y `table fetch continued row` | Igual (CHAIN_CNT 1 en ANCHA) |
| Cura | `ALTER TABLE … MOVE (ONLINE)` con PCTFREE adecuado: con 20 %, CHAIN_CNT 0 y 63 bloques | No se cura reorganizando: bloque mayor (16/32 KB) o rediseño (LOB o tabla aparte) |

**34. El 3,2 de lecturas por búsqueda.**
Una búsqueda normal cuesta 3 lecturas (índice de 2 niveles + bloque de tabla), y las filas migradas cuestan 4. De las 1000 búsquedas, 200 tocaron filas migradas (`table fetch continued row = 200`): (800 · 3 + 200 · 4) / 1000 = **3,2** (3200 lecturas lógicas). Es un 7 % más de trabajo en cada acceso, para siempre.

**35. ¿Por qué MOVE deja el índice UNUSABLE? ¿Y en producción?**
MOVE reescribe las filas en bloques nuevos: todas cambian de ROWID y PK_MIGRA apuntaba a los viejos, así que quedó **UNUSABLE**. Volvió a **VALID** tras `ALTER INDEX … REBUILD`. Mientras tanto, una consulta que lo necesite falla (ORA-01502) o hace FULL SCAN, y un INSERT con índice único falla. En producción usaría **`ALTER TABLE … MOVE ONLINE`**, que mantiene los índices válidos y no bloquea el DML, y recogería estadísticas al terminar.

### 8.1.9 Autopsia y trabajo profesional (N, O)

**36. Tres hallazgos de mi autopsia (15).** El detalle está en `docs/bitacora/lab4-autopsia.md`.
1. **ARCHIVELOG sin FRA** (sección 1: `LOG_MODE ARCHIVELOG`; sección 4: `db_recovery_file_dest` vacío y tamaño 0; 1 archivado de 66 MB). Riesgo: los archivados no tienen destino gestionado ni límite, y si su disco se llena la base se detiene. Acción: configurar FRA con tamaño (Lab 5). **Prioridad alta.**
2. **Control files en la misma carpeta y redo con un miembro por grupo** (sección 4 y evidencia 11). Riesgo: punto único de fallo. Acción: multiplexar en otra ubicación (Lab 5). **Prioridad alta.**
3. **ADR fuera del volumen** (evidencia 11-archivos-so). Riesgo: el alert log se pierde al recrear el contenedor; ya pasó en la Parte C. Acción: `diagnostic_dest` persistente o logs centralizados. **Prioridad media.**

**37. ¿Por qué C##OPS_RO y no SYSTEM? ¿Qué no puede hacer?**
Por mínimo privilegio: para mirar no hace falta poder romper. SYSTEM puede crear, borrar y alterar objetos y usuarios; un despiste o una contraseña filtrada sería un incidente. C##OPS_RO solo tiene:
- `CREATE SESSION`, `SET CONTAINER` y `SELECT_CATALOG_ROLE`;
- `CONTAINER_DATA = ALL`;
- el `SELECT` puntual sobre `V_$DIAG_ALERT_EXT`.

**No puede** modificar datos ni objetos, cambiar parámetros, parar la base, crear usuarios ni conceder privilegios. `16-verificacion-final` lo comprueba: "C##OPS_RO sin privilegios ANY de escritura (0)".

**38. Las dos vías de exposición de contraseñas que se corrigen.**
1. **Contraseñas en el repositorio:** V000 tenía las de los 5 propietarios de esquema. V003 las invalida (`NO AUTHENTICATION`, ORA-01017 comprobado).
2. **SYS en la línea de comandos:** el `08` del Lab 3 pasaba `sys/<contraseña>@…`, visible con `ps` y en el historial. El `08` v2 usa `/ as sysdba`.

Además, `05` v2 no pasa `ORACLE_PWD` al reutilizar el volumen, y `ro.sh` y `02` mandan la contraseña por stdin.

---

## Preguntas tipo examen

| P | Resp. | Justificación |
|---|---|---|
| P1 | **A, D** | Tras SHUTDOWN IMMEDIATE todas las cabeceras tienen el mismo SCN: es consistente y abre con STARTUP sin redo. No exige ARCHIVELOG ni RMAN (mi copia de la evidencia 00). |
| P2 | **B** | En SE no hay MOVE DATAFILE online: método offline OFFLINE → copiar → RENAME → ONLINE, el de `03-reubicar`. |
| P3 | **A, C** | STARTUP_TIME es de la instancia (cambió en el reinicio); CREATED es de la base. El DBID 1509902213 no cambió al recrear el contenedor. |
| P4 | **A, C** | En NOMOUNT, v$parameter ya responde (evidencia 06) y se puede ejecutar CREATE CONTROLFILE. ARCHIVELOG y renombrar SYSTEM exigen MOUNT. |
| P5 | **B** | ALTER DATABASE ARCHIVELOG se ejecuta en MOUNT. |
| P6 | **B** | Con SPFILE, el SCOPE por defecto es BOTH. |
| P7 | **C** | PROCESSES no es modificable por PDB: ORA-65040 (evidencia 07, bloque 5). |
| P8 | **A, C** | Arrancar con un PFILE bueno y regenerar el SPFILE con CREATE SPFILE FROM PFILE. |
| P-D1 | **C** | NO AUTHENTICATION elimina el login (V003). LOCK y EXPIRE dejan una contraseña reutilizable, y REVOKE CREATE SESSION se puede volver a conceder. |
| P9 | **B** | MEMORY_TARGET = 0 y SGA_TARGET > 0 es ASMM; DB_CACHE_SIZE actúa como mínimo. |
| P10 | **A, D** | La sort area y la memoria de sesión (servidor dedicado) están en la PGA; el resto, en la SGA. |
| P-G1 | **B** | Variables de enlace: 1008 → 1 análisis duro en mi evidencia 08. Agrandar la shared pool o usar FORCE solo parchea. |
| P-G2 | **B** | No cupo en la PGA y releyó 6 veces desde TEMP: mi ejecución con 64 KB (6 PASSES, 2048 KB en TEMP). |
| P11 | **C** | El COMMIT espera a que LGWR escriba el redo (write-ahead logging). |
| P12 | **B, D** | PMON y SMON son obligatorios. ARC0 solo existe en ARCHIVELOG (la mía lo tiene, pero no es obligatorio). |
| P13 | **B** | Dentro de la PDB, V$DATAFILE se filtra: solo CON_ID 3, con 9 filas (evidencia 10). |
| P14 | **B** | CONTAINER_DATA = ALL (lo que distingue a C##OPS_RO del auditor). |
| P15 | **A, D** | Tablas presentes y futuras de HR, y nada más (ORA-00942 en ADMIN_CLINICA). |
| P16 | **B, D** | Control files y online redo son la base; el resto son relacionados. |
| P17 | **C** | Sin multiplexar ni redo archivado, solo queda la última copia completa. |
| P18 | **B** | Sin 'BIGFILE', la función asume SMALLFILE y reparte mal los bits. |
| P19 | **A, B** | PCTFREE reserva el 10 % para crecer por UPDATE; por debajo de ese margen no se aceptan INSERT (90 filas por bloque en el 781). |
| P20 | **B** | floor((8192 − 96) · 0,9 / 180) = 40 filas por bloque; 2 000 000 / 40 = 50 000 bloques. |
| P21 | **B** | *db file scattered read* = lectura multibloque a la buffer cache. |
| P22 | **A, C** | LIST CHAINED ROWS identifica las filas, y MOVE ONLINE con un PCTFREE mayor las cura. DBMS_STATS no calcula CHAIN_CNT. |
| P23 | **B** | La fila está encadenada y MOVE no lo arregla (ANCHA: CHAIN_CNT 1). |
| P24 | **B** | Cuenta común de solo lectura con CONTAINER_DATA y el GRANT puntual de V_$DIAG_ALERT_EXT. |
| P25 | **B** | PDB$SEED (PDB_LAB4 se creó desde ella). |
| P26 | **C** | ORA-65094 (bloque 3b). |
| P27 | **B** | CLOSE IMMEDIATE antes del DROP; si no, ORA-65025 (evidencia 10). |
| P28 | **A, C** | V$DATAFILE y V$LOG leen el control file; las DBA_/CDB_ necesitan OPEN. |
| P29 | **A** | KCC = control file. |
| P30 | **B** | Las CDB_ existen en la raíz y en cada PDB; desde una PDB solo devuelven sus filas. |
| P31 | **B** | Los tempfiles no se respaldan: se recrean. |
| P32 | **B** | Los parámetros siguen en memoria; se recrea con CREATE SPFILE FROM MEMORY. |
| P33 | **B** | V$PWFILE_USERS (evidencia 11, bloque 4). |
| P34 | **A, B** | La cabecera del bloque incluye la ITL y el directorio de filas (volcado K). |
| P35 | **B** | 16 extensiones de 64 KB y después 1 MB (evidencia 12, bloque 3). |
| P36 | **B** | ASSM: mapas de bits del espacio libre. |
| P37 | **B** | BIGFILE gestionado localmente por defecto desde 23ai (todos mis TBS_* muestran BIG = YES). |
| P38 | **A** | 0 físicas: todos los bloques estaban en la caché. |
| P39 | **A, B** | Más PCTFREE o filas más largas reducen el número de filas por bloque. |
| P40 | **B** | Todas las sesiones van a disco hasta recalentar la caché. |
| P41 | **B** | La migrada cabía y se mudó al crecer; la encadenada no cabe en ningún bloque. |
| P42 | **A** | REBUILD (PK_MIGRA pasó de UNUSABLE a VALID) o MOVE ONLINE. |
| P43 | **A** | V$DIAG_ALERT_EXT. |
| P44 | **A, B** | Ampliar espacio e investigar qué segmentos crecen. |
| P45 | **A, B** | SGA, procesos y redo online son compartidos por todas las PDB. |
| P46 | **B** | ORA-01031 (bloque 3c). |

---

## Retos (Práctica profesional)

### Reto A — Informe de diagnóstico (5 líneas)
1. **Medio:** 5 datafiles de negocio en una carpeta no estándar (`$ORACLE_HOME/dbs` → `dbconfig/FREE/dbs`), dentro del volumen solo gracias a un enlace de la imagen. *1.º:* es el único con posible pérdida de datos si la imagen cambia ese enlace.
2. **Alto:** contraseñas de los propietarios de esquema en V000 (historial de Git). *2.º:* credenciales comprometidas y utilizables.
3. **Alto:** el `08` pasa `sys/<contraseña>` en la línea de comandos. *3.º:* expone la cuenta con más privilegios.
4. **Bajo:** el puerto 8181 se publica sin servicio detrás. *4.º:* superficie de ataque inútil, sin datos en juego.
5. **Bajo:** incoherencias del documento del Lab 3 (V000/V001, `APP_USER_PWD`). *5.º:* solo confunden.

Orden: primero la ubicación de los datos (con la copia ya hecha), después los secretos y al final la higiene.

### Reto B — ¿Rol DBA para C##OPS_RO?
- **Riesgo 1:** un error humano o un script de monitorización con un fallo podría ejecutar DROP o ALTER SYSTEM y destruir datos o tumbar la base. La cuenta de observar pasaría a poder romper.
- **Riesgo 2:** su contraseña vive en `config/.env` y en las herramientas de monitorización. Si se filtra, el atacante tiene DBA: todos los datos, crear usuarios, conceder privilegios. Además es *privilege creep*, difícil de auditar.
- **Para leer el alert log** basta `GRANT SELECT ON sys.v_$diag_alert_ext TO c##ops_ro CONTAINER = ALL;` (sobre `V_$`, no sobre el sinónimo). Es lo que hace `11-ampliar-ops-ro.sql`, y `16` comprueba que no tiene privilegios ANY de escritura.

### Reto C — Que no vuelva a pasar (OMF)
```sql
ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata' SCOPE = BOTH;
```
Uso **SCOPE = BOTH** porque es dinámico (`SYS_MOD = IMMEDIATE`) y quiero que surta efecto ya y sobreviva a reinicios. Con él, `CREATE TABLESPACE tbs_x;` sin cláusula DATAFILE creó `/opt/oracle/oradata/FREE/55E54F210F100828E0630B00580ADFD0/datafile/o1_mf_tbs_x_ofnk5gv3_.dbf`, de 100 MB con AUTOEXTEND, dentro del volumen. Al hacer DROP, OMF borró el archivo. Está en `scripts/lab4/03-reto-omf.sql` (evidencia `*_03-reto-omf`), en su propio commit, y el SPFILE lo muestra (`*.db_create_file_dest='/opt/oracle/oradata'`).

### Reto E — El parte del reinicio (Parte E, 2026-10-22 UTC, fuente `v$diag_alert_ext`)
- **Parada pedida:** 17:16:45.584 ("Shutting down ORACLE instance (immediate)"). Instancia parada a las 17:16:49.629: **4 s** de cierre limpio.
- **Arranque:** 17:16:49.727. MOUNT a las 17:16:51.701 y **OPEN a las 17:16:53.220**: 3,5 s desde el arranque y **7,6 s** desde la orden de parada.
- **Recuperación de instancia:** no. "Crash Recovery excluding pdb 2/3 which was cleanly closed" es el mensaje estándar del OPEN; tras SHUTDOWN IMMEDIATE no hay redo que aplicar.
- **Errores:**
  - **ORA-00800** [Set Priority Failed] en VKTM y LGWR → **conocido**: el contenedor no tiene CAP_SYS_NICE.
  - **ORA-27303** "error returned by chdir() is 2" al arrancar → **a investigar**: acompaña a un intento de cambiar a un directorio que no existe en la imagen, sin impacto visible, pero no está documentado como ruido conocido.

### Reto F — Change request: open_cursors = 1000
- **Valor actual y origen:** 300, especificado en el SPFILE (`*.open_cursors=300`, ISDEFAULT FALSE). Es dinámico y modificable por PDB.
- **Antes de cambiar:** ORA-01000 suele delatar cursores que la aplicación no cierra. Pediría medir `SELECT sid, COUNT(*) FROM v$open_cursor GROUP BY sid ORDER BY 2 DESC;` y `opened cursors current` en `v$sesstat`. Si crece sin parar, es una fuga y se corrige la aplicación.
- **Propuesta:** si el aumento se justifica, `ALTER SYSTEM SET open_cursors = 1000 COMMENT = 'CR-xxx' SCOPE = BOTH;` en FREEPDB1 (solo su PDB, `PDB_MOD = TRUE`). BOTH porque es dinámico y debe persistir.
- **Prueba:** reproducir la carga en el laboratorio y comprobar que el ORA-01000 desaparece y el máximo por sesión se estabiliza.
- **Rollback:** `ALTER SYSTEM SET open_cursors = 300 SCOPE = BOTH;` (o `RESET` en la PDB para heredar el valor del CDB).
- **Evidencia:** PFILE antes y después (`git diff`), `v$parameter`/`v$spparameter` y el ticket.

### Reto G — Culpables de la CPU (literales)
`scripts/lab4/08-reto-literales.sql` agrupa V$SQL por `force_matching_signature` con más de 50 cursores. Justo después de 08-parse-y-pga encontró una firma en FREEPDB1 con **501 cursores**, 501 ejecuciones y 18 106 KB de shared pool: `SELECT /* lab4_literal */ COUNT(*) FROM admin_academia.aca_estudiantes WHERE estudiante_id…`.

### Reto H — La sesión que más consume
En la terminal 1 lancé, como SYSDBA en FREEPDB1, `SELECT COUNT(*) FROM aca_matriculas a, aca_matriculas b WHERE a.matricula_id < 3000 AND MOD(a.estudiante_id + b.estudiante_id, 7) = 0`. La condición sobre ambas tablas obliga a evaluar cada combinación; sin ella Oracle resuelve el COUNT al instante. Mientras corría, como C##OPS_RO lancé `scripts/lab4/09-reto-sesion.sql` (`v$session` JOIN `v$process`, solo sesiones de usuario activas, ordenadas por `pga_alloc_mem`):
- **SID 223**, SERIAL# 34422, usuario SYS en FREEPDB1, sql_id `cgsct69gusnpt`;
- **SPID 1777**;
- **PGA asignada 3,3 MB** (2,6 MB en uso).

La otra sesión activa era la mía de C##OPS_RO (SID 65, SPID 1490).

### Reto I — Acceso de una auditora externa (diseño, no se ejecuta)
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER aud_clinica IDENTIFIED BY "<secreto generado>" PASSWORD EXPIRE;   -- LOCAL en FREEPDB1
GRANT CREATE SESSION TO aud_clinica;
GRANT READ ANY TABLE ON SCHEMA admin_clinica TO aud_clinica;                 -- 23ai: solo ese esquema, solo lectura
-- Último día:
REVOKE READ ANY TABLE ON SCHEMA admin_clinica FROM aud_clinica;
DROP USER aud_clinica CASCADE;
```
- **Local en FREEPDB1:** solo necesita esa PDB. En I.2, un local con CREATE SESSION no ve nada más (ORA-00942) ni puede saltar a la raíz (ORA-01031).
- **READ y no SELECT:** sin `FOR UPDATE`, así que no puede bloquear filas.
- **Privilegio de esquema:** cubre todo ADMIN_CLINICA y nada más. En I.2, ADMIN_CLINICA siguió cerrado para quien tenía el de ADMIN_ACADEMIA. Un UPDATE daría ORA-41900.
- **Alternativa para la fecha de fin:** un perfil con `PASSWORD_LIFE_TIME 7`.

### Reto J — Plan de copia desde el inventario (evidencia 11)
- **Copia en frío completa:** datafiles 3944 MB + control files 36 MB + redo online 600 MB + SPFILE (3,5 KB) + password file (2 KB) ≈ **4580 MB** sin comprimir. Los tempfiles (60 MB) no hacen falta. Mi copia real del volumen (4742 MB, con archivado y configuración) ocupó **490 MB** comprimida.
- **Con RMAN sobrarían:** el **redo online**, que RMAN no copia (usa el redo archivado: hoy 1 archivo de 66 MB), y los **tempfiles**. Los control files y el SPFILE irían en el autobackup, y RMAN solo copia bloques usados (en incremental, solo los cambiados).

### Reto K — Abre otro bloque (estudiante 19500, `scripts/lab4/12-reto-bloque.sql`)
- **Ubicación:** ROWID `AAAR2kAAAAAAASOABN`, que da el bloque **1166** (`ASO` = 18·64 + 14) y la ranura **77** (`ABN`). Mismo objeto 73124 y mismo archivo 16.
- **Comparación con el bloque 781:**
  - **`nrow` = 85** frente a 90: las filas del final son más largas (DNI y nombre con más dígitos, estado `EGRESADO`: 74 bytes de datos frente a 68).
  - **`avsp` = 0x33a = 826** frente a 865: comprobación `fseo − fsbo` = 0x3f6 − 0xbc = 0x33a ✔.
  - **`hsiz`** = 0xbc frente a 0xc6, porque hay 5 entradas menos en el directorio.
  - **ITL:** la misma Xid `0x0003.01b.00000225` (la carga de V002) con `--U-` y `Lck 85`, así que **sí hay limpieza diferida pendiente**, igual que en el 781.

### Reto L — Dimensionar ACA_MATRICULAS (`scripts/lab4/13-reto-matriculas.sql`)
- **Predicción** con la Unidad 3 y las estadísticas reales (r = 60 000, R = 30, PCTFREE 10): bfr = floor(7286,4 / 30) = **242**, así que b = ceil(60 000 / 242) = **248** bloques.
- **Real:** **370** bloques (384 asignados). La diferencia, en proporción, es mayor que en L.2 (370/248 ≈ 1,49 frente a 244/211 ≈ 1,16), porque con filas cortas pesa más lo que la fórmula ignora: cada fila suma ~5 bytes de cabecera y directorio a sus 30 de datos (un 17 %). A eso se añaden la cabecera real e ITL, y los bloques que ASSM deja a medio llenar bajo la HWM tras una carga con INSERT…SELECT.
- **Recorrido completo en HDD a 150 MB/s:** 370 · 8192 B / 157 286 400 B/s ≈ **19,3 ms**.
