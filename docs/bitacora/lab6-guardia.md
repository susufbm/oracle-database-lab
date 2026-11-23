## INC-601 · La pantalla de secretaría se queda colgada
- Detección: 17:23 UTC · Ana García avisó por el sistema de tickets.
- Impacto: Ana no pudo guardar la ficha del alumno 101 durante 1 min 42 s (de 17:23:29 a 17:25:11). Solo afectó a esa fila.
- Diagnóstico: `08-diagnostico.sql` (17:23:38). La sesión 221 de Ana esperaba en `enq: TX - row lock contention` con `BLOQ = 19`. La 19 (`matriculas / cierre-periodo`) estaba en `WAIT_CLASS = Idle`, con `USED_UREC = 1`, sobre la tabla `ACA_ESTUDIANTES`. El bloqueo lo tiene la 19 y lo pide la 221, en el servidor de la base de datos. Ana se encontraría con que la sesión sigue igual aunque reinicie su ordenador.
- Causa raíz: el proceso de cierre de periodo hizo el `UPDATE` y no hizo `COMMIT` ni `ROLLBACK`, así que su transacción no terminó y la fila siguió bloqueada.
- Intervención: `ALTER SYSTEM KILL SESSION '19,22887' IMMEDIATE`. Era la más pequeña porque solo afectaba a la sesión 19 y solo deshacía una acción del módulo, mientras que reiniciar la instancia afecta a todas las sesiones.
- Validación: en `08-diagnostico.sql` (17:25:16) las secciones 1, 3 y 4 ya no tienen información porque ya no hay problemas, y ASH muestra que la espera de la 221 terminó a las 17:25:11. El alumno 101 salía `ACTIVO` antes y después, así que ese dato no me permitía decidir si estaba bien.
- Acción preventiva: que siempre que se haga un `UPDATE` se haga `COMMIT`, o `ROLLBACK` si es necesario. Avisar al DBA cuando una sesión bloqueada lleve más de 9 segundos.
- Incidencias durante la guardia: el primer bloqueo (17:05) no lo resolví porque la transacción de la sesión 49 terminó sola antes de que yo interviniera. El primer `KILL` (17:23:52) dio `ORA-00026` porque dejé las palabras `SID,SERIAL` de la plantilla en vez de poner `19,22887`.

## INC-602 · La aplicación no conecta: ORA-12514
- Detección: 18:55 UTC · El equipo de matrículas avisó por el sistema de tickets, con el error `ORA-12514`.
- Impacto: todos los usuarios de la aplicación de la academia, que entra por el servicio `academia_app`, no podían hacer nada durante al menos 6 min 45 s (de 18:55:29 a 19:02:14).
- Diagnóstico: la base no estaba caída, porque `08-diagnostico.sql` consiguió conectarse. En la sección 6 (18:55:29), `academia_app` salía `NO` y `FREEPDB1` salía `SI`.
- Causa raíz: el servicio `academia_app` no estaba arrancado. No sabemos quién lo paró.
- Intervención: `EXEC DBMS_SERVICE.START_SERVICE('academia_app')`. Era la más pequeña porque solo actúa sobre `academia_app`.
- Validación: antes de arrancarlo, `app.sh` daba `ORA-12514`. Después, `app.sh` entró y mostró su rol y los estudiantes, y la sección 6 mostraba `academia_app` en `SI`.
- Acción preventiva: hice `SAVE STATE` para que se guarde el estado de la PDB con el servicio arrancado. Además, vigilaría que un servicio que debe estar arrancado salga en `NO`.
- Incidencias durante la guardia: a las 19:03:01 salió `ORA-44305` porque lancé el arranque otra vez y el servicio ya estaba en marcha.

## INC-603 · La aplicación no entra: ORA-28000
- Detección: 19:35 UTC · El equipo de matrículas avisó por el sistema de tickets, con el error `ORA-28000`.
- Impacto: la aplicación de la academia no pudo entrar durante al menos 7 min 15 s (de 19:35:57 a 19:43:12).
- Diagnóstico: `08-diagnostico.sql` (19:36:01), sección 7: `APP_ACADEMIA` en `LOCKED`, bloqueada a las 19:35, con perfil `DEFAULT` y 10 intentos. No es `LOCKED(TIMED)`, así que no se bloqueó por intentos fallidos.
- Causa raíz: probablemente el script de bajas no distingue las cuentas de personas de las de aplicación.
- Intervención: `ALTER USER app_academia ACCOUNT UNLOCK`. Era la más pequeña porque quita el bloqueo de esa cuenta sin cambiar su contraseña, permisos ni datos.
- Validación: a las 19:43:04 `app.sh` daba `ORA-28000`. A las 19:43:17 entró y mostró su rol y los estudiantes, y en el diagnóstico de las 19:43:28 la sección 7 quedó vacía.
- Acción preventiva: que el script de bajas excluya las cuentas de aplicación y avisar al DBA si una de ellas queda `LOCKED`.

