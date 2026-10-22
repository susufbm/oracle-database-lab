-- scripts/lab4/08-reto-literales.sql — reto de la Parte G: encontrar las sentencias que la aplicación ejecuta con literales
-- SQLcl · C##OPS_RO · servicio FREE. Ejecútalo justo después de 08-parse-y-pga.sql: debe aparecer la de lab4_literal.
-- FORCE_MATCHING_SIGNATURE es la firma del texto con los literales sustituidos por variables: los cursores que solo
-- se diferencian en un literal comparten firma. Muchos cursores con la misma firma = sentencia sin variables de enlace.
@scripts/ops/marca
SPOOL docs/bitacora/lab4/evidencia/spool/&marca._08-reto-literales.spool.log
SET SQLFORMAT DEFAULT
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF
COLUMN contenedor FORMAT A10
COLUMN ejemplo FORMAT A90 TRUNCATED
PROMPT
PROMPT == Firmas con más de 50 cursores distintos (candidatas a usar variables de enlace) ==
SELECT c.name AS contenedor, s.force_matching_signature AS firma,
       COUNT(DISTINCT s.sql_id) AS cursores, SUM(s.executions) AS ejecuciones,
       ROUND(SUM(s.sharable_mem) / 1024) AS kb_shared_pool,
       MIN(SUBSTR(s.sql_text, 1, 90)) AS ejemplo
  FROM v$sql s JOIN v$containers c ON c.con_id = s.con_id
 WHERE s.force_matching_signature <> 0
 GROUP BY c.name, s.force_matching_signature
HAVING COUNT(DISTINCT s.sql_id) > 50
 ORDER BY cursores DESC;
SPOOL OFF
