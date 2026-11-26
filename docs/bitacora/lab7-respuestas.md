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

Predicado del plan real (SQL_ID 0dbx7196jdajy, TABLE ACCESS FULL, coste 1449): filter(TO_NUMBER("CODIGO_POSTAL")=:B1), con Peeked Binds :B1 (NUMBER): 30038.
Sale de pasar el código postal a un número para compararlo con la variable: la columna CODIGO_POSTAL es VARCHAR2(5) y la V1 de la web mandaba un NUMBER.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T184153Z_C07_diagnosticar.txt

2. Lecturas y p95 de V1 y V2. ¿Por qué EXPLAIN PLAN no lo vio?

V1: 5227 lecturas por búsqueda y p95 de 67,9 ms. V2: 95 lecturas por búsqueda y p95 de 0,8 ms (INDEX RANGE SCAN sobre IX_T6_PED_CP).
EXPLAIN PLAN no lo vio porque no mira el tipo: lo trata como texto.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T184148Z_C07_entender.txt y docs/bitacora/lab7/evidencia/casos/20261125T184302Z_C07_validar.txt

## Parte D · C08 · E-Rows frente a A-Rows
1. Estimación y filas reales antes y después del grupo de columnas. ¿En qué línea del plan se separan por primera vez?

Antes del grupo de columnas: la línea 3 (TABLE ACCESS BY INDEX ROWID BATCHED de CLIENTE, filtro COMUNIDAD = 'COM09') estimaba 3 filas y salieron 56; el resultado final estimaba 28 y salieron 599. Después: la línea 3 estima 50 (reales 56) y el resultado final 496 (reales 599).
Se separan por primera vez en la línea 3.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T184744Z_C08_diagnosticar.txt, docs/bitacora/lab7/evidencia/casos/20261125T184856Z_C08_solucionar.txt y docs/bitacora/lab7/evidencia/casos/20261125T184901Z_C08_validar.txt

2. ¿Por qué el optimizador multiplicaba mal las dos selectividades?

Porque cada ciudad tiene una comunidad (MAX_COMUNIDADES_POR_CIUDAD = 1). El optimizador hacía 100000 × 1/2000 × 1/18 ≈ 2,9 clientes, y eran 56. El grupo de columnas SYS_STUBJHRJ63BYYQ61EBQAQU2TM_ ("CIUDAD","COMUNIDAD") tiene 2000 combinaciones distintas.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261125T184740Z_C08_entender.txt y docs/bitacora/lab7/evidencia/casos/20261125T184905Z_C08_observar.txt

## Parte E · C12 · Estadísticas obsoletas
1. Filas según las estadísticas y reales; método de unión y lecturas antes y después.

Antes: CARRITO tenía 100 filas según las estadísticas y 200100 reales (200000 inserciones, STALE = YES); el informe usaba NESTED LOOPS (E-Rows 100, A-Rows 200K en CARRITO) con 212299 lecturas lógicas. Después de recoger solo CARRITO: 200100 filas en las estadísticas (STALE = NO), HASH JOIN y 5907 lecturas lógicas.
Con estadísticas al día usa HASH JOIN y lee menos.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T104143Z_C12_entender.txt, docs/bitacora/lab7/evidencia/casos/20261126T104159Z_C12_diagnosticar.txt y docs/bitacora/lab7/evidencia/casos/20261126T104214Z_C12_validar.txt

2. ¿Por qué la tarea automática no lo habría arreglado a tiempo? ¿Quién debe recoger y cuándo?

Porque solo trabaja en su ventana de mantenimiento (THURSDAY_WINDOW a las 22:00, 4 horas) y no entra a tiempo.
Debe recoger el propio proceso de carga, al terminar, con GATHER_TABLE_STATS (runbook RB-2).
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T104220Z_C12_observar.txt y docs/bitacora/lab7/evidencia/casos/20261126T104206Z_C12_solucionar.txt

## Parte E · C13 · El ciclo de estadísticas con red
1. Describe el ciclo que seguiste (pendientes, probar, publicar, restaurar, bloquear) con la vista que comprueba cada paso.

