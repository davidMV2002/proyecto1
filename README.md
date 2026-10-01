# proyecto1

Aplicación Flutter con Firebase Authentication y Cloud Firestore.

La entrada comienza en `SplashView`: comprueba la sesión y el perfil antes de abrir login, creación de perfil, bienvenida o Home. La bienvenida tiene tres páginas deslizables con espacios para tus fotos y botones **Siguiente**, **Omitir** y **Comenzar**.

Al omitir o completar se guarda `deslizablesVistos: true` en `Perfiles/{uid}`. Se recuerda por perfil en Firestore, sin preferencias locales por instalación. Los perfiles sin ese campo tienen la bienvenida pendiente.

Consulta [la guía de bienvenida](docs/onboarding.md) para añadir fotos y conectar la creación de perfil. `/CreatePerfilView` y `/HomeView` muestran avisos temporales hasta implementar sus pantallas.
