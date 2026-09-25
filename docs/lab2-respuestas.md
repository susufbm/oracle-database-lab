# Laboratorio 2 — GitHub Team Workflow · Preguntas de comprobación

Administración de Bases de Datos · Práctica 1, Laboratorio 2
Autor: Susu · Revisora: Irene

## 1. ¿Por qué un Issue sin criterios de aceptación es un problema, aunque la descripción general parezca clara?

Porque si no hay criterios de aceptación no se sabe cuándo un trabajo está terminado. Los criterios de aceptación funcionan como un contrato claro y son una lista de comprobación para el autor y el revisor.

## 2. Explica la diferencia entre "Refs #N" y "Closes #N" en un mensaje de commit o en la descripción de un Pull Request.

Mientras que `Refs #N` es una referencia cruzada visible que enlaza el commit con el Issue, pero el Issue permanece abierto, `Closes #N` es una palabra clave que cierra el Issue automáticamente cuando el Pull Request se fusiona con la rama `main`.

## 3. ¿Qué ocurre exactamente si intentas hacer git push directamente sobre una branch main protegida? ¿Es un error tuyo o un fallo del sistema?

Que GitHub rechazará la subida mostrando un error (`GH006: Protected branch update failed`) e indicando que los cambios deben hacerse mediante un Pull Request. No es un fallo del sistema ni un error mío: es la protección funcionando como se espera. La solución no es forzar el push, sino crear una rama y abrir un Pull Request.

## 4. Un compañero te dice: "he aprobado el PR sin mirar los archivos, total ya me fío". ¿Qué riesgo tiene esa forma de revisar?

Esto puede hacer que los posibles errores o vulnerabilidades que haya pasen directamente a la línea de producción principal. Además, la aprobación deja de ser una señal de calidad: si algo falla, el cambio lo habrán aprobado dos personas y una de ellas ni lo miró.

## 5. Si el reviewer pide un cambio y tú ya habías hecho push de tu branch, ¿tienes que abrir un Pull Request nuevo? Explica qué ocurre técnicamente con el PR existente cuando haces un nuevo commit.

No, no se debe abrir un Pull Request nuevo para realizar una corrección. Solo hay que hacer nuevos commits sobre la misma rama y después hacer `git push`. Como el Pull Request está vinculado a la rama, cualquier nuevo commit actualiza automáticamente el Pull Request existente y así el revisor lo podrá ver en la pestaña *Files changed*.

## 6. Describe con tus palabras la diferencia entre Merge commit, Squash and merge y Rebase and merge. ¿Cuál usarías para una branch con commits "wip", "fix", "fix2", "ok ya"?

*Merge commit* guarda todos los commits individuales de la rama y añade un nuevo commit de fusión para integrarlos. *Squash and merge* combina todos los commits de la rama en uno único antes de integrarlo en `main`. *Rebase and merge* mueve los commits de la rama para ponerlos al final de `main`, manteniendo el historial lineal. Para «wip», «fix», «fix2», «ok ya» usaríamos *Squash and merge*, porque esos commits no aportan valor al historial individual: así se queda todo resumido en un solo commit.

## 7. ¿Por qué borrar una branch después del merge no elimina el trabajo realizado en ella?

Porque aunque borres la rama no se borra el historial. Al hacer merge, los commits ya han sido integrados en la rama `main`. La rama en la que estabas solo es temporal y, si ya no la necesitamos, podemos borrarla para mantener el repositorio limpio.

## 8. ¿Qué información debería contener siempre la descripción de un Pull Request, como mínimo?

Debería responder, sin que nadie tenga que preguntar, qué hace el cambio, los cambios técnicos aplicados, cómo probar que funciona y por qué se hace.

## 9. Un reviewer escribe solo "esto está mal" como comentario. ¿Qué le falta a ese comentario para ser útil? Reescríbelo tú con un ejemplo inventado.

Le hace falta añadir contexto, justificación y una propuesta para arreglarlo. Un ejemplo sería:

> «Este cálculo asume que el usuario siempre tiene saldo positivo. Propongo añadir una validación previa para evitar que el programa falle si el saldo es 0 o negativo.»

## 10. ¿Qué diferencia hay entre que main esté protegida y que simplemente el equipo "se ponga de acuerdo" en no hacer push directo?

Ponerse de acuerdo depende de la buena voluntad de los humanos que forman parte del equipo, por lo que es fácil que haya errores por un despiste. Proteger `main` convierte esa sugerencia en una regla estricta que Git y GitHub hacen cumplir automáticamente, bloqueando cualquier intento de saltarse el proceso.

## 11. Explica con un ejemplo propio la diferencia entre un comentario issue: (blocking) y uno nitpick: (if-minor) en formato Conventional Comments.

`issue:` es que hay un error grave que impide aprobar el Pull Request hasta que se corrige; por ejemplo, «has dejado la contraseña de la base de datos escrita en el código». `nitpick:` es para detalles que no deberían bloquear el merge; por ejemplo, «falta un espacio después de esta coma».

## 12. Si tu próximo commit es feat!: cambia la firma de la función principal de la API, ¿qué tipo de versión SemVer se dispara y por qué?

Se dispara un lanzamiento de tipo MAJOR (por ejemplo, pasar de la versión 2.1.0 a la 3.0.0). Esto sucede porque el símbolo `!` incluido justo después del tipo de commit (`feat!`) indica que es un cambio que rompe la compatibilidad con versiones anteriores (un BREAKING CHANGE).

## 13. ¿Por qué abrir un Draft PR desde el primer commit estructural puede ahorrar tiempo al equipo, aunque parezca más lento para el autor individual?

Porque aplica el principio de la industria conocido como *Fail Fast* (fallar rápido). Permite al equipo validar el enfoque general y la arquitectura desde el principio, antes de que el autor invierta horas en desarrollar toda la lógica detallada y las pruebas. Esto evita la «falacia del coste hundido», una situación donde el autor terminaría defendiendo un diseño equivocado únicamente por la gran cantidad de tiempo que ya habría invertido en él.
EOF
