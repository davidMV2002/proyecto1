# proyecto1

Aplicación Flutter con registro e inicio de sesión mediante Firebase Authentication y perfiles guardados en Cloud Firestore.

## Entrada a la app

`SplashView` comprueba la sesión y el perfil para decidir qué pantalla abrir:

- Sin sesión iniciada: `LoginView`.
- Con sesión, pero sin perfil: `CreatePerfilView`.
- Con perfil y bienvenida pendiente: `OnBoardingView`.
- Con perfil y bienvenida ya vista: `HomeView`.

Después de iniciar sesión se vuelve al splash para hacer estas comprobaciones. Al registrar una cuenta nueva se abre directamente la creación de perfil, donde se introduce el nombre y la edad. Tras guardar el perfil, comienza la bienvenida.

## Bienvenida y pantalla principal

La bienvenida tiene tres páginas deslizables y los botones **Siguiente**, **Omitir** y **Comenzar**. Al omitirla o completarla, se guarda `deslizablesVistos: true` en `Perfiles/{uid}` y se abre Home. Así no vuelve a mostrarse para ese perfil en los siguientes accesos. Si el campo no existe, la bienvenida se considera pendiente.

Home muestra un saludo con el nombre del perfil y un botón para cerrar sesión y volver al login. Su barra inferior incluye **Principal**, **Notificaciones** y **Mensajes**.

## Pendiente de completar

- Añadir las fotos de bienvenida; por ahora se muestran iconos en su lugar.
- Implementar Notificaciones: actualmente solo escribe «PROXIMAMENTE» en la consola.
- Implementar Mensajes: actualmente abre una pantalla temporal en la ruta `/XXX`.
