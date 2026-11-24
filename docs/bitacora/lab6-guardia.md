## INC-601 · La pantalla de secretaría se queda colgada
- Detección: Ticket a las 17:23 UTC de Ana García por bloqueo sobre alumno 101; primero Ana reinicia el PC, falla porque sigue bloqueado.
- Impacto: Sesión 221 en espera (enq: TX - row lock contention) durante 1 min 42 s (17:23:29–17:25:11), sin que me permitiera decidir si estaba bien o no porque salía activo en los dos; alumno 101 ACTIVO antes y después.
- Diagnóstico: El bloqueo lo tiene 19 (matriculas / cierre-periodo, Idle, USED_UREC = 1) pero lo pide 221 (ANA_GARCIA, BLOQ = 19) en el servidor de la base de datos sobre ACA_ESTUDIANTES.
- Causa raíz: Es un fallo de la función, está mal programada: al hacer update debería de haber un rollback o un commit pero no lo hay.
- Intervención: Se ejecuta ALTER SYSTEM KILL SESSION '19,22887' IMMEDIATE tras un ORA-00026 a las 17:23:52 (descartando reiniciar la instancia porque afecta a todas las sesiones).
- Validación: Secciones 1, 3 y 4 vacías, última espera en ASH a las 17:25:11 y alumno 101 ACTIVO antes y después.
- Acción preventiva: Que siempre que se haga un update se haga commit y rollback si es necesario, y que avisaría al DBA después de 9 segs.
- Incidencias: INC-601 (incluye bloqueo previo de las 17:05 que terminó sin KILL y ORA-00026 a las 17:23:52).

## INC-602 · La aplicación no conecta: ORA-12514
- Detección: Ticket a las 18:55 UTC del equipo de matrículas con el error ORA-12514 y app.sh a las 19:02:07 con ORA-12514 "Service academia_app is not registered with the listener".
- Impacto: Todos los users no podían hacer nada en la app de la academia; si ha conseguido conectarse no falla la base.
- Diagnóstico: A las 18:55:29 FREEPDB1 = SI y academia_app = NO; usa el servicio academia_app, que está apagado o no funcionando, y solo actúa sobre la academia app.
- Causa raíz: No sabemos quién lo paró, simplemente no estaba arrancado.
- Intervención: Arranca el servicio (EXEC DBMS_SERVICE.START_SERVICE('academia_app') a las 19:02:14, con ORA-44305 al segundo intento a las 19:03:01) y guarda el estado (ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE a las 19:24:15).
- Validación: A las 19:03:09 app.sh devuelve ROL_APP_ACADEMIA y 17600 estudiantes, a las 19:03:22 academia_app = SI, FREEPDB1 OPEN y hoy a las 09:37 tras reinicio academia_app sigue activo sin tocar nada.
- Acción preventiva: Mantener el servicio academia_app arrancado y el estado de FREEPDB1 guardado tras reinicios.
- Incidencias: Error ORA-12514 (18:55 UTC y 19:02:07) y ORA-44305 (19:03:01).

## INC-603 · La aplicación no entra: ORA-28000
- Detección: Ticket a las 19:35 UTC del equipo de matrículas con ORA-28000 («no hemos cambiado la contraseña») y app.sh a las 19:43:04 con ORA-28000 "The account is locked".
- Impacto: La aplicación quedó sin acceso con el usuario APP_ACADEMIA desde las 19:35 hasta las 19:43:12 UTC (unos 7 minutos), tras ejecutarse el script trimestral de bajas.
- Diagnóstico: A las 19:36:01 en diagnóstico sección 7 sale APP_ACADEMIA LOCKED (bloqueo 19:35, perfil DEFAULT, 10 intentos), y como LOCKED = a mano (no LOCKED(TIMED) por intentos fallidos), el bloqueo fue manual.
- Causa raíz: El script trimestral de bajas no comprueba ni filtra si un usuario pertenece a una aplicación/servicio antes de bloquearlo (LOCKED), aplicando la baja masiva también sobre APP_ACADEMIA.
- Intervención: A las 19:43:12 se ejecuta ALTER USER app_academia ACCOUNT UNLOCK (User altered), la intervención mínima posible al desbloquear la cuenta manteniendo su contraseña y privilegios intactos sin tener que cambiar la clave ni recrear el usuario.
- Validación: A las 19:43:17 app.sh devuelve ROL_APP_ACADEMIA y 17600 estudiantes, y a las 19:43:28 la sección 7 del diagnóstico está vacía.
- Acción preventiva: Revisar y controlar los bloqueos manuales (LOCKED) de cuentas de aplicación al ejecutar el script trimestral de bajas.

