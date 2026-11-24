# Lab 6 · Respuestas de comprobación (E020)

## 1. Errores ORA- en 24 h
Tenía 40 errores ORA- en 24 h (archivo docs/bitacora/lab6/evidencia/script/20261119T170250Z_01-turno.script.log). Se debían sobre todo a errores externos (ORA-00800) y al open read de la pluggable database (ORA-65019). No es una alarma porque no rompen nada.

## 2. Ventana de mantenimiento del miércoles
La ventana de mantenimiento de los miércoles (WEDNESDAY_WINDOW) empieza a las 22:00 (byhour=22;byminute=0) y dura 4 horas. En ella corren tres tareas automáticas habilitadas (auto optimizer stats collection, auto space advisor y sql tuning advisor), según el archivo spool/20261119T170259Z_01-automatizacion.spool.log.

## 3. V$SPPARAMETER frente a V$PARAMETER
V$SPPARAMETER es lo escrito en el archivo guardado (250) y V$PARAMETER es lo que la base está usando ahora mismo en su memoria (200) (script/20261119T171022Z_02-parametros.script.log, paso 5). Si reinicias sin RESET, la base leerá el archivo guardado y arrancará con 250.

## 4. Por qué RESET valía para db_files y no para processes
Hacer RESET borra el ajuste del archivo para que vuelva a su valor de fábrica; en db_files estaba bien porque no salía en mi copia (config/20261119T171029Z_02-init_desde_spfile.ora), pero en processes no sirve porque en la línea 32 pone *.processes=200 y borrarías ese número que tenías puesto.

## 5. Reinicio sin estado guardado
C##OPS_RO obtuvo ORA-01109 porque la CDB no abre las PDB que tiene dentro si no tienen estado guardado (script/20261119T171657Z_02-estados-pdb.script.log, paso 4: FREEPDB1 en MOUNTED).

## 6. La sesión de la aplicación
SID 67 (serial 51536), SPID 4560, evento PL/SQL lock timer (script/20261119T172530Z_03-sesiones.script.log, paso 3). MODULE dice matriculas, ACTION dice cierre-periodo y CLIENT_IDENTIFIER dice que es Ana; USERNAME solo dice APP_ACADEMIA.

## 7. CANCEL SQL frente a KILL SESSION
Tras CANCEL SQL, 1 transacción abierta; tras KILL, 0 sesiones vivas (script/20261119T172530Z_03-sesiones.script.log, pasos 4 y 5). La fila 101 quedó ACTIVO porque el UPDATE se deshizo.

## 8. common_user_prefix
Vale C## (script/20261119T172406Z_03-cuenta-app.script.log). Una cuenta común tiene que empezar por C##; sin él da error.

## 9. Las tres miradas
Datos de script/20261119T173638Z_04-tres-miradas.script.log:

| Vista | C##OPS_RO en CDB$ROOT | C##OPS_RO en FREEPDB1 | APP_ACADEMIA en FREEPDB1 |
|---|---|---|---|
| ALL_TABLES (de ADMIN_ACADEMIA) | 0 | 0 | 1 |
| DBA_USERS | 37 | 47 | ORA-00942 |
| CDB_USERS | 37 (con 1) + 47 (con 3) | 47 (con 3) | ORA-00942 |
| V$DATAFILE | 17 | 10 | ORA-00942 |

Desde la raíz, CDB_USERS ve los dos contenedores porque es una estructura en árbol: desde la raíz se encuentran todas las de las PDB. APP_ACADEMIA da ORA-00942 en DBA_USERS por los permisos que tiene la app.

## 10. Deltas de la carga
Cada recorrido necesitó 5394 lecturas lógicas y la carga costó 0,34 s de DB time (script/20261119T173821Z_04-deltas.script.log, paso 4). De ese tiempo, 0,30 s fueron de CPU, así que la carga pasó casi todo el tiempo calculando.

## 11. Las tres medidas de TBS_ACADEMIA_HIST
Asignado 10 MB, libre 3,9 MB y máximo 40 MB (script/20261123T163527Z_05-almacenamiento.script.log, paso 2; 15,16 % sobre el máximo). Alertaría sobre el máximo, porque ya no tenemos más espacio: es el máximo que podemos tener.

