# Bienvenida y entrada

## Flujo

`MiApp` comienza en `/SplashView`. `EntradaApp` consulta la sesión de Firebase Authentication y `Perfiles/{uid}` en Firestore:

| Estado | Destino |
| --- | --- |
| Sin sesión | `/LoginView` |
| Sesión sin documento de perfil | `/CreatePerfilView` |
| Perfil con `deslizablesVistos` ausente o distinto de `true` | `/OnBoardingView` |
| Perfil con `deslizablesVistos: true` | `/HomeView` |

Login y registro vuelven al splash después de autenticarse. Creación de perfil y Home están registradas con avisos temporales; todavía hay que implementar esas pantallas.

`Onboardingview.deslizables()` muestra tres páginas que se recorren deslizando o pulsando **Siguiente**. **Comenzar** aparece en la tercera. **Omitir** y **Comenzar** guardan `deslizablesVistos: true` y abren Home cuando la escritura termina correctamente. Si falla, aparece un mensaje y se puede intentar otra vez. La actualización requiere un perfil existente; no crea documentos incompletos.

La marca pertenece al perfil en Firestore. El mismo perfil omite la bienvenida en siguientes entradas; uno nuevo comienza con `false`. Cerrar la app antes de omitir o completar mantiene la bienvenida pendiente. Las reglas de Firestore deben permitir leer el perfil y actualizar ese campo; este cambio no incluye reglas de seguridad.

## Añadir las tres fotos

Actualmente cada página muestra un icono. Para sustituirlo:

1. Crea `assets/images/` y añade tus fotos, por ejemplo `bienvenida_1.jpg`, `bienvenida_2.jpg` y `bienvenida_3.jpg`.
2. Añade la carpeta dentro del bloque `flutter:` existente de `pubspec.yaml`:

   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/
   ```

3. Sustituye los tres `null` de `_fotos` en `lib/views/OnBoardingView.dart`:

   ```dart
   static const List<String?> _fotos = [
     'assets/images/bienvenida_1.jpg',
     'assets/images/bienvenida_2.jpg',
     'assets/images/bienvenida_3.jpg',
   ];
   ```

Las imágenes usan proporción 4:3 y `BoxFit.cover`, por lo que pueden recortarse. Puedes personalizar `_titulos` y `_textos`, manteniendo tres elementos en cada lista.

## Conectar creación de perfil

Cuando implementes `/CreatePerfilView`, guarda el nuevo perfil del usuario autenticado con el modelo existente y vuelve al splash:

```dart
final perfil = Perfil(uid: uid, nombre: nombre, edad: edad);
await FirebaseFirestore.instance
    .collection('Perfiles')
    .doc(uid)
    .set(perfil.toFirestore());
if (!context.mounted) return;
Navigator.of(context).pushReplacementNamed('/SplashView');
```

`Perfil` inicializa `deslizablesVistos` a `false` y `toFirestore()` lo incluye junto con `name` y `edad` cuando tienen valor. Este ejemplo crea un perfil nuevo; no lo uses para sobrescribir uno existente y reiniciar su bienvenida.

## Splash y comprobaciones

El splash muestra la animación de bienvenida de su URL y carga mientras decide la entrada. Incluye un sustituto para imagen fallida o lenta y **Reintentar** si no consigue decidir el destino. La imagen del splash es independiente de las tres fotos locales.

Se han comprobado las decisiones de ruta, el modelo y la interacción de bienvenida mediante ocho pruebas Flutter. No se ha validado contra Firebase real ni en un dispositivo real. El análisis no presenta errores, pero mantiene advertencias previas de login/registro y avisos de estilo.

## Referencias locales

- [Perfil](../lib/FbObjects/Perfil.dart)
- [EntradaApp](../lib/services/EntradaApp.dart)
- [Splash](../lib/views/SplashView.dart)
- [Bienvenida](../lib/views/OnBoardingView.dart)
- [Rutas](../lib/MiApp.dart)
- [Configuración](../pubspec.yaml)
