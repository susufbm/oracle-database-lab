He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 6 · E020

## Entrada 1
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
no quiero que lo hagas este si ayudame a hacerlo y ten en cuenta lo de la IA vamos hacerlo como la primera parte de l lab 5
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
mkdir -p /tmp/kit6 && python3 -m zipfile -e "/mnt/c/Users/yisus/Downloads/P2_Lab6_v1.3_Estudiante.zip" /tmp/kit6 && ls /tmp/kit6/repo-kit
cp -r /tmp/kit6/repo-kit/. . && git status --short | head -30
```
- **Dónde lo usé (parte, script o pregunta):** Parte A.2 (copiar el kit)
- **Propósito (para qué lo necesitaba):** Sacar el archivo de dowloands y extraer el zip.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Crea direcciones anidadas en linux y extrae con python el zip .
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** no aplica (copia de archivos, sin salida en la base; el resultado son los archivos del kit en el commit de la Parte A)

## Entrada 2
- **Herramienta:** Claude (Claude Code)
- **Prompt (literal, copiado tal cual):**
```text
dame tu las contraseñas de app academia y de ana garcia
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
gen() { printf '%s%s%s%s' "$(tr -dc 'A-Z' </dev/urandom | head -c3)" "$(tr -dc 'a-z' </dev/urandom | head -c5)" "$(tr -dc '0-9' </dev/urandom | head -c3)" "##"; }
sed -i "s/^APP_ACADEMIA_PWD=.*/APP_ACADEMIA_PWD=\"$(gen)\"/; s/^ANA_GARCIA_PWD=.*/ANA_GARCIA_PWD=\"$(gen)\"/" config/.env
for v in APP_ACADEMIA_PWD ANA_GARCIA_PWD; do p=$(grep "^$v=" config/.env | cut -d'"' -f2); echo "$v: ${#p} caracteres ..."; done
```
- **Dónde lo usé (parte, script o pregunta):** Parte A.3 (contraseñas en config/.env)
- **Propósito (para qué lo necesitaba):** Para crear contraseñas aleatorias me ha creado una función que ñas genera.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Una función que crea contraseñas.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** no aplica (genera las contraseñas en config/.env, que no se versiona; no se muestran por seguridad)

## Entrada 3
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
E20 soy yo
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
grep '^ESTUDIANTE=' config/.env
```
- **Dónde lo usé (parte, script o pregunta):** Parte A.3 (código de alumno)
- **Propósito (para qué lo necesitaba):** Quería ver esa variable en el .env.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** grep busca esa palabra en un archivo y el ^ es para el principio de línea.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** no aplica (solo lee una línea de config/.env)

## Entrada 4
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
esta bien puesto en
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
set -a && source config/.env && set +a && python3 scripts/ops/autoria.py --ia docs/bitacora/lab6-ia.md 2>&1 | head -8
grep -c '^## Entrada' docs/bitacora/lab6-ia.md
```
- **Dónde lo usé (parte, script o pregunta):** Parte A.4 (comprobar la declaración)
- **Propósito (para qué lo necesitaba):** Porque no estaba puesto como variable global.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Lo crea como variable y autoria.py mira si es correcto.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** no aplica (comprueba el repositorio, no la base)

## Entrada 5
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
se ha quedado parado en el punto 5
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
ls -lh backups/*lab6-inicio*/
df -h /mnt/c | tail -1
```
- **Dónde lo usé (parte, script o pregunta):** Parte A.5 (copia de seguridad)
- **Propósito (para qué lo necesitaba):** Quería ver si el archivo crecía para saber si estaba funcionando o no.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** ls -lh muestra si el archivo de la copia crece; df -h muestra el espacio disponible, porque antes Docker había muerto por no tener espacio.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** no aplica (diagnóstico en el sistema operativo; la copia está en la evidencia 00)

## Entrada 6
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
gh issue list --limit 3
no open issues in susufbm/oracle-database-lab
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
gh issue create --title "Oracle DBA Operations: daily operations runbook on oralab-26ai (Unit 5)" --label infra,operations,documentation --body "(cuerpo del enunciado, A.6)"
gh issue list --limit 3
gh issue close 12 --reason "not planned" --comment "Duplicate of #11, created by mistake."
```
- **Dónde lo usé (parte, script o pregunta):** Parte A.6 (issue #11; la #12 se creó por error y se cerró)
- **Propósito (para qué lo necesitaba):** La issue sirve para planificar y reportar errores, además de que tenemos trazabilidad del código. Tenía que ser la 11 porque era la siguiente de la anterior.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Creé una issue de más sin querer y tuve que cerrarla, listando las que había para saber cuáles había. Cerré la 12 porque la abrí sin querer.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** no aplica (actúa sobre GitHub, no sobre la base)

## Entrada 7
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
hacemos un paron dime que debo de hacer
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
git status --short && git log --oneline -6
git push -u origin chore/11-administracion-operativa
cd ~/oracle-database-lab && source scripts/deployment/env/00-config.sh && docker start oralab-26ai
docker ps --format '{{.Names}} {{.Status}}'
git branch --show-current && bash scripts/ops/ro.sh scripts/ops/validar-arranque.sql
```
- **Dónde lo usé (parte, script o pregunta):** Pausa entre las Partes E y F
- **Propósito (para qué lo necesitaba):** Necesitaba los comandos de parar y volver para no perder el progreso.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** El push sube mis commits y la rama a GitHub, el docker start arranca el contenedor de la base y el validar arranque verifica que el inicio haya sido correcto.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** no aplica (comandos de Git y Docker; validar-arranque se ejecutó por pantalla, sin guardar evidencia)

## Entrada 8
- **Herramienta:** Claude (Claude Code), como tutor
- **Prompt (literal, copiado tal cual):**
```text
quieor que a partir de ahora me expliques linea  linea cada comando que lanzamos para que sirve y asi aprender mas quiero que me enseñes. Pero guiandome
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):** no aplica
- **Dónde lo usé (parte, script o pregunta):** Parte H (explicación de los comandos y scripts 07)
- **Propósito (para qué lo necesitaba):** Pedí las explicaciones para tratar de aprender mejor lo que estaba pasando por debajo.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** He aprendido, por ejemplo, que ts saca el tiempo en ese momento.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** no aplica
