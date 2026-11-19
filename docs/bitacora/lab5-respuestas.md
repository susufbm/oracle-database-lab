# Lab 5 v3 — Oracle DBA Workflow II · Respuestas

**Estudiante:** Jesús Fernández · **GitHub:** susufbm · **Issue:** #9 · **Branch:** `chore/9-oracle-dba-workflow-ii`

Las evidencias están en `docs/bitacora/lab5/evidencia/{script,spool,config}/` (ejecuciones del 2026-11-18 y del 2026-11-19, UTC). «Evidencia NN» es el archivo `*_NN-*` correspondiente.

---

## 8. Preguntas de comprobación

### 8.1 Punto de partida y banco de medida (A, B)

**1. Paso 6 de lab4-final frente a lab3-final.**
Las dos copias dicen `archivos_fuera_del_volumen=0` y, en el paso 6, «ninguno». En mi caso la diferencia no está en ese número, sino en **dónde** estaban los datafiles. En `inventario.txt` de lab3-final, los cinco de negocio aparecen en `/opt/oracle/product/26ai/dbhomeFree/dbs/academia01.dbf` … `fintech01.dbf`. En la evidencia 00 (lab4-final) están en `/opt/oracle/oradata/FREE/FREEPDB1/`. En el Lab 3 ya contaban como «dentro» solo porque `$ORACLE_HOME/dbs` es un enlace al volumen. Es decir, por suerte, no por diseño. Que lab4-final los tenga en la carpeta estándar demuestra que la reubicación del Lab 4 (OFFLINE → copiar → RENAME → ONLINE) funcionó y que la base ya no depende de ese enlace.

**2. bfr de CLIENTE y de PEDIDO.**
Datos de la evidencia 01-perfil: CLIENTE tiene r = 100 000 y b = 1517, así que bfr = 100 000 / 1517 = **66**. PEDIDO tiene r = 1 000 000 y b = 5320, así que bfr = 1 000 000 / 5320 = **188**. PEDIDO mete casi el triple (188/66 = 2,85) porque su fila mide **32 bytes**, frente a los **102** de CLIENTE: 102/32 = 3,2 veces más corta. CLIENTE lleva cadenas largas (email de 26 bytes, apellidos de 19, DNI, teléfono), mientras que PEDIDO son casi todo números y fechas de 2 a 7 bytes. El reto bfr lo confirma bloque a bloque con `DBMS_ROWID`: 5220 bloques con filas, una media de **191,6** y un máximo de 200.

**3. ¿Por qué se mide la segunda ejecución?**
Porque la primera paga trabajo que ocurre una sola vez: el análisis duro del cursor, las consultas recursivas al diccionario y la limpieza diferida de bloques (*delayed block cleanout*) que quedó de la carga. Lo comprobé sin querer: la primera `prueba_pk`, justo después de instalar el paquete, dio **41** lecturas lógicas (evidencia 01-herramienta-medir). Repetida, dio **4**, el valor real (evidencia 02, sección 3: `Buffers = 4`).

### 8.1.1 Anatomía y tipos de índice (C, D)

**4. IX_PED_CLIENTE: altura, hojas y fan-out.**
Evidencia 02, sección 2: **altura 3**, **2216 hojas** y 6 ramas. El fan-out real es (2216 + 6 − 1) / 6 = **370**, y el máximo, 8028 / 14,8 = **543**. Cada hoja guarda 451 entradas de un máximo de 503 (90 %, por PCTFREE 10). Con **mil millones de filas** saldrían 2 208 969 hojas y **altura 4**, es decir, 5 lecturas por búsqueda: una sola más que hoy. La altura crece con el logaritmo de las filas.

