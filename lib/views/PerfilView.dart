import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../insLib/BotBarStyle.dart';
import '../services/foto_perfil_service.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final _fotos = FotoPerfilService();
  bool _guardando = false;
  late final User? _usuario;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _perfilStream;

  @override
  void initState() {
    super.initState();
    _usuario = FirebaseAuth.instance.currentUser;
    _cargarPerfil();
  }

  void _cargarPerfil() {
    final usuario = _usuario;
    _perfilStream = usuario == null
        ? null
        : FirebaseFirestore.instance
              .collection('Perfiles')
              .doc(usuario.uid)
              .snapshots();
  }

  Future<void> _seleccionar(ImageSource origen) async {
    if (_guardando) return;
    setState(() => _guardando = true);
    try {
      final guardada = await _fotos.seleccionarYGuardar(origen);
      if (!mounted || !guardada) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto de perfil guardada.')));
    } on FotoPerfilException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.mensaje)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la foto. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _elegirOrigen() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Hacer una foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (origen != null && mounted) await _seleccionar(origen);
  }

  Uint8List? _decodificarFoto(Object? dato) {
    if (dato is! String || dato.isEmpty) return null;
    try {
      return base64Decode(dato);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      bottomNavigationBar: const Botbarstyle(iBarIndex: 3),
      body: usuario == null
          ? const Center(child: Text('Inicia sesión para ver tu perfil.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _perfilStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No se pudo cargar el perfil. Comprueba tu conexión.',
                        ),
                        TextButton(
                          onPressed: () => setState(_cargarPerfil),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final datos = snapshot.data!.data();
                if (datos == null) {
                  return const Center(child: Text('No se encontró tu perfil.'));
                }
                final nombre = datos['Nombre'];
                final edad = datos['Edad'];
                final fotoGuardada = datos['fotoBase64'];
                final foto = _decodificarFoto(fotoGuardada);
                final fotoInvalida =
                    fotoGuardada is String &&
                    fotoGuardada.isNotEmpty &&
                    foto == null;
                return SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Semantics(
                                label: foto == null
                                    ? 'Sin foto de perfil'
                                    : 'Tu foto de perfil',
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 144,
                                    height: 144,
                                    child: foto == null
                                        ? _fotoVacia(
                                            context,
                                            error: fotoInvalida,
                                          )
                                        : Image.memory(
                                            foto,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stack) =>
                                                    _fotoVacia(
                                                      context,
                                                      error: true,
                                                    ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _guardando ? null : _elegirOrigen,
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: Text(
                                foto == null ? 'Añadir foto' : 'Cambiar foto',
                              ),
                            ),
                            if (_guardando) ...[
                              const SizedBox(height: 16),
                              const LinearProgressIndicator(),
                              const SizedBox(height: 8),
                              const Text(
                                'Preparando y guardando la foto…',
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 28),
                            Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.person_outline),
                                    title: const Text('Nombre'),
                                    subtitle: Text(
                                      nombre is String &&
                                              nombre.trim().isNotEmpty
                                          ? nombre
                                          : 'Sin indicar',
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: const Icon(Icons.cake_outlined),
                                    title: const Text('Edad'),
                                    subtitle: Text(
                                      edad is num
                                          ? '${edad.toInt()} años'
                                          : 'Sin indicar',
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
              },
            ),
    );
  }

  Widget _fotoVacia(BuildContext context, {bool error = false}) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Semantics(
      label: error
          ? 'No se pudo cargar la foto de perfil'
          : 'Sin foto de perfil',
      child: Icon(
        error ? Icons.broken_image_outlined : Icons.person_outline,
        size: 72,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
