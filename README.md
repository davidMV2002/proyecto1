# proyecto1

Aplicación Flutter con registro e inicio de sesión mediante Firebase Authentication y perfiles guardados en Cloud Firestore.

## Entrada a la app

`SplashView` comprueba la sesión y el perfil para decidir qué pantalla abrir:

- Sin sesión iniciada: `LoginView`.
- Con sesión, pero sin perfil: `CreatePerfilView`.
- Con perfil y bienvenida pendiente: `OnBoardingView`.
- Con perfil y bienvenida ya vista: `HomeView`.

Después de iniciar sesión se vuelve al splash para hacer estas comprobaciones. Al registrar una cuenta con correo y contraseña se abre la creación de perfil, donde se introduce el nombre y la edad. Tras guardar el perfil, comienza la bienvenida.

El acceso también ofrece Google en Android y en el navegador. Si el usuario aún no tiene perfil, se crea en `Perfiles/{uid}` con el nombre proporcionado por Google y la bienvenida pendiente; si ya existe, se conserva. La edad no se obtiene de Google. Si se cancela el acceso o se produce un error, la pantalla muestra un mensaje.

## Configuración del acceso con Google

1. En Firebase Authentication, activa el proveedor Google para el proyecto y configura el correo de asistencia solicitado.
2. Para Android, registra en los ajustes de la aplicación Firebase la huella SHA-1 del certificado con el que se firma la aplicación. Para obtener la huella de depuración, desde `android/` ejecuta `./gradlew signingReport` en Windows; usa la huella de la variante `debug`. Cada firma y equipo de desarrollo puede necesitar su propia huella.
3. Descarga de nuevo `google-services.json` desde los ajustes de la aplicación Android en Firebase después de registrar la huella y guárdalo en `android/app/`. Comprueba que pertenece al proyecto y al identificador de aplicación de este repositorio.
4. Para la web, verifica que el dominio desde el que se abre la app está autorizado en Firebase Authentication. Permite las ventanas emergentes si el navegador las bloquea.
5. Ejecuta `flutter pub get` y vuelve a compilar la aplicación. Comprueba en Android y navegador tanto el acceso como la cancelación y el error de conexión.

La configuración de Firebase identifica el proyecto; no incluyas contraseñas, claves privadas ni archivos de firma en el repositorio. La verificación real del acceso requiere tener configurados Firebase y la cuenta de prueba.

## Bienvenida y pantalla principal

La bienvenida tiene tres páginas deslizables y los botones **Siguiente**, **Omitir** y **Comenzar**. Al omitirla o completarla, se guarda `deslizablesVistos: true` en `Perfiles/{uid}` y se abre Home. Así no vuelve a mostrarse para ese perfil en los siguientes accesos. Si el campo no existe, la bienvenida se considera pendiente.

Home muestra un saludo con el nombre del perfil y un botón para cerrar sesión y volver al login. Su barra inferior incluye **Principal**, **Mapa**, **Notificaciones** y **Perfil**.

## Perfil y fotografía

La pestaña **Perfil** muestra el nombre y la edad del usuario que ha iniciado sesión. Permite modificar el nombre (obligatorio, de hasta 100 caracteres) y añadir o cambiar la fotografía desde la cámara o la galería. También permite borrar la foto tras pedir confirmación; se elimina el campo de la foto del perfil, no el documento completo. Se informa si falla la selección, el permiso o el guardado; cancelar la selección no cambia la foto anterior.

La fotografía se reduce y comprime como JPEG antes de codificarse en base64 y guardarse en el campo `fotoBase64` del documento `Perfiles/{uid}` en Firestore. Se guarda una miniatura de menos de 300 KiB en lugar del archivo original para mantener el documento por debajo del límite de tamaño de Firestore. Al mostrar la foto, la aplicación decodifica los datos guardados. La actualización solo modifica ese campo y conserva el resto del perfil.

En Android e iOS, la compresión se realiza mediante `compute` en un isolate mientras se muestra un indicador de espera. En web, `compute` se ejecuta en el hilo principal, por lo que una imagen grande podría afectar temporalmente a la interfaz. Esta opción guarda la foto en Firestore y no requiere configurar Firebase Storage ni activar Blaze.

En iOS se declaran los motivos para utilizar la cámara y la fototeca. Android usa los selectores del sistema proporcionados por `image_picker`; en navegador, la disponibilidad de la cámara depende del dispositivo y del navegador. Las pruebas reales de permisos, cámara y galería deben hacerse en cada plataforma.

## Mapa y ubicación