**5. ROWID de una entrada de PK_CLIENTE.**
Evidencia 02, sección 4, hoja 0x314: `row#0 … data:(6): 00 00 03 1b 00 00` con la clave `c1 02` (el número 1). Los **4 primeros bytes** `00 00 03 1b` son el bloque 0x31B = **795**, y los **2 últimos**, `00 00`, la **ranura 0**. La consulta de comprobación lo confirma: el cliente 1 está en el bloque 795, ranura 0. No aparece el número de archivo porque **TBS_TIENDASUR es un tablespace bigfile**: tiene un solo archivo, así que el número de bloque ya es único dentro del tablespace. Por eso el índice guarda un ROWID «corto» de 6 bytes.

**6. Tres pruebas de la Parte D (evidencia 03).**
- **Cubriente (Q7):** pasa de **15** lecturas con `ix_ped_cliente` (que además necesita SORT ORDER BY) a **7** con `(id_cliente, fecha)`, porque el índice ya entrega las filas ordenadas. Con el cubriente baja a **3**: un INDEX RANGE SCAN DESCENDING que ni toca la tabla. Por eso V005 crea `ix_ped_cli_fec_cub` para la consulta más frecuente (2000/s).
- **Único (Q13):** de **1486** lecturas (FULL de CLIENTE) a **3**. Además, la base rechaza el DNI duplicado con ORA-00001 sobre `UX_CLI_DNI`: el índice impone una regla de negocio.
- **Bitmap (Q14):** de **4073** lecturas (FULL de VENTA_HECHO) a **528** combinando 4 bitmaps con BITMAP AND. El bitmap de región ocupa 114 hojas, frente a las 1954 de su B-tree. Gana porque son columnas de pocos valores en un almacén que se carga de noche.
- *Discrepancia anotada:* el clúster hash de Q15 me dio **890** lecturas, cuando la teoría espera 1 (el IOT dio 3 y montículo + PK, 4). Lo dejo con mi cifra. Es probable que la tabla hash tuviera más filas que HASHKEYS y se encadenaran bloques por colisiones, pero no lo he podido confirmar.

### 8.1.2 Agrupamiento, equilibrio y sargabilidad (E, F)

**7. CF de IX_PED_FECHA frente a IX_PED_CLIENTE.**
Evidencia 04, sección 1: IX_PED_FECHA tiene CF **5220**, casi igual a los **5320 bloques**. IX_PED_CLIENTE tiene **999 041**, casi igual a **1 000 000 de filas**. La tabla se cargó en orden de fecha, así que pedidos con fechas vecinas están en el mismo bloque. Los pedidos de un cliente, en cambio, están repartidos por toda la tabla, y cada entrada del índice salta a otro bloque. Calculado a mano (sección 2), sale el mismo CF. **Un REBUILD no lo arregla:** el CF es una propiedad de cómo está ordenada la **tabla**, no el índice. Solo bajaría reordenando la tabla (CTAS ordenado, IOT o clúster), y eso empeoraría el CF de la fecha.

**8. Punto de equilibrio según mi curva (evidencia 04, sección 3, y config/04-curva-equilibrio.csv).**
- **CF malo (IX_PED_CLIENTE):** al 0,5 % todavía lee 4875, frente a las 5232 de la tabla. Al **1 %** ya lee **9920**, casi el doble. Se cruza en torno al **0,53 %**. El optimizador se pasa al recorrido completo antes, a partir del 0,2 %, porque descuenta que la lectura multibloque es más barata.
- **CF bueno (IX_PED_FECHA):** compensa hasta pasado el **50 %** (3938 < 5232). Solo pierde al 100 % (7875).
- **Teoría (Unidad 3):** k/r < (1/bfr) × (c_sec/c_aleat). En lecturas lógicas es 1/188 = **0,53 %**, justo donde se cruza mi curva. En disco, con c_sec/c_aleat = 1/5, sería un **0,11 %**.

