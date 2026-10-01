# Instrucciones del proyecto

## Contexto

Aplicacion Flutter con Dart y Firebase. El codigo esta en `lib/`; las pantallas en `lib/views/` y los modelos en `lib/FbObjects/`. Revisa `pubspec.yaml` antes de cambiar dependencias.

## Delegacion a agentes

El usuario ha solicitado dos agentes especializados para colaborar en este proyecto. Delega tareas relevantes a estos roles:

- **diseno_app**: cambios y revisiones de interfaz, navegacion, estilos, accesibilidad y adaptacion a movil y web. Instrucciones: `.codex/agents/diseno_app.toml`.
- **documentacion_git**: documentacion de cambios y commits locales al terminar tareas verificadas. Instrucciones: `.codex/agents/documentacion_git.toml`.

Usa los agentes personalizados por nombre cuando el cliente lo permita. Si la herramienta solo admite prompts, lee su archivo TOML y transmite sus instrucciones al subagente. No hace falta iniciar los dos para cada pregunta: delega segun la tarea.

El agente principal define alcance y archivos, coordina los cambios y espera los resultados. Evita que dos agentes editen el mismo archivo simultaneamente. El agente de documentacion puede investigar en paralelo, pero documenta el resultado final y hace commits solo cuando todos hayan terminado de editar y las comprobaciones apropiadas hayan pasado.

## Comprobaciones y Git

- Para Dart, formatea los archivos cambiados y usa `flutter analyze` cuando este disponible. Ejecuta pruebas pertinentes cuando el cambio lo justifique.
- Para instrucciones o configuracion, comprueba contenido, referencias locales y sintaxis sin ejecutar pruebas de la app innecesariamente.
- Respeta cambios previos del usuario. Prepara commits con rutas explicitas y revisa el diff staged.
- Los commits locales de tareas completadas estan autorizados. Push y operaciones que reescriban historial requieren una solicitud expresa.
- Informa de las comprobaciones realizadas y sus limitaciones. No incluyas secretos en documentacion o commits.
