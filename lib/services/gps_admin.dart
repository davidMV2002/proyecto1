import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class UbicacionException implements Exception {
  const UbicacionException(this.mensaje, {this.requiereAjustes = false});

  final String mensaje;
  final bool requiereAjustes;

  @override
  String toString() => mensaje;
}

class GPSAdmin {
  /// Distancia en línea recta, en metros, entre dos coordenadas geográficas.
  double distanciaEnMetros({
    required double latitudOrigen,
    required double longitudOrigen,
    required double latitudDestino,
    required double longitudDestino,
  }) => Geolocator.distanceBetween(
    latitudOrigen,
    longitudOrigen,
    latitudDestino,
    longitudDestino,
  );

  /// Guarda únicamente en el perfil privado del usuario autenticado.
  Future<void> guardarUbicacion(Position posicion) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw const UbicacionException(
        'Inicia sesión para guardar la ubicación.',
      );
    }
    await FirebaseFirestore.instance
        .collection('Perfiles')
        .doc(usuario.uid)
        .update({
          'ubicacion': GeoPoint(posicion.latitude, posicion.longitude),
          'fechaUbicacion': FieldValue.serverTimestamp(),
        });
  }

  /// Pide permiso y lee la posición sin compartirla con otros usuarios.
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
}