**9. Q4b ('Gonz%') usa el índice y lee más que el recorrido completo.**
Evidencia 05, regla 4: Q4b devuelve **2056** filas (el 2,1 % de los clientes) con **2024** lecturas, mientras que un FULL de CLIENTE cuesta unas **1523**. El predicado es sargable (es un rango por el principio de la cadena), así que el índice se puede usar. Pero el 2,1 % está por encima del punto de equilibrio de CLIENTE (1/66 = 1,5 %), y los apellidos no siguen el orden físico de la tabla (CF malo), así que casi cada fila es un bloque distinto. Sargable no significa que compense.

### 8.1.3 Coste de escritura y mantenimiento (G, H)

**10. Coste por INSERT y propuesta rechazada (evidencia 06).**
**10,2** bloques con 4 índices (hoy), **20,2** con 9 (compañero) y **12,1** con 5 (V005). Cuadra con 2 + 2 × índices. Redo por fila: 1332, 2557 y 1610 bytes. De la propuesta:
- `ix_ped_canal`: **rechazado**. Tiene 3 valores, el 33,3 % por valor («NO viable»), y `DBA_OBJECT_USAGE` lo marca **NO** usado.
- `ix_ped_fec_cli`: **rechazado**. **NO** usado y hace a `ix_ped_fecha` redundante, pero es más grande. Mejor quedarse con el pequeño, que usan Q2, Q8 y Q9.
- `ix_ped_estado`: **rechazado**. 4 valores, el 25 % por valor. Q12 sí lo usaba, pero lo resuelve mejor el parcial `ix_ped_pendientes` (54 hojas frente a 2933, Parte D).
- `ix_ped_cli_fec`: **sustituido** por `ix_ped_cli_fec_cub` (Q7: de 7 a 3 lecturas), que además hereda la protección de la clave ajena.
- `ix_ped_cp`: **aceptado**. Se usa (Q3 reescrita: 106 lecturas) y es muy selectivo (0,009 % por valor).

Además, `ix_ped_importe` (NO usado) pasó a INVISIBLE, Q2 siguió con 319 lecturas y V005 lo borra.

**11. Los tres patrones en mis gráficos (Parte H).**
- **50/50 (IX_AZAR, 07a-grafico-IX_AZAR):** 595 divisiones, 0 de ellas 90/10, y **75,4 %** de ocupación. El histograma va del 40 % al 99 % y el mapa mezcla `=` y `-`. Es su estado estable, cerca del ln 2 ≈ 69 % teórico.
- **90/10 (IX_CRECIENTE):** 398 divisiones, **todas 90/10**, y **99,9 %**: 398 hojas en 90-99 % y un mapa todo `#`.
- **Cola (IX_COLA, 07b-grafico-antes):** **224 hojas vacías** (0-9 %), el mapa `[        =####]` vacío a la izquierda, `DEL_LF_ROWS` = 70 271 (el 41 %), y «siguiente mensaje» en **226** lecturas frente a 2 en un índice sano.

**12. Remedio en producción y en horario de servicio.**
**COALESCE.** Es en línea, no bloquea, no necesita espacio extra y resuelve el síntoma. En mi evidencia 07c, las hojas bajan de 425 a **201** y «siguiente mensaje», de 226 a **2**. SHRINK SPACE solo si además hace falta devolver espacio (de 4 a 1,69 MB). REBUILD ONLINE dejó **223** hojas (vuelve a PCTFREE 10) con espacio doble y mucho redo, así que no compensa. A largo plazo, la cura es de diseño: particionar por fecha y vaciar particiones enteras.

### 8.1.4 SCN, control files, redo y FRA (I a L)

**13. Qué compara Oracle al abrir (evidencia 08).**
El `checkpoint_change#` de cada datafile en el **control file** (`v$datafile`) con el de la **cabecera del propio archivo** (`v$datafile_header`). Antes del checkpoint, todos los archivos abiertos tenían **4 210 178** en ambos sitios («sincronizado»). Tras `ALTER SYSTEM CHECKPOINT` saltaron a **4 214 348**, salvo los de PDB$SEED, que siguen en **2 098 101** porque es de solo lectura: no tiene bloques sucios y su cabecera no se reescribe. Si los dos SCN coinciden, no hay nada que recuperar. Si la cabecera va por detrás, hay que aplicar redo desde ese SCN.