## 12. Quién insertó y quién pagó
Lo lanzó SYS y pagó el user CARGA_HIST (script/20261123T163527Z_05-almacenamiento.script.log, pasos 4 y 5). Ampliar el tablespace no lo arreglaba porque la cuota era ya la máxima (2 MB de 2 MB).

## 13. Carga reanudable
Estuvo suspendida unos 12 s (de 16:38:22 a 16:38:34, script/20261123T163821Z_05-resumable.script.log). En el alert log quedó que fue suspendida («was suspended due to») y que se reanudó («was resumed»).

## 14. Antes y después del SHRINK
Antes había 20000 filas y 2944 bloques; luego 2000 filas, 304 bloques y 2,4 MB de cuota (script/20261123T164111Z_05-hwm-shrink.script.log). El DELETE no devolvió el espacio porque tras el delete los bloques siguen reservados.

## 15. Perfil DEFAULT y PRF_PERSONAS
DEFAULT: FAILED_LOGIN_ATTEMPTS 10, PASSWORD_LOCK_TIME 1 día, PASSWORD_LIFE_TIME 180 días y ninguna función de verificación (script/20261123T164415Z_06-gobierno-acceso.script.log). En PRF_PERSONAS, la cuenta quedó bloqueada por seguridad tras 3 intentos (LOCKED(TIMED)) y exige una contraseña con al menos 8 caracteres por seguridad (ORA-28003 con «corta»).

## 16. Por qué Ana leyó ACA_MATRICULAS
Tenía el rol activado (ROL_LECTURA_ACADEMIA, con SELECT ANY TABLE sobre el esquema ADMIN_ACADEMIA, que le llega por ROL_SECRETARIA_ACADEMIA). Al cambiar el nombre obtuvo ORA-41900: le falta el privilegio UPDATE (script/20261123T164621Z_06-probar-acceso.script.log).

## 17. Objetos invalidados
Con la columna nueva no se invalidó nada, porque no la usaba nadie. Con email se invalidó V_CONTACTO_LAB6. Con nombres se invalidaron V_ACTIVOS_LAB6 y F_TOTAL_ACTIVOS_LAB6, porque la jerarquía es como una herencia y hay dependencias (la función depende de V_ACTIVOS_LAB6) (script/20261123T165023Z_07-objetos.script.log, pasos 2 a 4).

## 18. Advisors de memoria
Duplicar la SGA (de 1536 a 3072 MB) no mejora: el tiempo es el mismo (ESTD_DB_TIME_FACTOR 1 en los dos, 25698 lecturas físicas). La PGA tendría sobreasignaciones por debajo de 384 MB (con 256 MB salen 3) (spool/20261123T165708Z_07-memoria.spool.log, paso 5).

## 19. Lecturas lógicas según la traza
Necesitó 247 lecturas lógicas y 0 de disco para devolver 1 fila. Lo dice la línea FETCH de la traza, en los campos cr=, p= y r= (respectivamente): «FETCH #123422018119488:c=0,e=1148,p=0,cr=247,cu=0,mis=0,r=1» (script/20261123T170002Z_07-adr-trazas.script.log).

## 20. Los tres incidentes de la guardia
- INC-601: vi que la sesión 221 estaba en enq: TX con BLOQ = 19, hice ALTER SYSTEM KILL SESSION '19,22887' IMMEDIATE, y comprobé que las secciones 1, 3 y 4 quedaron vacías con última espera en ASH a las 17:25:11 (script/20261123T172338Z_08-diagnostico.script.log y 20261123T172516Z_08-diagnostico.script.log).
- INC-602: vi que en la sección 6 salía academia_app = NO, hice DBMS_SERVICE.START_SERVICE('academia_app') y SAVE STATE, y comprobé que app.sh entra (17600 estudiantes), academia_app = SI y sigue igual tras el reinicio (script/20261123T185529Z_08-diagnostico.script.log, 20261123T190308Z_08-inc2-validacion.script.log y 20261124T094406Z_08-inc2-tras-reinicio.script.log).
- INC-603: vi que en la sección 7 APP_ACADEMIA estaba LOCKED (no TIMED), hice ALTER USER app_academia ACCOUNT UNLOCK, y comprobé que app.sh entra y la sección 7 queda vacía (script/20261123T193601Z_08-diagnostico.script.log y 20261123T194317Z_08-inc3-validacion.script.log).

