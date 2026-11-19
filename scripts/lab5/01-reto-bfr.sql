-- scripts/lab5/01-reto-bfr.sql — reto de la Parte B: filas por bloque de PEDIDO, medidas una a una
-- Se ejecuta como SYSDBA: bash scripts/ops/sysdba.sh <este archivo> <evidencia>
SET LINESIZE 160 PAGESIZE 50 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
PROMPT == bfr según las estadísticas (NUM_ROWS / BLOCKS) ==
SELECT num_rows, blocks, ROUND(num_rows / blocks, 1) AS bfr_medio FROM dba_tables
 WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO';
PROMPT == bfr contado bloque a bloque con DBMS_ROWID ==
SELECT COUNT(*) AS bloques_con_filas, MIN(n) AS min_filas, ROUND(AVG(n), 1) AS media_filas, MAX(n) AS max_filas
  FROM (SELECT DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE') AS blk, COUNT(*) AS n
          FROM tiendasur.pedido GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE'));
EXIT