Antes: 135277 pedidos pasaron a 'E', STALE = YES y ESTADO sin histograma; el optimizador estimaba 250000 y eran 185277.
- Pendientes: SET_TABLE_PREFS PUBLISH = FALSE y GATHER_TABLE_STATS; se comprueba en DBA_TAB_PENDING_STATS.
- Probar: optimizer_use_pending_statistics = TRUE solo en mi sesión y EXPLAIN PLAN; PLAN_TABLE estima 185277.
- Publicar: PUBLISH_PENDING_STATS y PUBLISH vuelve a TRUE; DBA_TAB_STATISTICS con STALE = NO y DBA_TAB_COL_STATISTICS con histograma FREQUENCY en ESTADO.
- Restaurar: RESTORE_TABLE_STATS a hace 60 segundos; DBA_TAB_STATS_HISTORY (31 días de retención) y ESTADO vuelve a HISTOGRAM = NONE.
- Bloquear: LOCK_TABLE_STATS; DBA_TAB_STATISTICS.STATTYPE_LOCKED = ALL.
Sirve para probar antes sin afectar a nadie.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T104653Z_C13_diagnosticar.txt, docs/bitacora/lab7/evidencia/casos/20261126T104705Z_C13_solucionar.txt, docs/bitacora/lab7/evidencia/casos/20261126T104708Z_C13_validar.txt y docs/bitacora/lab7/evidencia/casos/20261126T104716Z_C13_observar.txt

2. ¿Qué error obtuviste al recoger sobre estadísticas bloqueadas y cómo se recoge si de verdad hace falta?

Me salió ORA-20005: object statistics are locked (stattype = ALL). Si de verdad hace falta, se recoge con force => TRUE.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T104716Z_C13_observar.txt

## Parte E · C14 · El índice invisible
1. Lecturas por apertura del panel antes y después. ¿Cómo probaste el índice sin que lo viera nadie más?

Antes: 5265 lecturas lógicas y 16,8 ms por apertura (TABLE ACCESS FULL) para mostrar 2056 pedidos de 1000000. Después, con IX_T6_C14_PEND (ESTADO, CANAL, FECHA_PEDIDO): 118 lecturas lógicas y 0,28 ms por apertura (INDEX RANGE SCAN).
Con el índice INVISIBLE, probándolo solo en mi sesión: CREATE INDEX ... INVISIBLE ONLINE, ALTER SESSION SET optimizer_use_invisible_indexes = TRUE (116 lecturas en la prueba) y después ALTER INDEX ... VISIBLE.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T104922Z_C14_entender.txt, docs/bitacora/lab7/evidencia/casos/20261126T104934Z_C14_solucionar.txt y docs/bitacora/lab7/evidencia/casos/20261126T104937Z_C14_validar.txt

2. Redo con el índice INVISIBLE y VISIBLE: ¿qué demuestra?

Redo de cambiar el canal de 20000 pedidos: sin mantener el índice 9008 KB, con el índice INVISIBLE 10403 KB y con el índice VISIBLE 10403 KB.
Demuestra que aunque sea invisible se mantiene igual.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T104942Z_C14_observar.txt

## Parte F · C17 · INC-604 con AWR, ASH y ADDM
1. SLI y SLO; p95 antes y después; instantáneas AWR que usaste.

SLI: p95 de la búsqueda por código postal (T6.APP_LOG). SLO: p95 < 20 ms. Antes (V1): p95 de 81,9 ms, INCUMPLE. Después (V2): p95 de 0,36 ms. Instantáneas AWR del intervalo de la V1: 24 (10:58:40) y 25 (11:00:43).
Sí, se ha resuelto: la p95 baja de 81,9 a 0,36 ms. Con la misma carga (3 sesiones, 120 s) se atienden 33090 búsquedas frente a 3825.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T110949Z_C17_entender.txt y docs/bitacora/lab7/evidencia/casos/20261126T111211Z_C17_validar.txt

2. ¿Qué dijeron ASH, AWR y ADDM, y qué no podían decirte? ¿Cuál fue el ÚNICO cambio?

ASH me dijo 98 muestras ON CPU y 11 de espera de CPU (resmgr:cpu quantum) del SQL_ID 0dbx7196jdajy. AWR: 3794 ejecuciones, 255 s y 5258 lecturas por ejecución. ADDM: el 96,3 % de la actividad, y recomienda pasar el SQL Tuning Advisor.
No podían decirme el tipo de dato: solo lo revela el plan real (TABLE ACCESS FULL, plan 2571571058, sacado de AWR). El bloque 4 de diagnosticar no salió porque el cursor ya no estaba en memoria.
El único cambio: desplegar la V2 con el tipo VARCHAR2 (APP.BUSCAR_CP_V2, argumento P_CP VARCHAR2), que usa el índice IX_T6_PED_CP y hace 97 lecturas por ejecución frente a 5258.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T110956Z_C17_diagnosticar.txt, docs/bitacora/lab7/evidencia/casos/20261126T110959Z_C17_solucionar.txt y docs/bitacora/lab7/evidencia/casos/20261126T111400Z_C17_observar.txt

