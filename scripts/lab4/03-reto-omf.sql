-- scripts/lab4/03-reto-omf.sql — reto de la Parte C: que un CREATE TABLESPACE nunca vuelva a dejar archivos fuera del volumen
-- Se ejecuta como SYSDBA: bash scripts/ops/sysdba.sh <este archivo> <evidencia>
-- Fija DB_CREATE_FILE_DEST (Oracle Managed Files) dentro del volumen con SCOPE=BOTH: efecto inmediato y persistente.
-- Prueba que un CREATE TABLESPACE sin cláusula DATAFILE crea el archivo dentro del volumen y lo borra al terminar.
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT A22
COLUMN en_memoria FORMAT A24
COLUMN en_spfile FORMAT A24
COLUMN file_name FORMAT A100
PROMPT
PROMPT ===== 1. Antes: sin destino por defecto =====
SELECT p.name, NVL(p.value, '(vacío)') AS en_memoria, NVL(s.value, '(no especificado)') AS en_spfile
  FROM v$parameter p JOIN v$spparameter s ON s.name = p.name WHERE p.name = 'db_create_file_dest';
PROMPT
PROMPT ===== 2. Cambio: OMF dentro del volumen, en memoria y en el SPFILE =====
ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata' COMMENT = 'Lab4 reto C: OMF dentro del volumen' SCOPE = BOTH;
SELECT p.name, p.value AS en_memoria, s.value AS en_spfile
  FROM v$parameter p JOIN v$spparameter s ON s.name = p.name WHERE p.name = 'db_create_file_dest';
PROMPT
PROMPT ===== 3. Prueba: CREATE TABLESPACE sin DATAFILE en FREEPDB1 =====
ALTER SESSION SET CONTAINER = FREEPDB1;
DROP TABLESPACE IF EXISTS tbs_x INCLUDING CONTENTS AND DATAFILES;
CREATE TABLESPACE tbs_x;
SELECT tablespace_name, file_name, ROUND(bytes / 1048576) AS mb, autoextensible, ROUND(maxbytes / 1048576) AS max_mb
  FROM dba_data_files WHERE tablespace_name = 'TBS_X';
PROMPT (Ruta OMF: <destino>/FREE/<GUID de la PDB>/datafile/o1_mf_tbs_x_<id>_.dbf, 100 MB con AUTOEXTEND)
PROMPT
PROMPT ===== 4. Limpieza: el tablespace de prueba se borra con su archivo (OMF lo elimina solo) =====
DROP TABLESPACE tbs_x INCLUDING CONTENTS AND DATAFILES;
SELECT COUNT(*) AS tbs_x_restantes FROM dba_tablespaces WHERE tablespace_name = 'TBS_X';
EXIT
