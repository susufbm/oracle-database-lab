# Autopsia de la instancia FREE — Lab 4

**Autor:** Jesús Fernández (susufbm) · **Fecha:** 2026-10-22 · **Fuente:** `docs/bitacora/lab4/evidencia/spool/*_15-autopsia-instancia.spool.log` (C##OPS_RO, solo lectura), con apoyo de las evidencias 06, 11 y 12.

## Identidad

| Dato | Valor |
|---|---|
| Instancia / host | FREE / `e93aa02e2502` (contenedor recreado en la Parte C) |
| Versión | 23.26.3.0.0 (Oracle AI Database 26ai Free) |
| DBID | 1509902213 |
| Arranque / días arriba | 2026-10-22 17:16 / 0 (reiniciada en la Parte E) |
| Modo de log / force logging / flashback | **ARCHIVELOG** / **YES** / NO |
| Contenedores | CDB$ROOT, PDB$SEED (810 MB), FREEPDB1 (1422 MB) |
| SGA / PGA | SGA máxima 1529 MB (buffer cache 1088, shared pool 400) / PGA asignada 412 MB, pico 466 MB, objetivo 512 MB |
| Procesos | 93 de segundo plano, 6 servidores u otros; obligatorios presentes y ARC0/ARC1 activos |
| Archivos | 16 datafiles (3944 MB), 2 control files (36 MB), 3 miembros de redo (600 MB), 3 tempfiles (60 MB), 1 redo archivado (66 MB) |

## Hallazgos

| # | Sección | Evidencia (valor exacto) | Riesgo | Acción | Prioridad |
|---|---|---|---|---|---|
| 1 | 1 · 4 | `LOG_MODE = ARCHIVELOG`, pero `db_recovery_file_dest` vacío y `db_recovery_file_dest_size = 0`; 1 archivado de 66 MB fuera de cualquier FRA | Los archivados crecen sin destino gestionado ni límite: si su disco se llena, la base se detiene. Además, nadie los incluye en una política de copia | Configurar la FRA con tamaño y política de retención (Lab 5) | **Alta** |
| 2 | 4 · J | `control_files` = `control01.ctl` y `control02.ctl`, ambos en `/opt/oracle/oradata/FREE/`; 3 grupos de redo de un solo miembro (200 MB) | Punto único de fallo: un disco o una carpeta dañados dejan la base sin control files o sin el redo CURRENT | Multiplexar control files y redo en otra ubicación (Lab 5) | **Alta** |
| 3 | J (11-archivos-so, bloque 4) | `/opt/oracle/diag` vive en la capa del contenedor (alert log de 102 KB, 218 trazas, 29 MB) | Al recrear el contenedor se pierden el alert log y las trazas. Ya ocurrió en la Parte C: el alert log empieza en el arranque del contenedor nuevo | `diagnostic_dest` en almacenamiento persistente o envío centralizado de logs | **Media** |
| 4 | 6 | `ALTURA_MAX` vacía en ADMIN_CLINICA, ADMIN_FINTECH, ADMIN_LOGISTICA y ADMIN_RETAIL | El optimizador trabaja sin estadísticas en 4 de los 5 esquemas de negocio | `DBMS_STATS.GATHER_SCHEMA_STATS` por esquema y comprobar el job automático de estadísticas | **Media** |
| 5 | 1 | `FORCE_LOGGING = YES` (heredado de la imagen) | Ninguno para la seguridad de los datos, pero las operaciones NOLOGGING no ahorrarán redo y las cargas masivas generarán más archivado (enlaza con el hallazgo 1) | Documentarlo y tenerlo en cuenta al dimensionar la FRA | Baja |
| 6 | 6 | 2 índices de ADMIN_ACADEMIA con factor de agrupamiento cercano al número de filas | Índices caros para consultas por rangos | Analizar en el Lab 5 (clustering factor y punto de equilibrio) | Baja |
| 7 | 10 | 8 ORA- en 24 h: ORA-00800 ×4, ORA-959 ×2, ORA-00031 ×1, ORA-65025 ×1 (evidencia 06: además ORA-27303 al arrancar) | Ruido que tapa alertas reales si no se clasifica | **Conocidos** (excluir de alertas): ORA-00800, por la prioridad de VKTM/LGWR (sin CAP_SYS_NICE). **Provocados por el laboratorio:** ORA-959, por `DROP TABLESPACE IF EXISTS` sobre un tablespace que no existía (Partes C y L); ORA-00031, al terminar la sesión de la consulta larga del reto H; ORA-65025, en la Parte I. **A investigar:** ORA-27303 (chdir) al arrancar la instancia | Baja |
| 8 | 7 | Ninguna cuenta "de la casa" con rol DBA; 9 usuarios locales en FREEPDB1 | — (correcto) | Mantener: C##OPS_RO observa con mínimo privilegio y sin privilegios ANY (`16-verificacion-final`) | — |
| 9 | 5 | Tablespace de negocio más lleno: TBS_ACADEMIA al 2,3 % de su máximo (23 de 1024 MB) | Ninguno: los techos de 1 GB de la Parte C funcionan | Vigilarlo en el runbook diario (Lab 5) | Baja |
| 10 | 9 | `db_create_file_dest = /opt/oracle/oradata` (reto C) y `common_user_prefix = C##` | — | Documentado: OMF evita que se repita el defecto 1 del Lab 3 | — |

## Resumen para dirección (no técnico)

1. La base funciona y sus datos ya sobreviven a la sustitución del servidor (contenedor), pero todavía **no está protegida ante la avería de un disco**: los archivos críticos no están duplicados y las copias de los cambios no tienen un espacio reservado.
2. Lo urgente es reservar ese espacio (FRA) y duplicar los archivos de control y de registro en otra ubicación. Es el plan del Lab 5 y no requiere comprar nada.
3. Lo demás son mejoras de mantenimiento (estadísticas y conservación de los logs de diagnóstico), sin riesgo inmediato para los datos.
