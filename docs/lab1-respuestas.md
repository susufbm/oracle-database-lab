# Laboratorio 1 — Respuestas a las preguntas de comprobación

**Asignatura:** Administración de Bases de Datos
**Profesor:** Richard Avilés López
**Alumno:** Tu Nombre Apellidos

---

### 1. Diferencia entre Working Directory, Staging Area y Local Repository

- **Working Directory**: la carpeta del proyecto tal como la veo y edito en mi disco.
- **Staging Area**: una zona intermedia donde preparo exactamente qué cambios van a entrar en el siguiente commit.
- **Local Repository**: el historial de commits ya confirmados, guardado dentro de la carpeta `.git`.

**Ejemplo del laboratorio:** cuando creé `README.md` con `touch` y le escribí el contenido, estaba solo en el Working Directory: `git status` lo mostraba en rojo como *untracked*. Con `git add README.md` pasó a la Staging Area y salió en verde bajo "Changes to be committed". Con `git commit -m "docs: add initial project documentation"` entró en el Local Repository, y `git status` pasó a decir "nothing to commit, working tree clean".

### 2. Si modifico un archivo pero no hago `git add`, ¿entra en el próximo commit?

No. `git commit` solo guarda lo que está en la Staging Area, no lo que hay en el disco. Si no hago `git add`, el cambio se queda en el Working Directory y el commit se hace sin él. Si el archivo además es nuevo, Git ni siquiera hace el commit y avisa con "nothing added to commit but untracked files present". Es lo que me pasó en el Ejercicio 1 de la Parte E con `docs/customer-schema.md`: hice el commit sin el `add` y el archivo no apareció en el historial hasta que lo añadí y volví a hacer commit.

### 3. ¿Por qué `git status` no mostraba las carpetas vacías de la Parte C?

Porque Git no versiona carpetas, solo archivos. Una carpeta vacía no contiene nada que Git pueda guardar, así que para Git no existe. El truco fue crear un archivo `.gitkeep` dentro de cada carpeta. `.gitkeep` no es algo especial de Git, es solo una convención: lo que hace que la carpeta aparezca es que ya tiene un archivo dentro. Además, esos `.gitkeep` hay que añadirlos y confirmarlos con `git add` y `git commit`; si no, siguen sin estar en el repositorio aunque existan en el disco.

### 4. ¿Qué es HEAD?

HEAD es un puntero que indica dónde estoy ahora mismo. Normalmente apunta a la rama activa, y esa rama apunta a su último commit. Git lo usa para saber qué contenido tiene que haber en mi carpeta de trabajo y encima de qué commit se va a crear el siguiente. Por eso, en un conflicto, la parte marcada como `<<<<<<< HEAD` es la versión de la rama en la que yo estoy.

### 5. Diferencia entre `git switch -c` y `mkdir`

`mkdir` crea una carpeta nueva de verdad en el disco. `git switch -c` no crea ninguna carpeta: crea una rama, que es una línea de evolución del historial, un puntero guardado dentro de `.git`.

En la Parte G lo comprobé así: después de `git switch -c feature/customer-search` ejecuté `ls -la` y salían exactamente los mismos archivos y carpetas que antes, sin ninguna carpeta `feature/`. Luego hice un commit con `docs/customer-search.md` en esa rama. Al volver a `main` con `git switch main`, ese archivo desapareció de `docs/`, y al volver a la rama apareció otra vez. Git cambia el contenido de la carpeta según el commit al que apunta la rama activa, sin crear carpetas nuevas.

### 6. Los marcadores del conflicto de la Parte H

- Entre `<<<<<<< HEAD` y `=======` estaba la versión que ya tenía la rama en la que yo estaba (`main`, que ya había fusionado `fix/readme-title`): `# Oracle Database Lab (Training Edition)`.
- Entre `=======` y `>>>>>>> fix/readme-subtitle` estaba la versión que venía de la rama que estaba fusionando: `# Oracle Database Lab — Academic Version`.

Git no podía elegir porque las dos ramas habían cambiado la misma línea, así que dejó las dos versiones marcadas para que decidiera yo. Lo resolví combinando los dos títulos, borrando los tres marcadores y haciendo `git add` y `git commit`.

### 7. ¿Por qué no hacer `git commit --amend` sobre un commit ya subido?

Porque `--amend` no modifica el commit: crea uno nuevo con otro hash y descarta el anterior. Si ese commit ya estaba en GitHub y otra persona lo había descargado, su historial y el mío dejarían de coincidir, y al sincronizar aparecerían rechazos y divergencias difíciles de arreglar en equipo. `--amend` solo es seguro mientras el commit sea local. Una vez hecho `git push`, el commit es público y, si hay que corregir algo, se hace con un commit nuevo.

### 8. Si borro la carpeta `.git`, ¿qué pierdo?

Pierdo todo el repositorio: el historial de commits, las ramas, la configuración local y la vinculación con el remoto. El proyecto pasa a ser una carpeta normal sin control de versiones.

El código fuente del disco **no** se pierde: los archivos siguen ahí en su última versión guardada. Lo que desaparece es poder volver atrás, comparar versiones o saber quién cambió qué. Como el proyecto ya estaba subido a GitHub, podría recuperar el historial con `git clone`.

### 9. Diferencia entre Git y GitHub

Git es un programa que instalo en mi ordenador. Guarda el historial del proyecto en la carpeta `.git` y funciona sin conexión a internet: `init`, `add`, `commit`, `branch`, `merge` y `log` son operaciones locales.

GitHub es un servicio web de una empresa que guarda copias de repositorios Git en sus servidores para que varias personas puedan sincronizarse. Además añade herramientas que Git no tiene, como Issues, Pull Requests, revisión de código, integración continua y protección de ramas.

Git es la herramienta; GitHub es un sitio donde compartir lo que produce esa herramienta y trabajar con otros. Se puede usar Git sin GitHub.

### 10. ¿Por qué no subir un `.env` con contraseñas, aunque el repositorio sea privado?

Porque Git guarda todo el historial. Aunque después borre el archivo y haga commit, la contraseña sigue en los commits anteriores y cualquiera con acceso puede verla con `git log` o `git show`. Además, que el repositorio sea privado no es garantía: se puede hacer público por error, compartir con más gente, clonarse en otros ordenadores o quedar expuesto si alguien entra en la cuenta.

Lo correcto es no subir nunca secretos: poner `.env` en el `.gitignore` desde el primer commit y subir un `.env.example` con las variables vacías. Si se sube una contraseña por error, lo primero es cambiarla, porque hay que darla por comprometida.

### 11. "GitHub me rechaza el segundo push con 'non-fast-forward'"

Probablemente en GitHub hay commits que él no tiene en su copia local; por ejemplo, porque hizo un cambio desde la web de GitHub, como en el Paso 4 de la Parte I. Git rechaza el push porque aceptarlo borraría esos commits del remoto.

Lo primero que ejecutaría es `git pull`, para traer y fusionar lo que falta. Si sale un conflicto, lo resuelvo como en la Parte H, y después hago `git push`.

### 12. Tipo de Conventional Commit

- **Añadir un índice de rendimiento a una tabla:** `perf`, porque el objetivo es mejorar el rendimiento.
  Ejemplo: `perf(db): add index on customer_id to speed up lookups`
- **Corregir una restricción mal definida:** `fix`, porque corrige un error del esquema.
  Ejemplo: `fix(db): correct check constraint on order_status`
- **Actualizar el README:** `docs`, porque solo cambia documentación.
  Ejemplo: `docs: update project description in README`
