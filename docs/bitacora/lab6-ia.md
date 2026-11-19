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