**14. Multiplexar el control file en el mismo volumen.**
Protege del borrado o la corrupción de **un** archivo. En el simulacro B borré `control03.ctl`, la base se quedó en NOMOUNT con **ORA-00205** (el alert log daba ORA-00202 + ORA-27037 con la ruta), la reparé con `cp -p control01.ctl control03.ctl` + `ALTER DATABASE MOUNT/OPEN` y no perdí nada. **No** protege de perder el disco o el volumen, porque las tres copias se irían juntas, ni de una corrupción lógica que se escriba en las tres. En producción: cada copia en un disco y una controladora distintos (o ASM con redundancia), además de `CONFIGURE CONTROLFILE AUTOBACKUP ON` en RMAN.

**15. Estados del redo y borrados rechazados (evidencia 10).**
- **CURRENT:** donde escribe LGWR. Tras dos `SWITCH LOGFILE`, el grupo 1 (secuencia 13).
- **ACTIVE:** ya no es el actual, pero aún hay bloques sucios cubiertos por su redo; haría falta para recuperar la instancia. Los grupos 2 y 3 justo después de los cambios.
- **INACTIVE:** su redo ya está en los datafiles y, en ARCHIVELOG, archivado. Se puede reutilizar, como el grupo 1 (secuencia 10) al principio.

Rechazos:
- **4a** `ORA-01623`: no se borra el grupo actual.
- **4b** `ORA-01609`: no se quita un miembro del grupo actual.
- **4c** está pensado para una base con 2 grupos, porque quedaría uno solo (`ORA-01567`, mínimo 2 por hilo). La mía tiene **3**: borrar uno dejaría 2, y Oracle lo **permitiría**. Por eso adapté el script para que solo lo intente con 2 grupos y, si no, lo explique (`4c. Omitido: hay 3 grupos…`).

Los miembros nuevos `redo0Nb.log` salieron **INVALID** hasta que LGWR escribió en ellos por primera vez. No es un error. `redo02b.log` seguía INVALID porque el grupo 2 aún no había vuelto a ser CURRENT.

**16. Cadena de causas de la FRA llena (evidencia 11-fra-llena).**
1. `db_recovery_file_dest_size` = 2 MB, por debajo de lo que ya ocupa la FRA (2,1 MB).
2. El UPDATE de 20 000 filas genera redo y pido archivar.
3. El alert log avisa con **ORA-19815** («100.00 % used, 0 remaining»).
4. ARCn no puede escribir: **ORA-19809** (límite superado) y **ORA-16038** (la secuencia 15 no se puede archivar).
5. Los grupos 3 y 1 se quedan con `ARC = NO`.
6. Cuando LGWR dé la vuelta y necesite uno de ellos, no puede reutilizarlo sin archivar. Las sesiones esperan en *log file switch (archiving needed)* y las conexiones nuevas reciben **ORA-00257**: la base deja de aceptar cambios.

Al devolver los 4 GB, ARCn reintentó solo: grupos 1 y 3 con `YES` y la FRA en 3,9 MB.

### 8.1.5 Undo, WAL y simulacros (M a P)

**17. «Los lectores no bloquean a los escritores» (evidencia 12, pasos 1-4).**
A puso la fila 101 a EGRESADO sin confirmar. B la leyó y vio **ACTIVO** al momento, sin esperar: es el valor confirmado, reconstruido con el undo (paso 1). La transacción de A tenía 1 bloque y 1 registro de undo (paso 2) y bloqueos TM modo 3 y TX modo 6 (paso 3). Solo cuando B intentó **escribir** (`FOR UPDATE WAIT 3`) chocó con **ORA-00054** (paso 4). Leer no espera ni bloquea; solo chocan dos escritores sobre la misma fila.

