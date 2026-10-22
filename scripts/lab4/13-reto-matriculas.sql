-- scripts/lab4/13-reto-matriculas.sql — reto de la Parte L: dimensionar ACA_MATRICULAS (predicción frente a realidad)
-- SQLcl · C##OPS_RO · servicio FREEPDB1: bash scripts/ops/ro.sh scripts/lab4/13-reto-matriculas.sql FREEPDB1
@scripts/ops/marca
SPOOL docs/bitacora/lab4/evidencia/spool/&marca._13-reto-matriculas.spool.log
SET SQLFORMAT DEFAULT
SET LINESIZE 160 PAGESIZE 50 FEEDBACK OFF
PROMPT == Estadísticas reales de ACA_MATRICULAS (r, R, b) ==
SELECT num_rows AS r, avg_row_len AS r_bytes, blocks AS b, pct_free,
       FLOOR((8192 - 96) * (1 - pct_free / 100) / avg_row_len) AS bfr_unidad3,
       CEIL(num_rows / FLOOR((8192 - 96) * (1 - pct_free / 100) / avg_row_len)) AS b_predicho,
       ROUND(blocks * 8192 / (150 * 1048576) * 1000, 1) AS ms_full_scan_hdd_150mbs
  FROM dba_tables WHERE owner = 'ADMIN_ACADEMIA' AND table_name = 'ACA_MATRICULAS';
SPOOL OFF
