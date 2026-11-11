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

Home muestra un saludo con el nombre del perfil y un botón para cerrar sesión y volver al login. Su barra inferior incluye **Principal**, **Mapa**, **Notificaciones** y **Mensajes**.

## Mapa y ubicación

La pestaña **Mapa** muestra OpenStreetMap y la ubicación del propio usuario. Al abrirla, la app solicita permiso para obtener una posición puntual y centrar el mapa. La posición no se comparte ni se guarda en Firestore, y no se consultan ni muestran ubicaciones de otros perfiles. Si la ubicación no está disponible, el mapa conserva un centro predeterminado y permite reintentar.

En Android se declaran permisos de ubicación aproximada y precisa, y en iOS la descripción del uso de ubicación en primer plano. En navegador se necesita un contexto seguro (HTTPS o localhost) y conceder el permiso del navegador. El mapa necesita conexión para descargar las teselas; si los servicios de ubicación están apagados, se deniega el permiso o se agota el tiempo de espera, se informa al usuario y se puede reintentar.

### Organización del código del mapa

- `lib/views/mapa_view.dart` coordina la pantalla, muestra el mapa y la ubicación propia, y gestiona los controles y mensajes.
- `lib/services/gps_admin.dart` comprueba el servicio y los permisos de ubicación y obtiene una posición puntual.

La pantalla no utiliza Firebase para mostrar la ubicación. No consulta terremotos ni perfiles de otras personas.

### Tecnologías de localización

El GPS usa señales de satélites: ofrece buena precisión en exteriores, aunque puede tardar en obtener una posición, consumir más batería y funcionar peor en interiores. La localización por red utiliza antenas móviles o redes Wi-Fi: suele responder rápido y funcionar mejor en interiores, pero depende de la cobertura y normalmente es menos precisa. El proveedor combinado del dispositivo utiliza las fuentes disponibles, junto con otros sensores cuando corresponde, para equilibrar precisión, tiempo de respuesta y consumo. La precisión real depende del entorno, el dispositivo y el permiso concedido; conviene usar la precisión necesaria para la tarea y evitar lecturas continuas cuando basta una posición puntual, como en este mapa.

## Pendiente de completar

- Añadir las fotos de bienvenida; por ahora se muestran iconos en su lugar.
- Implementar Notificaciones: actualmente muestra un aviso de que está pendiente.
- Implementar Mensajes: actualmente abre una pantalla temporal en la ruta `/XXX`.