**18. ¿Por qué DELETE genera más undo y ROLLBACK genera redo? (evidencia 12-undo-y-redo).**
Con 10 000 pedidos, el undo fue de **143** bloques para INSERT, **71** para UPDATE y **427** para DELETE. El undo de un INSERT solo dice «borra este ROWID». El de un DELETE guarda la **fila entera** y sus entradas de índice, para poder volver a insertarla. El ROLLBACK genera redo (**353** KB para el INSERT y **4701** KB para el DELETE) porque deshacer es aplicar cambios nuevos a los bloques, y todo cambio de bloque se protege con redo por si la instancia cae a mitad del ROLLBACK.

**19. Dónde está la durabilidad (evidencia 13).**
- **Justo después del COMMIT:** en el **redo log online**. El paso 1 movió **1779 KB** de redo con LGWR (2 escrituras, 1 commit), mientras DBWn escribió **0** bloques y la tabla seguía con **231 bloques sucios** en la caché. Si la instancia cayera ahí, el COMMIT se recuperaría desde el redo.
- **Después del checkpoint:** además, en los **datafiles**. DBWn escribió **348** bloques y quedaron 0 sucios.

Es el *write-ahead logging*: el redo llega al disco antes que el dato.

**20. Simulacro A: roll forward y roll back (evidencia 14a).**
Antes del `SHUTDOWN ABORT`: fila 102 a EGRESADO **confirmada** y fila 103 a INACTIVO **sin confirmar**. Al arrancar, el alert log muestra `Beginning crash recovery of 1 threads`, `Recovery starting at checkpoint rba (logseq 17 block 42464), scn 4218240` y `read 13 KB redo, 13 data blocks need recovery`. Esa es la fase **roll forward**: SMON reaplica el redo desde el último checkpoint, también el de la 103 y el de su undo. Después, `Completed crash recovery` y `Thread 1 opened at log sequence 18`. Con la base abierta, el **roll back** deshace con el undo lo no confirmado. Resultado: **102 = EGRESADO** (lo confirmado sobrevive) y **103 = ACTIVO** (lo no confirmado desaparece), sin que yo interviniera.

**21. RTO y RPO de los simulacros C y D.**
- **C (evidencia 14c):** el DROP sin PURGE lo arregló `FLASHBACK TABLE … TO BEFORE DROP` en segundos, con 60 000 matrículas antes y después. Tras `DROP … PURGE` (ORA-00942) tuve que restaurar la copia completa: **RTO = 62 s**. El **RPO** fue todo lo hecho entre la copia y el fallo: aquí solo **1 s**, pero en la vida real es todo lo ocurrido desde la última copia, en cualquier tabla de la base.
- **D (evidencia 14d):** se borró `academia01.dbf` (archivo 16). RMAN hizo RESTORE de la copia de la FRA y RECOVER con el redo archivado. **RTO = 10 s** y **RPO = 0**: la fila 104, confirmada **después** de la copia, volvió como EGRESADO.

Son tan distintos porque **C restaura la base entera para recuperar una tabla**, y su RTO crece con el tamaño de la base, no con el del daño. Además, el RPO pierde todo lo posterior a la copia. **D restaura un solo archivo de 38 MB** y después **rehace** con el redo archivado todo lo ocurrido desde la copia: el redo convierte una copia vieja en una copia al día. Sin ARCHIVELOG, D sería como C.

**22. Errores ORA- del bloque 5 de mi runbook (evidencia 15).**
Spool `20261119T150904Z_15-healthcheck`, bloque 5 (las 10 más recientes):

