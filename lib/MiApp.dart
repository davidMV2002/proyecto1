import 'package:flutter/material.dart';
import 'package:proyecto1/views/LoginView.dart';
import 'package:proyecto1/views/OnBoardingView.dart';
import 'package:proyecto1/views/RegistroView.dart';
import 'package:proyecto1/views/SplashView.dart';

class Miapp extends StatelessWidget {
  const Miapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRIMER PROYECTO',
      routes: {
        '/SplashView': (context) => const SplashView(),
        '/OnBoardingView': (context) => const Onboardingview(),
        '/LoginView': (context) => Loginview(),
        '/RegistroView': (context) => Registroview(),
        // Sustituye estos avisos por tus pantallas cuando las implementes.
        '/CreatePerfilView': (context) =>
            const _PantallaPendiente('Crear perfil'),
        '/HomeView': (context) => const _PantallaPendiente('Home'),
      },
      initialRoute: '/SplashView',
    );
  }
}

class _PantallaPendiente extends StatelessWidget {
  const _PantallaPendiente(this.nombre);
  final String nombre;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(nombre)),
    body: Center(child: Text('Pantalla $nombre pendiente de implementar.')),
  );
}
