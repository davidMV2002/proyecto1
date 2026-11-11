import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:flutter/services.dart' show PlatformException;
import 'package:image/image.dart' as imagen;
import 'package:image_picker/image_picker.dart';

/// Error comprensible para mostrar en la pantalla de perfil.
class FotoPerfilException implements Exception {
  const FotoPerfilException(this.mensaje);
  final String mensaje;
}

class FotoPerfilService {
  FotoPerfilService({
    ImagePicker? selector,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _selector = selector ?? ImagePicker(),
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final ImagePicker _selector;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Devuelve false si se cancela la selección; nunca guarda un archivo original.
  Future<bool> seleccionarYGuardar(ImageSource origen) async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      throw const FotoPerfilException('Inicia sesión para guardar tu foto.');
    }
    try {
      final archivo = await _selector.pickImage(source: origen);
      if (archivo == null) return false;
      final bytes = await archivo.readAsBytes();
      final miniatura = await compute(comprimirMiniatura, bytes);
      if (miniatura == null) {
        throw const FotoPerfilException(
          'No se pudo procesar la imagen. Prueba con otra fotografía.',
        );
      }
      // update conserva los demás campos del perfil.
      await _firestore.collection('Perfiles').doc(usuario.uid).update({
        'fotoBase64': miniatura,
      });
      return true;
    } on FotoPerfilException {
      rethrow;
    } on PlatformException catch (error) {
      final codigo = error.code.toLowerCase();
      if (codigo.contains('denied') || codigo.contains('permission')) {
        throw FotoPerfilException(
          origen == ImageSource.camera
              ? 'No hay permiso para usar la cámara. Actívalo en los ajustes del dispositivo e inténtalo de nuevo.'
              : 'No hay permiso para acceder a las fotos. Actívalo en los ajustes del dispositivo e inténtalo de nuevo.',
        );
      }
      throw const FotoPerfilException(
        'No se pudo abrir la cámara o la galería. Inténtalo de nuevo.',
      );
    } on FirebaseException {
      throw const FotoPerfilException(
        'No se pudo guardar la foto. Comprueba tu conexión e inténtalo de nuevo.',
      );
    } catch (_) {
      throw const FotoPerfilException(
        'No se pudo preparar la foto. Prueba con otra imagen.',
      );
    }
  }
}

/// Se ejecuta con compute (un isolate en Android/iOS). El límite se aplica
/// al texto base64 guardado en Firestore.
@visibleForTesting
String? comprimirMiniatura(Uint8List bytes) {
  imagen.Image? original;
  try {
    original = imagen.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (original == null) return null;
  var foto = imagen.bakeOrientation(original);
  const ladoMaximo = 800;
  if (foto.width > ladoMaximo || foto.height > ladoMaximo) {
    foto = foto.width >= foto.height
        ? imagen.copyResize(foto, width: ladoMaximo)
        : imagen.copyResize(foto, height: ladoMaximo);
  }
  const limiteTexto = 300 * 1024;
  for (var intento = 0; intento < 4; intento++) {
    for (final calidad in [85, 70, 55, 40]) {
      final resultado = base64Encode(imagen.encodeJpg(foto, quality: calidad));
      if (resultado.length < limiteTexto) return resultado;
    }
    if (foto.width <= 100 || foto.height <= 100) break;
    foto = imagen.copyResize(foto, width: (foto.width * 0.7).round());
  }
  return null;
}