La pestaña **Mapa** muestra OpenStreetMap, la ubicación del propio usuario y marcadores de capitales cargados desde Firestore. Al tocar un marcador se muestra el nombre de la capital, su país y la distancia en línea recta desde la última posición obtenida del usuario. Si no se dispone de la ubicación, se informa al usuario y se ofrece obtenerla. Al abrirla, la app solicita permiso para obtener una posición puntual y centrar el mapa. Cuando se obtiene la posición, se intenta guardar en el perfil propio de Firestore como `ubicacion` (`GeoPoint`) y `fechaUbicacion` (`Timestamp` del servidor). Las reglas actuales solo permiten al propietario leer o modificar su perfil; no se consultan ni muestran ubicaciones de otros perfiles. Si el guardado falla, se informa y el mapa sigue funcionando con la posición obtenida en el dispositivo. Si la ubicación no está disponible, el mapa conserva un centro predeterminado y permite reintentar.

En Android se declaran permisos de ubicación aproximada y precisa, y en iOS la descripción del uso de ubicación en primer plano. En navegador se necesita un contexto seguro (HTTPS o localhost) y conceder el permiso del navegador. El mapa necesita conexión para descargar las teselas; si los servicios de ubicación están apagados, se deniega el permiso o se agota el tiempo de espera, se informa al usuario y se puede reintentar.

### Capitales en Firestore

La colección `Capitales` contiene un documento por capital, con estos campos:

| Campo | Tipo Firestore | Ejemplo |
| --- | --- | --- |
| `nombre` | `string` | `Madrid` |
| `pais` | `string` | `España` |
| `ubicacion` | `GeoPoint` | latitud `40.4168`, longitud `-3.7038` |

Se han cargado 20 capitales europeas como datos de ejemplo. La colección y sus documentos se pueden ampliar con esa misma estructura; los documentos sin los campos correctos se omiten. Las reglas de `firestore.rules`, ya desplegadas en este proyecto, permiten a usuarios autenticados leer `Capitales` y reservan la lectura y escritura de cada perfil a su propietario. La aplicación no puede modificar las capitales con estas reglas; su administración se realiza desde Firebase. La aplicación muestra un aviso y permite reintentar si no puede cargar las capitales. La ubicación propia se obtiene en el dispositivo y se guarda con su fecha en el perfil privado del usuario; no se muestra a otros usuarios.

### Capitales cerca de mí

La lista **Capitales cerca de mí** muestra las capitales ordenadas por distancia en línea recta desde la última ubicación obtenida en el dispositivo. Cada resultado indica la distancia y permite abrir el detalle de la capital. Si no se dispone de ubicación, es necesario conceder permiso y volver a intentarlo. La posición usada para ordenar también se guarda, junto con su fecha, en el perfil privado del usuario; no se muestra a otros usuarios.

La aplicación escucha la colección `Capitales` con `snapshots()`: así puede actualizar el mapa y la lista si los documentos cambian mientras están abiertos. La distancia se calcula y la lista se ordena en el dispositivo, a partir de esas capitales y de la posición local; Firestore no realiza una consulta ordenada por distancia. Por tanto, esta lista no sustituye las cuatro consultas específicas requeridas por la práctica.

En Android e iOS, el cálculo y la ordenación se ejecutan en un isolate que comunica el progreso a la interfaz. Para unas veinte capitales no es imprescindible usar un isolate; se utiliza para practicar y comprobar la comunicación sin bloquear la pantalla. En web no está disponible `Isolate.spawn`, por lo que el cálculo se realiza en el hilo principal cediendo el control entre lotes y la ordenación también se hace en ese hilo. La ubicación y la lectura de Firestore son operaciones asíncronas y permanecen fuera del isolate.

### Organización del código del mapa

- `lib/views/mapa_view.dart` coordina la pantalla, muestra el mapa y la ubicación propia, y gestiona los controles y mensajes.
- `lib/services/gps_admin.dart` comprueba el servicio y los permisos de ubicación, obtiene una posición puntual y calcula la distancia hasta una capital mediante `Geolocator.distanceBetween`, en metros o kilómetros.
- `lib/services/capitales_service.dart` lee las capitales de Firestore y convierte los documentos válidos para mostrarlos en el mapa.

La pantalla usa Firebase para leer las capitales y guardar en el perfil privado la posición propia y su fecha. No consulta terremotos ni ubicaciones de perfiles de otras personas.

### Tecnologías de localización

El GPS usa señales de satélites: ofrece buena precisión en exteriores, aunque puede tardar en obtener una posición, consumir más batería y funcionar peor en interiores. La localización por red utiliza antenas móviles o redes Wi-Fi: suele responder rápido y funcionar mejor en interiores, pero depende de la cobertura y normalmente es menos precisa. El proveedor combinado del dispositivo utiliza las fuentes disponibles, junto con otros sensores cuando corresponde, para equilibrar precisión, tiempo de respuesta y consumo. La precisión real depende del entorno, el dispositivo y el permiso concedido; conviene usar la precisión necesaria para la tarea y evitar lecturas continuas cuando basta una posición puntual, como en este mapa.

## Pendiente de completar

- Añadir las fotos de bienvenida; por ahora se muestran iconos en su lugar.
- Implementar Notificaciones: actualmente muestra un aviso de que está pendiente.
