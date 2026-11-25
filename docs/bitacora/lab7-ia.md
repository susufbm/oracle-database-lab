He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 7 · E020

<!--
CÓMO SE RELLENA (léelo y borra este comentario si quieres; el script de evaluación lo ignora)
- La PRIMERA línea es obligatoria y no se toca: «He leído la política de uso de IA de la asignatura.»
- Copia este archivo como docs/bitacora/lab7-ia.md (junto a lab7-respuestas.md) y pon tu código en el título.
  Cada laboratorio tiene el suyo: el del Lab 6 (lab6-ia.md) no se toca.
- Si NO has usado IA: deja solo la línea «No he usado IA.» y borra la entrada de ejemplo.
- Si la has usado: borra la línea «No he usado IA.» y escribe UNA entrada por cada uso, con los 7 campos.
  Un campo vacío es una entrada incompleta (D3: −0,5 por entrada).
- Preguntar a la IA como tutor o corregir la ortografía de un texto propio está permitido: decláralo también.
  Si no copiaste código, escribe «no aplica» en «Código recibido» y en «Evidencia de ejecución» (no cuentan como vacíos).
  Los demás campos son siempre obligatorios.
- Una entrada con TODOS los campos vacíos (la de ejemplo sin tocar) no cuenta: se ignora.
- El código copiado de una IA puntúa si lo EJECUTAS en tu contenedor, lo EXPLICAS con tus palabras,
  dices para qué lo usaste y adjuntas aquí el código y el prompt LITERAL.
-->




## Entrada 1
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
@"C:\Users\yisus\Downloads\P2_Lab 7 Oracle Performance Tuning v1.0 - Estudiante.pdf" @"C:\Users\yisus\Downloads\P2_Lab7_v1.0_Estudiante.zip"
hacemos git pull antes para ver si todo es correcto antes de hcaer el commit
si hay col a
cuando el aas es mayor que el cpuy cliente
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):** no aplica (comandos del enunciado, A.1–A.5)
- **Dónde lo usé (parte, script o pregunta):** Parte A (A.1–A.5)
- **Propósito (para qué lo necesitaba):** Te he usado en la Parte A para ser mi ayudante para aprender, un tutor de enseñanza.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Copiamos y hacemos un backup por si tenemos un fallo y perdemos datos y demás. El preparar sirve para preparar el laboratorio. El AAS es el número de clientes medio, y hay cola cuando el AAS es mayor que el CPU_COUNT (más clientes que cajas).
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** no aplica

## Entrada 2
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
hazlo como en el lab 6
preguntamelo tu y lo escribes tu
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):** bloque de la Parte A.6: gh label create, gh issue create, git switch -c, cp y sed de la plantilla de respuestas, sed sobre lab7-ia.md; después git branch -m para corregir el nombre de la rama, y sed + cat >> para añadir estas entradas con mis respuestas
- **Dónde lo usé (parte, script o pregunta):** Parte A.6 (issue #14, rama y archivos)
- **Propósito (para qué lo necesitaba):** Ese bloque hace que seas mi tutor de enseñanza para ayudarme a enseñarme los comandos, información y sobre el laboratorio.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Creó una rama diferente para hacer este laboratorio y crea una bitácora de IA del Lab 7.
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** no aplica (trabaja con GitHub y el repositorio, no con la base)



## Entrada 3
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
17:39:40 E020 SYS@FREE> SELECT etiqueta, COUNT(*),
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ms)
FROM t6.app_log
GROUP BY etiqueta;
GROUP BY etiqueta
         *
ERROR at line 4:
ORA-00904: "ETIQUETA": invalid identifier
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```sql
SELECT etq, COUNT(*),
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ms)
FROM t6.app_log
GROUP BY etq;
```
- **Dónde lo usé (parte, script o pregunta):** Parte B, C01 (fase entender, «Hazlo a mano» en la TERMINAL 2) y guía de las seis fases de C01
- **Propósito (para qué lo necesitaba):** Te he usado porque había un error del profesor en el enunciado.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Había un fallo en el enunciado: etq es el nombre correcto de la columna y no etiqueta.
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** no aplica (consulta a mano en sqlplus; el mismo dato está en docs/bitacora/lab7/evidencia/casos/20261125T175646Z_C01_entender.txt)

