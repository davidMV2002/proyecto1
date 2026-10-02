import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../DataHolder.dart';

class Onboardingview extends StatefulWidget {
  const Onboardingview({super.key});
  @override
  State<Onboardingview> createState() => _Onboardingview();
}

class _Onboardingview extends State<Onboardingview> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _guardando = false;
  String? _error;
  // Sustituye cada null por la ruta de tu foto y declara los assets en pubspec.yaml.
  // Ejemplo: 'assets/images/bienvenida_1.jpg'.
  static const List<String?> _fotos = [null, null, null];
  static const _titulos = [
    '¡Te damos la bienvenida!',
    'Descubre tu espacio',
    'Todo listo para empezar',
  ];
  static const _textos = [
    'Nos alegra tenerte aquí. Conoce la app en estos tres pasos.',
    'Explora la app a tu ritmo y disfruta de todo lo que tiene para ti.',
    'Tu cuenta está lista. Comienza tu experiencia y descubre la app.',
  ];

  Future<void> _completar() async {
    if (_guardando) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) {
        Navigator.pushReplacementNamed(context, '/LoginView');
        return;
      }

      await FirebaseFirestore.instance
          .collection('Perfiles')
          .doc(usuario.uid)
          .update({'deslizablesVistos': true});
      Dataholder.instance.perfilUsuario.deslizablesVistos = true;
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/HomeView');
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'No se pudo guardar la bienvenida. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _siguiente() {
    if (_page == 2) {
      _completar();
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget deslizables() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PageView.builder(
      controller: _controller,
      itemCount: 3,
      onPageChanged: (page) => setState(() => _page = page),
      itemBuilder: (context, index) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _fotos[index] == null
                    ? ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_outlined,
                          size: 72,
                          color: colors.onSurfaceVariant,
                          semanticLabel: 'Imagen de bienvenida ${index + 1}',
                        ),
                      )
                    : Image.asset(
                        _fotos[index]!,
                        fit: BoxFit.cover,
                        semanticLabel: _titulos[index],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              header: true,
              child: Text(
                _titulos[index],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _textos[index],
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextButton(
                      onPressed: _guardando ? null : _completar,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Omitir'),
                    ),
                  ),
                ),
                Expanded(child: deslizables()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        label: 'Paso ${_page + 1} de 3',
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: index == _page ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == _page
                                      ? colors.primary
                                      : colors.outline,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _guardando ? null : _siguiente,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 56),
                          ),
                          child: Text(
                            _guardando
                                ? 'Guardando…'
                                : _page == 2
                                ? 'Comenzar'
                                : 'Siguiente',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