## Parte F · C18 · SQL Plan Management
1. PLAN_HASH_VALUE y lecturas del lunes, del martes y con la línea base.

Mismo SQL_ID 8hn59jfgw00y7. Lunes (con histograma en ESTADO): plan 1767728868 (INDEX RANGE SCAN de IX_T6_PED_ESTADO), 211 lecturas por ejecución y 3,5 ms. Martes (sin histograma): plan 2571571058 (TABLE ACCESS FULL), 5227 lecturas y 13 ms. Con la línea base SQL_PLAN_0a27u7nan424ba00b9863 (MANUAL-LOAD-FROM-AWR, snapshots 32 a 33): plan 1767728868, 190 lecturas y 7,7 ms.
Recupera el plan del lunes y lee menos.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T162937Z_C18_provocar.txt, docs/bitacora/lab7/evidencia/casos/20261126T163008Z_C18_solucionar.txt y docs/bitacora/lab7/evidencia/casos/20261126T163017Z_C18_validar.txt

2. ¿Qué hizo la evolución con el plan nuevo y por qué? ¿Qué queda pendiente para que no vuelva a pasar?

El optimizador quería el plan del martes y lo guardó con ACC = NO (SQL_PLAN_0a27u7nan424b95a18d93, AUTO-CAPTURE). La evolución ejecutó los dos planes y los comparó: «failed the benefit criterion», el plan nuevo era peor, así que sigue sin aceptarse.
La causa sigue ahí: METHOD_OPT = FOR ALL COLUMNS SIZE 1 en PEDIDO, que recoge sin histograma.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T163003Z_C18_diagnosticar.txt y docs/bitacora/lab7/evidencia/casos/20261126T163022Z_C18_observar.txt

## Parte G · Incidente 1 · INC-606
- **Síntoma (con números):** La búsqueda por código postal va lenta: 5310 lecturas por búsqueda.
  Evidencia: docs/bitacora/lab7/evidencia/incidentes/20261126T163906Z_INC-606_romper.txt
- **Playbook y pasos seguidos (herramientas y vistas):** Empiezo por el playbook PB-2 y el runbook RB-3 (índices con red). El verificar da FALLO: IX_T6_PED_CP UNUSABLE y VISIBLE, 5310 lecturas por búsqueda.
  Evidencia: docs/bitacora/lab7/evidencia/incidentes/20261126T164026Z_INC-606_verificar.txt
- **Causa raíz:** El índice IX_T6_PED_CP estaba UNUSABLE (aunque VISIBLE), así que la búsqueda hacía TABLE ACCESS FULL.
- **Arreglo aplicado (órdenes exactas) y por qué ese:** `ALTER INDEX t6.ix_t6_ped_cp REBUILD ONLINE;` Rebuild online porque necesitamos que esté activo.
  Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T164356Z_C17_solucionar.txt
- **Verificación (archivo de evidencia con todo OK):** Cambia el plan (hash 2571571058 → 2982358210) de TABLE ACCESS FULL a INDEX RANGE SCAN después del rebuild. Después, VALID y VISIBLE: vuelve a usar IX_T6_PED_CP y ahora son 95 lecturas por búsqueda.
  Evidencia: docs/bitacora/lab7/evidencia/incidentes/20261126T164403Z_INC-606_verificar.txt
- **Prevención (qué evitaría que se repita):** Hacer un SELECT a DBA_INDEXES donde el dueño sea T6 y mirar que el STATUS sea VALID y VISIBLE.

## Parte G · Incidente 2 · INC-608
- **Síntoma (con números):** En el incidente INC-608 el informe de estado = P estimaba 250000 filas cuando las reales eran 20000.
  Evidencia: docs/bitacora/lab7/evidencia/incidentes/20261126T170013Z_INC-608_romper.txt y docs/bitacora/lab7/evidencia/incidentes/20261126T170022Z_INC-608_verificar.txt
- **Playbook y pasos seguidos (herramientas y vistas):** Playbook PB-3 y runbook RB-2. Lo miré con incidente y t6 estad PEDIDO en las evidencias del lab.
  Evidencia: docs/bitacora/lab7/evidencia/herramientas/20261126T170123Z_t6-estad.txt
