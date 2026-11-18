-- scripts/lab5/03-reto-cubriente.sql — reto de la Parte D: ¿un índice cubriente para Q9?
-- Se ejecuta como SYSDBA: bash scripts/ops/sysdba.sh <este archivo> <evidencia>
SET LINESIZE 200 PAGESIZE 50 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED
EXEC lab_tools.medir.consulta('Q9 ultimos 20', 'SELECT * FROM tiendasur.pedido ORDER BY fecha_pedido DESC FETCH FIRST 20 ROWS ONLY')
SELECT segment_name, ROUND(bytes / 1048576, 1) AS mb FROM dba_segments
 WHERE owner = 'TIENDASUR' AND segment_name IN ('PEDIDO', 'IX_PED_FECHA') ORDER BY 1;
EXIT
