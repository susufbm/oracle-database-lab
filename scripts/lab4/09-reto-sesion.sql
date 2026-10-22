-- scripts/lab4/09-reto-sesion.sql — reto de la Parte H: la sesión que más consume (SID, SPID y PGA)
-- SQLcl · C##OPS_RO · servicio FREE. Lánzalo mientras otra sesión ejecuta una consulta larga.
@scripts/ops/marca
SPOOL docs/bitacora/lab4/evidencia/spool/&marca._09-reto-sesion.spool.log
SET SQLFORMAT DEFAULT
SET LINESIZE 180 PAGESIZE 100 FEEDBACK OFF
COLUMN username FORMAT A12
COLUMN contenedor FORMAT A10
COLUMN sql_id FORMAT A14
COLUMN spid FORMAT A8
PROMPT == Sesiones de usuario ACTIVAS ordenadas por PGA asignada (v$session + v$process) ==
SELECT s.sid, s.serial#, s.username, c.name AS contenedor, s.status, s.sql_id, p.spid,
       ROUND(p.pga_used_mem / 1048576, 1) AS pga_usada_mb, ROUND(p.pga_alloc_mem / 1048576, 1) AS pga_asignada_mb
  FROM v$session s JOIN v$process p ON p.addr = s.paddr
  JOIN v$containers c ON c.con_id = s.con_id
 WHERE s.type = 'USER' AND s.status = 'ACTIVE' AND s.sid <> SYS_CONTEXT('USERENV', 'SID')
 ORDER BY p.pga_alloc_mem DESC;
SPOOL OFF
