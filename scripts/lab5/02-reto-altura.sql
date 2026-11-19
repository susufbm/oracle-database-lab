-- scripts/lab5/02-reto-altura.sql — reto de la Parte C: predicción de la altura de UX_CLI_EMAIL frente a la medida
-- Se ejecuta como SYSDBA: bash scripts/ops/sysdba.sh <este archivo> <evidencia>
SET LINESIZE 170 PAGESIZE 50 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
ANALYZE INDEX tiendasur.ux_cli_email VALIDATE STRUCTURE;
SELECT name, height AS altura, lf_rows AS entradas, lf_blks AS hojas, br_blks AS ramas,
       ROUND(lf_rows_len / lf_rows, 1) AS bytes_por_entrada_hoja, ROUND(br_rows_len / br_rows, 1) AS bytes_por_entrada_rama,
       FLOOR(br_blk_len / (br_rows_len / br_rows)) AS fo_maximo, ROUND(lf_rows / lf_blks) AS entradas_por_hoja, pct_used
  FROM index_stats;
EXIT