| Error | Clasificación | Por qué |
|---|---|---|
| `ORA-63999: data file suffered media failure` (15:08) | **Efecto del laboratorio** | Lo provoqué en el simulacro D al borrar `academia01.dbf`: Oracle cerró FREEPDB1 para protegerla. En producción sería un incidente real de prioridad máxima. |
| `ORA-01110: data file 16 … 26` (academia, clínica, retail, logística, fintech, tiendasur) | **Efecto del laboratorio** | Al cerrar la PDB de golpe, Oracle anota cada datafile de FREEPDB1 afectado por el cierre. No estaban dañados (solo faltaba el 16). |
| `ORA-01113: file 26 needs media recovery` (tiendasur01.dbf) | **Efecto del laboratorio** | Tras el cierre abrupto de la PDB, sus archivos quedan pendientes de recuperación. El `ALTER PLUGGABLE DATABASE OPEN` del script la hizo y la PDB quedó en READ WRITE (bloque 1). |
| `ORA-00800: soft external error … [Set Priority Failed], [LGWR]` (15:07) | **Ruido conocido** | Sale en cada arranque: dentro de Docker, el contenedor no tiene permiso para dar prioridad de tiempo real a LGWR. No afecta al funcionamiento. |

Ninguno es un incidente real abierto: la PDB está en READ WRITE, el datafile 16 está ONLINE y la verificación 16 da TODO OK.

---

## Tabla RTO/RPO de los simulacros

| Simulacro | Fallo | Recuperación | RTO medido | RPO real | Evidencia |
|---|---|---|---|---|---|
| A | Caída de la instancia (SHUTDOWN ABORT) | Automática: SMON, 13 KB de redo y 13 bloques | Segundos (abrió en el primer intento de esperar-healthy, t=0 s) | **0**: la 102 confirmada sobrevive y la 103 sin confirmar se deshace | 14a |
| B | Pérdida de `control03.ctl` | Copiar una copia sana + MOUNT + OPEN | Segundos (ORA-00205, cp y open: una sola orden manual) | **0** | 14b |
| C | `DROP TABLE … PURGE` | Restaurar la copia completa | **62 s** | Todo lo posterior a la copia (aquí, 1 s) | 14c |
| D | Pérdida de `academia01.dbf` | RMAN RESTORE + RECOVER (camino B: PDB cerrada por ORA-63999) | **10 s** | **0** (fila 104) | 14d |

## Retrospectiva del día de simulacro (sin culpables)

**Lo que fue bien**
- Los cuatro simulacros terminaron con la base íntegra y la verificación final en TODO OK.
- En D, RPO = 0. Es la prueba práctica de que copia + redo archivado vale más que una copia completa reciente.
- Multiplexar antes de romper (Partes J y K) convirtió la pérdida de un control file en un `cp`.

**Lo que me sorprendió**
- **El disco del PC se llenó durante el simulacro C.** A mitad de la restauración, el disco C: de Windows llegó a 0 bytes libres, el motor de Docker se cayó y la restauración se cortó con el volumen a medias. Lo resolví reiniciando Docker Desktop y restaurando de nuevo desde la copia `lab5-pre-simulacro`: el SHA-256 salió íntegro y volvieron las 60 000 matrículas. Después repetí el simulacro C desde cero para medir un RTO limpio (62 s). Lección: **una restauración necesita espacio libre en el anfitrión, no solo en la base**, y el espacio de disco tiene que estar en las comprobaciones previas de cualquier restauración.
- En D, Oracle **cerró la PDB entera** (ORA-63999) en lugar de dejar fuera de línea solo el archivo. Durante esos 10 s estuvo caída **toda FREEPDB1**, no solo TBS_ACADEMIA.
- El RTO de C (62 s) es **6 veces** el de D (10 s), y eso con una base pequeña. Con una base real, la diferencia serían horas.
- El script del redo (10) daba por hecho 2 grupos, y con mis 3 habría borrado uno de verdad. Hay que leer los scripts con DROP antes de ejecutarlos.

**Qué cambiaría**
1. Añadir a `restaurar-estado.sh` una comprobación de espacio libre en el anfitrión (al menos 2 veces el tamaño del volumen) antes de borrar nada del volumen.
2. Activar `CONFIGURE CONTROLFILE AUTOBACKUP ON` (RMAN ya la hizo en D) y una copia RMAN periódica de toda la base, para que un caso como C se resuelva con `RECOVER TABLE` (pregunta O4) en vez de restaurar todo.
3. Vigilar en el healthcheck el uso de la FRA (avisar al 80 %) y el espacio del disco del anfitrión.

