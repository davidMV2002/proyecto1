import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Un perfil que tiene coordenadas válidas y puede mostrarse en el mapa.
class PerfilMapa {
  const PerfilMapa({
    required this.uid,
    required this.nombre,
    required this.edad,
    required this.ubicacion,
    required this.fechaUbicacion,
  });

  final String uid;
  final String nombre;
  final int? edad;
  final GeoPoint ubicacion;
  final Timestamp? fechaUbicacion;
}

class UbicacionException implements Exception {
  const UbicacionException(this.mensaje, {this.requiereAjustes = false});

  final String mensaje;
  final bool requiereAjustes;

  @override
  String toString() => mensaje;
}

class MapaService {
  MapaService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Omite perfiles sin coordenadas o con datos incorrectos.
  Stream<List<PerfilMapa>> observarPerfiles() =>
      _firestore.collection('Perfiles').snapshots().map((snapshot) {
        final perfiles = <PerfilMapa>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final posicion = data['ubicacion'];
          if (posicion is! GeoPoint ||
              !posicion.latitude.isFinite ||
              !posicion.longitude.isFinite ||
              posicion.latitude.abs() > 90 ||
              posicion.longitude.abs() > 180) {
            continue;
          }
          final nombre = data['Nombre'];
          final edad = data['Edad'];
          final fecha = data['fechaUbicacion'];
          perfiles.add(
            PerfilMapa(
              uid: doc.id,
              nombre: nombre is String && nombre.trim().isNotEmpty
                  ? nombre.trim()
                  : 'Perfil sin nombre',
              edad: edad is num ? edad.toInt() : null,
              ubicacion: posicion,
              fechaUbicacion: fecha is Timestamp ? fecha : null,
            ),
          );
        }
        return perfiles;
      });

  /// Pide permiso y lee la posición; no la guarda ni la comparte.
  Future<Position> obtenerUbicacion() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const UbicacionException(
          'La ubicación está desactivada. Actívala e inténtalo de nuevo.',
          requiereAjustes: true,
        );
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        throw const UbicacionException(
          'Has denegado el permiso de ubicación. Puedes volver a intentarlo.',
        );
      }
      if (permiso == LocationPermission.deniedForever) {
        throw UbicacionException(
          kIsWeb
              ? 'La ubicación está bloqueada. Actívala en los permisos del navegador.'
              : 'La ubicación está bloqueada. Actívala en los ajustes de la aplicación.',
          requiereAjustes: true,
        );
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on UbicacionException {
      rethrow;
    } on TimeoutException {
      throw const UbicacionException(
        'No se pudo obtener la ubicación a tiempo. Comprueba la señal e inténtalo de nuevo.',
      );
    } catch (_) {
      throw const UbicacionException(
        'No se pudo obtener la ubicación. Comprueba el permiso y la conexión e inténtalo de nuevo.',
      );
    }
  }

  /// Se debe invocar únicamente tras una acción explícita del usuario.
  Future<void> guardarUbicacion(Position posicion) async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      throw const UbicacionException(
        'Inicia sesión para compartir tu ubicación.',
      );
    }
    await _firestore.collection('Perfiles').doc(usuario.uid).update({
      'ubicacion': GeoPoint(posicion.latitude, posicion.longitude),
      'fechaUbicacion': FieldValue.serverTimestamp(),
    });
  }
}