- **Causa raíz:** La causa fue tener METHOD_OPT en SIZE 1, lo que quitó el histograma de ESTADO (NONE) y hacía que estimara 250000 filas para 'P'.
- **Arreglo aplicado (órdenes exactas) y por qué ese:** Primero puse SIZE AUTO con SET_TABLE_PREFS y luego recogí estadísticas con GATHER_TABLE_STATS y no_invalidate => FALSE, porque si recoges antes te lo vuelve a dejar sin histograma y hay que tirar el plan viejo.
  `EXEC DBMS_STATS.SET_TABLE_PREFS('T6','PEDIDO','METHOD_OPT','FOR ALL COLUMNS SIZE AUTO');`
  `EXEC DBMS_STATS.GATHER_TABLE_STATS('T6','PEDIDO', no_invalidate => FALSE);`
- **Verificación (archivo de evidencia con todo OK):** En la verificación ya salió todo OK, con 20000 filas estimadas (20000 reales) y histograma FREQUENCY de 4 cajones.
  Evidencia: docs/bitacora/lab7/evidencia/incidentes/20261126T171307Z_INC-608_verificar.txt
- **Prevención (qué evitaría que se repita):** Para que no vuelva a pasar, revisaré el bloque 7 de t6 estad para ver que METHOD_OPT sigue en SIZE AUTO.

## Parte G · Incidente 3 · INC-610
- **Síntoma (con números):** Varias consultas de la aplicación se degradaron a la vez subiendo los buffer gets y el tiempo por ejecución al descartar los índices. La V2 de la búsqueda (53mx77snb43uw) usaba el plan 2571571058 (FULL) con 5961 lecturas y 26,1 ms por ejecución; optimizer_index_cost_adj = 6000 en FREEPDB1 (por defecto, 100).
  Evidencia: docs/bitacora/lab7/evidencia/incidentes/20261126T172055Z_INC-610_romper.txt y docs/bitacora/lab7/evidencia/incidentes/20261126T172103Z_INC-610_verificar.txt
- **Playbook y pasos seguidos (herramientas y vistas):** Playbook PB-3. Lo diagnostiqué mirando las sentencias pesadas con t6 top y revisando los parámetros del optimizador en v$system_parameter dentro de FREEPDB1.
  Evidencia: docs/bitacora/lab7/evidencia/herramientas/20261126T173044Z_t6-top.txt
- **Causa raíz:** Fallan muchas consultas a la vez porque optimizer_index_cost_adj es un parámetro global que encarece el uso de cualquier índice en toda la base de datos y hace que el optimizador los descarte en favor de lecturas completas.
- **Arreglo aplicado (órdenes exactas) y por qué ese:** `ALTER SYSTEM RESET optimizer_index_cost_adj SCOPE = BOTH;` (en FREEPDB1). Si lo cambias solo en la sesión solo te afecta mientras sigas conectado y el resto sigue fallando, y si lo cambias solo en memoria se arregla temporalmente pero al reiniciar la base volverá al valor malo al no estar guardado en el SPFILE.
- **Verificación (archivo de evidencia con todo OK):** Al hacer RESET del parámetro optimizer_index_cost_adj en el SPFILE y reiniciarlo en memoria, el valor volvió al defecto (100) sin dejar nada guardado en el SPFILE, y la consulta V2 volvió a usar el índice IX_T6_PED_CP bajando de las 5961 lecturas por ejecución del plan FULL (2571571058).
  Evidencia: docs/bitacora/lab7/evidencia/incidentes/20261126T173115Z_INC-610_verificar.txt
- **Prevención (qué evitaría que se repita):** Para que no vuelva a pasar sin enterarme, restringiría los permisos de ALTER SYSTEM a usuarios externos, activaría auditoría sobre cambios de parámetros del sistema y comprobaría directamente los valores de parámetros críticos del optimizador en v$system_parameter (sin fiarme solo de ISDEFAULT).

## Parte H · Reflexión
1. De todo el laboratorio, ¿qué cambio dio más mejora por menos riesgo? Justifícalo con tus números.

C14, porque no afecta a nadie.
El panel de pendientes pasó de 5265 lecturas lógicas y 16,8 ms por apertura (TABLE ACCESS FULL) a 118 lecturas y 0,28 ms (INDEX RANGE SCAN) con IX_T6_C14_PEND. El índice se creó INVISIBLE ONLINE y lo probé solo en mi sesión con optimizer_use_invisible_indexes = TRUE (116 lecturas) antes de hacerlo VISIBLE.
Evidencia: docs/bitacora/lab7/evidencia/casos/20261126T104922Z_C14_entender.txt, docs/bitacora/lab7/evidencia/casos/20261126T104934Z_C14_solucionar.txt y docs/bitacora/lab7/evidencia/casos/20261126T104937Z_C14_validar.txt

2. Un caso no evaluable (sin ★) que hayas hecho y qué aprendiste de él (opcional, cuenta para la certificación).

No he hecho ningún caso no evaluable.
