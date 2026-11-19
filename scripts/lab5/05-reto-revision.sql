-- scripts/lab5/05-reto-revision.sql — reto de la Parte F: revisión de código de una consulta no sargable
-- Se ejecuta como SYSDBA: bash scripts/ops/sysdba.sh <este archivo> <evidencia>
SET LINESIZE 200 PAGESIZE 50 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED
PROMPT == 1. Antes de reescribir, mirar los datos: ¿cómo se guardan teléfonos y apellidos? ==
SELECT telefono, apellidos FROM tiendasur.cliente WHERE ROWNUM <= 3;
SELECT apellidos, COUNT(*) AS n FROM tiendasur.cliente WHERE UPPER(apellidos) LIKE 'GIL%' GROUP BY apellidos;
PROMPT == 2. La consulta del compañero, tal cual (sin índices en telefono ni apellidos) ==
EXEC lab_tools.medir.consulta('reto rota', q'[SELECT * FROM tiendasur.cliente WHERE SUBSTR(telefono, 1, 3) = '600' OR UPPER(apellidos) = 'GIL']')
PROMPT == 3. Índices temporales en las dos columnas ==
CREATE INDEX tiendasur.ix_reto_tel ON tiendasur.cliente (telefono);
CREATE INDEX tiendasur.ix_reto_ape ON tiendasur.cliente (apellidos);
EXEC lab_tools.medir.consulta('reto rota + indices', q'[SELECT * FROM tiendasur.cliente WHERE SUBSTR(telefono, 1, 3) = '600' OR UPPER(apellidos) = 'GIL']')
EXEC lab_tools.medir.consulta('reto reescrita', q'[SELECT * FROM tiendasur.cliente WHERE telefono LIKE '600%' OR apellidos = 'Gil']')
PROMPT == 4. Limpieza: el banco vuelve a su estado ==
DROP INDEX tiendasur.ix_reto_tel;
DROP INDEX tiendasur.ix_reto_ape;
SELECT COUNT(*) AS indices_tiendasur FROM dba_indexes WHERE owner = 'TIENDASUR';
EXIT
