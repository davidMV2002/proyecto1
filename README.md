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

Home muestra un saludo con el nombre del perfil y un botón para cerrar sesión y volver al login. Su barra inferior incluye **Principal**, **Notificaciones** y **Mensajes**.

## Pendiente de completar

- Añadir las fotos de bienvenida; por ahora se muestran iconos en su lugar.
- Implementar Notificaciones: actualmente solo escribe «PROXIMAMENTE» en la consola.
- Implementar Mensajes: actualmente abre una pantalla temporal en la ruta `/XXX`.
