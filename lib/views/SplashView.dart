import 'dart:async';

import 'package:flutter/material.dart';

import '../services/EntradaApp.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key, this.destino});
  final Future<String> Function()? destino;
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const _gif =
      'https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExN2Q0emZtcWoxbzd0ZTJjMzZ2OWkyOHUwM3locXY2MWt5Y2lpM28yciZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gQbVzXQQbGO7C/giphy.gif';
  bool _cargando = true;
  bool _esperandoImagen = true;
  Timer? _imagenTimeout;
  String? _error;

  @override
  void initState() {
    super.initState();
    _imagenTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _esperandoImagen = false);
    });
    _abrir();
  }

  Future<void> _abrir() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // Simula una carga para poder ver el splash y su indicador.
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      final route = await (widget.destino ?? EntradaApp.destino)().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
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
  void dispose() {
    _imagenTimeout?.cancel();
    super.dispose();
  }

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
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : _esperandoImagen
                        ? const Center(child: CircularProgressIndicator())
                        : _placeholder(),
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
