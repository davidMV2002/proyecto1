import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../DataHolder.dart';
import '../FbObjects/Perfil.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const _gif =
      'https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExN2Q0emZtcWoxbzd0ZTJjMzZ2OWkyOHUwM3locXY2MWt5Y2lpM28yciZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gQbVzXQQbGO7C/giphy.gif';
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _abrir();
  }

  Future<void> _abrir() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      final usuario = FirebaseAuth.instance.currentUser;
      String ruta;

      if (usuario == null) {
        ruta = '/LoginView';
      } else {
        final documento = await FirebaseFirestore.instance
            .collection('Perfiles')
            .doc(usuario.uid)
            .get();

        if (!documento.exists) {
          ruta = '/CreatePerfilView';
        } else {
          final perfil = Perfil.fromFirestore(documento, null);
          Dataholder.instance.perfilUsuario = perfil;

          if (perfil.deslizablesVistos) {
            ruta = '/HomeView';
          } else {
            ruta = '/OnBoardingView';
          }
        }
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, ruta);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo abrir la app. Comprueba tu conexión e inténtalo de nuevo.';
      });
    }
  }

  Widget _placeholder() => const SizedBox(
    height: 180,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.apps, size: 72, semanticLabel: 'Bienvenida a la app'),
        SizedBox(height: 16),
        Text('No se pudo cargar la imagen', textAlign: TextAlign.center),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 220,
                  child: Image.network(
                    _gif,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _placeholder(),
                    semanticLabel: 'Animación de bienvenida',
                  ),
                ),
                const SizedBox(height: 24),
                if (_cargando) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Preparando la app…'),
                ],
                if (_error != null) ...[
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _abrir,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
