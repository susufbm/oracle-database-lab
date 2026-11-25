# Laboratorio 7 · Respuestas · E020

<!--
CÓMO SE RELLENA
- Copia este archivo como docs/bitacora/lab7-respuestas.md y pon tu código en el título.
- Responde con TUS números: cada respuesta cita el archivo de evidencia de donde sale (docs/bitacora/lab7/evidencia/...).
  Una cifra sin evidencia no puntúa. Las cifras del PPTX son de referencia: las tuyas serán parecidas, no iguales.
- 3 a 6 líneas por pregunta. No pegues salidas enteras: el archivo de evidencia ya las tiene.
- No borres los títulos: scripts/lab7/09-verificacion-final.sh comprueba que están todos.
-->

## Parte B · C01 · Más sesiones no es más rendimiento
1. ¿Cuántas llamadas por segundo y qué p95 tuviste con 1, 2 y 8 sesiones? ¿Qué número de sesiones recomiendas y por qué?

Con 1 sesión: 7,5 llamadas/s y p95 de 140 ms. Con 2 sesiones: 12,6 llamadas/s y p95 de 192 ms. Con 8 sesiones: 14,7 llamadas/s y p95 de 1035 ms.
Recomiendo un pool con 2 sesiones, porque en eficiencia es el mejor y el que mejor concuerda en latencia y throughput: las dos sesiones trabajan con las 2 CPU, que es lo ideal.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T175646Z_C01_entender.txt (1 y 8 sesiones) y docs/bitacora/lab7/evidencia/casos/20261125T180152Z_C01_validar.txt (2 sesiones).

2. ¿Qué evento domina con 8 sesiones y qué significa en Oracle Free?

Domina resmgr:cpu quantum: 236 de 321 muestras (73,5 %), con AAS 7,8 y CPU_COUNT 2.
La sesión está esperando: al ser gratis, Oracle Free solo nos permite 2 CPU, que se reparten el trabajo con colas.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T175935Z_C01_diagnosticar.txt

3. Comprueba la ley de Little (N = X · R) con tus tres medidas.

1 sesión: 7,5 × 0,1298 s = 0,97 ≈ 1. 2 sesiones: 12,6 × 0,1567 s = 1,97 ≈ 2. 8 sesiones: 14,7 × 0,5354 s = 7,87 ≈ 7,9.
Concuerdan con las sesiones.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T180330Z_C01_observar.txt

## Parte C · C03 · Literales y análisis completos
1. Análisis completos y tiempo con literales, con variables de enlace y con CURSOR_SHARING = FORCE (tus cifras).

Con literales: 5050 hard parses y 4190 ms para 5000 fichas. Con variables de enlace: 29 hard parses y 150 ms. Con CURSOR_SHARING = FORCE: 28 hard parses y 170 ms.
Con variables va mucho más rápido y casi sin hard parses.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T182916Z_C03_solucionar.txt y docs/bitacora/lab7/evidencia/casos/20261125T182924Z_C03_observar.txt

2. ¿Por qué FORCE es un puente y no la solución? ¿Qué ve el DBA en V$SQL que lo delata (FORCE_MATCHING_SIGNATURE)?

Es un parche que cambia todos los literales.
En V$SQL hay 750 SQL_ID distintos con la misma FORCE_MATCHING_SIGNATURE (14573098645096361820) y 750 ejecuciones: se ha ejecutado lo mismo 750 veces.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T182600Z_C03_diagnosticar.txt y docs/bitacora/lab7/evidencia/casos/20261125T182924Z_C03_observar.txt

## Parte C · C04 · El informe que se desborda a TEMP
1. Bloques de TEMP, tipo de pasada y tiempo del informe antes y después. ¿Qué hacía el disparador de logon?