---

## Preguntas tipo examen del texto

| P | Resp. | Justificación (con mi evidencia) |
|---|---|---|
| B1 | **B** | Una columna sesgada sin histograma hace que el optimizador suponga 1/NDV. Mi `estado` tiene histograma FREQUENCY (evidencia 01-perfil): sabe que 'P' es el 2 %. |
| C1 | **C** | BLEVEL 2 → altura 3, más 1 bloque de tabla = 4. Igual que mi `prueba_pk` (Buffers = 4, evidencia 02). |
| C2 | **C** | 1 + ceil(log₅₀₀ 2 000 000) = 1 + 3 = 4. Misma fórmula que la evidencia 02. |
| D1 | **B** | Bitmaps en columnas de pocos valores de un almacén: Q14 bajó de 4073 a 528 lecturas (evidencia 03). |
| D2 | **A, C** | Q7 cubriente: 3 lecturas sin tocar la tabla. Pero es el índice más grande (40 MB) y encarece las escrituras de sus columnas (evidencia 06: UPDATE importe 6 bloques). Oracle no tiene INCLUDE. |
| E1 | **B** | CF ≈ filas y el 3 % > 1/bfr (≈ 0,8 %). Con CF malo, al 1 % mi índice ya leía 9920 frente a 5232 (evidencia 04). Un REBUILD no cambia el CF. |
| F1 | **B** | Número frente a VARCHAR2 → `TO_NUMBER("CODIGO_POSTAL")` sobre la columna (Q3, evidencia 05: 5232 frente a 106). |
| F2 | **A, C** | Despejar la columna con un rango: regla 2 (Q2: de 5285 a 320 lecturas). |
| G1 | **B** | INVISIBLE: se sigue manteniendo y se vuelve atrás con VISIBLE. Lo hice con `ix_ped_importe` (evidencia 06, pregunta 5). |
| G2 | **B** | Unos 2 bloques por índice y fila × 500 = 1000/s (10,2 → 12,1 con un índice más, evidencia 06). |
| H1 | **B** | COALESCE: de 226 a 2 lecturas, en línea y sin espacio extra (evidencia 07c). |
| H2 | **A, C** | REVERSE reparte la hoja caliente, pero un BETWEEN pasó de 4 a 878 lecturas con TABLE ACCESS FULL (evidencia 07a). No evita divisiones: 511. |
| I1 | **B** | SCN del control file frente al de la cabecera: 4 210 178 = 4 210 178 «sincronizado» (evidencia 08). |
| J1 | **B** | Si falla una copia, la instancia se detiene. En el simulacro B, sin `control03.ctl`, ni siquiera montó (ORA-00205). |
| J2 | **A, C** | Rutas de datafiles y redo, y SCN de checkpoint: lo veo en mi CREATE CONTROLFILE (09) y en la evidencia 08. Ni parámetros (SPFILE) ni contraseñas. |
| K1 | **C** | ACTIVE: su redo aún haría falta para recuperar la instancia (grupos 2 y 3 tras los switch, evidencia 10). |
| L1 | **B** | Primero el tamaño: ORA-02097 + ORA-19802 en mi evidencia 11-activar-archivelog. |
| L2 | **A, C** | Más tamaño (mi remedio en 11-fra-llena) o copia con RMAN y DELETE INPUT. Nunca `rm`. |
| M1 | **C** | B vio ACTIVO con la fila modificada por A (evidencia 12, paso 1). |
| M2 | **C** | DELETE: 427 bloques de undo frente a 143 del INSERT (evidencia 12-undo-y-redo). |
| M3 | **B, D** | Más retención y tamaño de undo, y RETENTION GUARANTEE si es crítica. Mi `undo_retention` = 900. |
| N1 | **A** | Tras el COMMIT, LGWR ya escribió el redo, pero DBWn 0 bloques (evidencia 13). |
| N2 | **B, C** | En el checkpoint (348 bloques, evidencia 13) y cuando no hay buffers libres. No en cada COMMIT. |
| O1 | **B** | SMON aplica el redo y deshace lo no confirmado sin intervención (simulacro A). |
| O2 | **B, D** | Copiar una copia sana (lo hice en el simulacro B) o quitarla de CONTROL_FILES. Sin RESETLOGS ni restaurar. |
| O3 | **B** | OFFLINE → RESTORE → RECOVER → ONLINE (simulacro D). |
| O4 | **D** | RMAN RECOVER TABLE hasta antes del DROP. FLASHBACK no sirve tras un PURGE (simulacro C), y restaurar la base entera perdería los cambios de otras tablas. |

