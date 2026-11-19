# Runbook · Pérdida de un datafile de aplicación

**Para:** quien esté de guardia, aunque no haya hecho el Lab 5. **Probado en:** simulacro D (`scripts/lab5/14d-perdida-datafile.sh`, evidencia 14d).
**Objetivo:** recuperar el archivo **sin parar la CDB** y **sin perder ningún COMMIT** (RPO = 0).

## 1. Síntoma

Una consulta sobre las tablas del tablespace falla con estos tres errores juntos:

| Error | Qué dice |
|---|---|
| `ORA-01116: error in opening database file N` | **Qué archivo** (número) no se puede abrir |
| `ORA-01110: data file N: '/ruta/archivo.dbf'` | **Su ruta** |
| `ORA-27041: unable to open file` + `Linux-x86_64 Error: 2: No such file or directory` | **La causa en el sistema operativo**: el archivo ya no existe |

Si en el alert log aparece además **`ORA-63999`**, Oracle ha **cerrado la PDB entera** para protegerla (FREEPDB1 pasa a `MOUNTED`). En ese caso, toda la PDB está caída, no solo ese tablespace.

## 2. Comprobaciones previas (2 minutos, antes de tocar nada)

```sql
-- ¿Hay redo archivado? Sin ARCHIVELOG solo queda restaurar la base entera desde una copia en frío (RPO > 0).
SELECT log_mode FROM v$database;                                   -- debe decir ARCHIVELOG
-- ¿Qué archivo es y de qué tablespace?
SELECT file#, name FROM v$datafile WHERE file# = N;
-- ¿En qué estado está la PDB? (READ WRITE = camino A; MOUNTED = camino B)
SELECT name, open_mode FROM v$pdbs;
```
```
RMAN> LIST BACKUP OF DATAFILE N;     -- ¿hay copia de ese archivo? Si no la hay, PARA y escala.
```
**Si el archivo es de SYSTEM o del undo de CDB$ROOT, este runbook NO sirve:** SHUTDOWN ABORT → STARTUP MOUNT → RESTORE/RECOVER → OPEN, y avisa de inmediato.

## 3. Reparación

Conexión: `docker exec -i oralab-26ai sqlplus / as sysdba` y `docker exec -i oralab-26ai rman target /`.

**Camino A: la PDB sigue abierta (READ WRITE).** Solo está caído ese tablespace.
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE N OFFLINE;          -- aísla el archivo; el resto de la PDB sigue dando servicio
```
```
RMAN> RESTORE DATAFILE N;                   -- trae la copia desde la FRA
RMAN> RECOVER DATAFILE N;                   -- aplica redo archivado + online hasta el presente
```
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE N ONLINE;
```

**Camino B: Oracle cerró la PDB (MOUNTED, ORA-63999).** Espera a que `open_mode` sea `MOUNTED` del todo (no la abras a medias) y después:
```
RMAN> RESTORE DATAFILE N;
RMAN> RECOVER DATAFILE N;
```
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE N ONLINE;
ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
```

**Nunca:** `rm` de archivos de la FRA, `OPEN RESETLOGS` ni `RESTORE DATABASE` para un solo archivo.

## 4. Verificación

```sql
SELECT name, open_mode FROM v$pdbs;                                 -- FREEPDB1 READ WRITE
SELECT file#, status FROM v$datafile WHERE file# = N;               -- ONLINE
SELECT COUNT(*) FROM admin_academia.aca_estudiantes;                -- la tabla responde
```
La **fila de control** es el último cambio confirmado antes del fallo. Si está, RECOVER aplicó todo el redo y el RPO es 0. En el simulacro fue la fila 104, que volvió como `EGRESADO` aunque la copia era anterior a ese cambio.

Para terminar, haz una copia nueva del tablespace (`BACKUP TABLESPACE FREEPDB1:<TBS>`): la anterior ya no sirve para recuperar a partir de ahora sin aplicar todo ese redo.

## 5. A quién avisar

1. **Al empezar:** al responsable de la aplicación afectada. Diles qué tablespace está caído y si la PDB entera lo está (camino B), con una hora estimada.
2. **Si no hay copia, no hay ARCHIVELOG o RECOVER pide un archivado que no existe:** escala al DBA senior **antes** de improvisar. Cualquier paso en falso puede convertir RPO = 0 en pérdida de datos.
3. **Al terminar:** anota en el Issue la hora del fallo, el RTO medido, el RPO y la causa del borrado (¿disco?, ¿persona?). La causa se investiga sin culpables (blameless).