Antes (informe heredado, política MANUAL): 5456 bloques escritos en TEMP (42,6 MB), 1 PASS y 2390 ms. Sin el disparador (AUTO, informe completo): 0 bloques, OPTIMAL y 750 ms. Con TOP 100 (AUTO): 0 bloques, OPTIMAL y 90 ms.
El tiempo disminuye.
El disparador de logon ponía la sesión en MANUAL y fijaba el área de sort, es decir, el tamaño (sort_area_size = 1048576, 1 MB), cuando la ordenación necesitaba 48 MB.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T183418Z_C04_diagnosticar.txt, docs/bitacora/lab7/evidencia/casos/20261125T183530Z_C04_solucionar.txt y docs/bitacora/lab7/evidencia/casos/20261125T183534Z_C04_validar.txt

2. ¿Por qué el TOP 100 cabe en memoria y el informe completo no?

Porque las filas son mínimas comparadas con el manual: el TOP 100 devuelve 100 filas y el informe completo ordena 1000000 (48 MB de área óptima frente a 0,0 MB del TOP 100).
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T183539Z_C04_observar.txt

## Parte D · C07 · EXPLAIN PLAN frente al plan real
1. Copia el predicado que delata el problema en el plan real y explica de dónde sale.
2. Lecturas y p95 de V1 y V2. ¿Por qué EXPLAIN PLAN no lo vio?

## Parte D · C08 · E-Rows frente a A-Rows
1. Estimación y filas reales antes y después del grupo de columnas. ¿En qué línea del plan se separan por primera vez?
2. ¿Por qué el optimizador multiplicaba mal las dos selectividades?

## Parte E · C12 · Estadísticas obsoletas
1. Filas según las estadísticas y reales; método de unión y lecturas antes y después.
2. ¿Por qué la tarea automática no lo habría arreglado a tiempo? ¿Quién debe recoger y cuándo?

## Parte E · C13 · El ciclo de estadísticas con red
1. Describe el ciclo que seguiste (pendientes, probar, publicar, restaurar, bloquear) con la vista que comprueba cada paso.
2. ¿Qué error obtuviste al recoger sobre estadísticas bloqueadas y cómo se recoge si de verdad hace falta?

## Parte E · C14 · El índice invisible
1. Lecturas por apertura del panel antes y después. ¿Cómo probaste el índice sin que lo viera nadie más?
2. Redo con el índice INVISIBLE y VISIBLE: ¿qué demuestra?

## Parte F · C17 · INC-604 con AWR, ASH y ADDM
1. SLI y SLO; p95 antes y después; instantáneas AWR que usaste.
2. ¿Qué dijeron ASH, AWR y ADDM, y qué no podían decirte? ¿Cuál fue el ÚNICO cambio?

## Parte F · C18 · SQL Plan Management
1. PLAN_HASH_VALUE y lecturas del lunes, del martes y con la línea base.
2. ¿Qué hizo la evolución con el plan nuevo y por qué? ¿Qué queda pendiente para que no vuelva a pasar?

## Parte G · Incidente 1 · INC-6NN
- **Síntoma (con números):**
- **Playbook y pasos seguidos (herramientas y vistas):**
- **Causa raíz:**
- **Arreglo aplicado (órdenes exactas) y por qué ese:**
- **Verificación (archivo de evidencia con todo OK):**
- **Prevención (qué evitaría que se repita):**

## Parte G · Incidente 2 · INC-6NN
- **Síntoma (con números):**
- **Playbook y pasos seguidos (herramientas y vistas):**
- **Causa raíz:**
- **Arreglo aplicado (órdenes exactas) y por qué ese:**
- **Verificación (archivo de evidencia con todo OK):**
- **Prevención (qué evitaría que se repita):**

## Parte G · Incidente 3 · INC-6NN
- **Síntoma (con números):**
- **Playbook y pasos seguidos (herramientas y vistas):**
- **Causa raíz:**
- **Arreglo aplicado (órdenes exactas) y por qué ese:**
- **Verificación (archivo de evidencia con todo OK):**
- **Prevención (qué evitaría que se repita):**

## Parte H · Reflexión
1. De todo el laboratorio, ¿qué cambio dio más mejora por menos riesgo? Justifícalo con tus números.
2. Un caso no evaluable (sin ★) que hayas hecho y qué aprendiste de él (opcional, cuenta para la certificación).