## 9. Simulacro de examen 1Z0-182

| S | Resp. | Dónde lo comprobé |
|---|---|---|
| S1 | **B** | Parte E: CF de IX_PED_CLIENTE 999 041 ≈ filas; al 1 %, 9920 lecturas. |
| S2 | **A, C** | Parte D (índice funcional, de 1486 a 4) y Parte F (reescrita con LOWER, de 1516 a 4). |
| S3 | **B** | Parte F, Q3: `filter(TO_NUMBER("CODIGO_POSTAL")=30001)`. |
| S4 | **B** | Parte D, Q14: bitmaps en un almacén que se carga de noche. |
| S5 | **B** | Parte D, Q6: INDEX SKIP SCAN IX_CLI_PAIS_CIUDAD (144 lecturas). |
| S6 | **B** | Parte G: `ix_ped_importe` INVISIBLE y Q2 sin cambios. |
| S7 | **A, C** | Parte H: COALESCE y SHRINK SPACE en línea. |
| S8 | **B** | Parte H: 0 divisiones 90/10, pero un rango de 878 lecturas. |
| S9 | **C** | Parte G: UPDATE estado = 2 bloques con 4 índices (ninguno tiene estado). |
| S10 | **B** | Parte C: fan-out 370-543 → altura 3. |
| S11 | **A, C** | Parte D, Q15: el IOT hace 3 lecturas frente a 4 de montículo + PK. |
| S12 | **B** | Parte I: control file frente a cabecera. |
| S13 | **C** | Parte I: CKPT registra; DBWn escribe (Parte N). |
| S14 | **B, E** | Lab 4: en NOMOUNT solo responden v$instance y v$parameter. En el simulacro B, `STATUS = STARTED`. |
| S15 | **B** | Parte L: el script de activación (mi base ya venía en ARCHIVELOG). |
| S16 | **B** | Parte K (teoría; no lo provoqué): INACTIVE y archivado significa que su redo ya no hace falta, así que CLEAR LOGFILE lo recrea sin perder nada. |
| S17 | **A, C** | Parte M: lectura consistente (B vio ACTIVO) y flashback query (la fila de hace 40 s). |
| S18 | **B** | Parte M: «describe el undo» = 2062 KB del redo del INSERT. |
| S19 | **A** | Parte N: redo escrito, 0 bloques de DBWn. |
| S20 | **A** | Parte I: FAST_START_MTTR_TARGET guía los checkpoints incrementales (el mío está a 0). |
| S21 | **B** | Parte L: FRA llena, ORA-19809/16038. |
| S22 | **B** | Parte O, simulacro D: OFFLINE del datafile para aislarlo. |
| S23 | **B** | Parte O (conexión con la teoría): SYSTEM se recupera con la base montada. |
| S24 | **B** | Parte L: sin redo archivado no hay RECOVER. |
| S25 | **B, D** | Parte M: undo_retention 900 y v$undostat. |
| S26 | **A** | Parte L: `v$recovery_area_usage` (ARCHIVED LOG, 0,05 %). |

**Resultado:** 26/26 con la Parte que lo demuestra.