## Entrada 4
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
escribeme las respuesta tu como ya hemos dicho
pero como que una pool
pues un pool con 2 obviamente
porque en eficiencia es el mejor y el que mejor concuerda en latencia y througput, las dos sesiones trabajan con las 2 cpus que e slo idela coinciden con el tiempo de espera
concuerndan con las seisones. esta esperando al ser gratis solo nos permite 2 cpus que se reparten el trabajo con colas
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):** archivo con mis respuestas de C01 copiadas tal cual (solo ortografía corregida, más mis cifras y la ruta de cada evidencia), y el comando awk que lo coloca en docs/bitacora/lab7-respuestas.md
- **Dónde lo usé (parte, script o pregunta):** Parte B, respuestas 1 a 3 de C01 en docs/bitacora/lab7-respuestas.md
- **Propósito (para qué lo necesitaba):** Te he utilizado para que cojas mis respuestas y las pongas donde me las piden, pero son de cosecha propia.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Tú coges mis respuestas y las copias en la bitácora.
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** no aplica (edita el archivo de respuestas, no la base)

## Entrada 5
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
P1 con variables va mucho mas rapido y casi sin hard parses
P2a es un parche que cambia todos los literales
no te he dicho como en el lab 6 quiero que me pongas tambien la evidencia
me refiero la salida de la terminal donde buscar eso
pues que se ha ejecutado lo mismo 750 veces
el tiempo disminuye . porque las filas son minimas comparadas con el manual
que estaba en manual y el area de sort es decir el tamaño
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```sql
-- C03, a mano en la TERMINAL 2
VARIABLE id NUMBER
EXEC :id := 56881
SELECT nombre, ciudad FROM t6.cliente WHERE id_cliente = :id;
-- C04, a mano en la TERMINAL 2
SELECT operation_type, last_execution,
       ROUND(estimated_optimal_size/1048576) AS mb_optimo,
       ROUND(last_memory_used/1024) AS kb_usados
FROM v$sql_workarea
WHERE operation_type LIKE 'SORT%' AND estimated_optimal_size > 10*1048576;
SELECT owner, trigger_name, status FROM dba_triggers
WHERE triggering_event LIKE 'LOGON%';
-- y el comando awk que coloca mis respuestas de C03 y C04 en docs/bitacora/lab7-respuestas.md
```
- **Dónde lo usé (parte, script o pregunta):** Parte C, C03 y C04 (consultas a mano y respuestas en docs/bitacora/lab7-respuestas.md)
- **Propósito (para qué lo necesitaba):** Te he utilizado para que cojas mis respuestas y las pongas donde me las piden, pero son de cosecha propia.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Tú coges mis respuestas y las copias en la bitácora.
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** no aplica (consultas a mano en sqlplus; los mismos datos están en docs/bitacora/lab7/evidencia/casos/20261125T183418Z_C04_diagnosticar.txt)

## Entrada 6
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
para pasar el codigo postal a un numero y asignarlo a una variable tiene 95 lecturas por bsuqeueda accede a esa variable tiene 0,8 ms frente al v1
porque no mira el tipo lo trata como texto
P1 en la línea 3, P2 porque cada ciudad tiene una comunidad
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):** el comando awk que coloca mis respuestas de C07 y C08 en docs/bitacora/lab7-respuestas.md (las órdenes t6 top y t6 plan son del kit)
- **Dónde lo usé (parte, script o pregunta):** Parte D, C07 y C08 (respuestas en docs/bitacora/lab7-respuestas.md)
- **Propósito (para qué lo necesitaba):** Te he utilizado para que cojas mis respuestas y las pongas donde me las piden, pero son de cosecha propia.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Tú coges mis respuestas y las copias en la bitácora.
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** no aplica (edita el archivo de respuestas, no la base)
