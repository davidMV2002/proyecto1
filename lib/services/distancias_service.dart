import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'perfil_mapa.dart';

class PerfilDistancia {
  const PerfilDistancia(this.perfil, this.metros);
  final PerfilMapa perfil;
  final double metros;
}

/// Calcula distancias fuera del hilo de interfaz en plataformas nativas.
/// En web, donde Isolate.spawn no está disponible, cede el control entre lotes.
class DistanciasService {
  Future<List<PerfilDistancia>> calcular({
    required double latitud,
    required double longitud,
    required List<PerfilMapa> perfiles,
    void Function(double progreso)? onProgress,
  }) async {
    final coordenadas = perfiles
        .map((p) => [p.ubicacion.latitude, p.ubicacion.longitude])
        .toList();
    if (coordenadas.isEmpty) {
      onProgress?.call(1);
      return [];
    }
    final List<double> distancias;
    List<int>? indicesOrdenados;
    if (kIsWeb) {
      distancias = [];
      for (var i = 0; i < coordenadas.length; i++) {
        distancias.add(
          _distancia(latitud, longitud, coordenadas[i][0], coordenadas[i][1]),
        );
        onProgress?.call((i + 1) / coordenadas.length);
        if (i % 50 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    } else {
      final puerto = ReceivePort();
      Isolate? isolate;
      final resultado = Completer<List<Object>>();
      try {
        final suscripcion = puerto.listen((mensaje) {
          if (mensaje is double) {
            onProgress?.call(mensaje);
          } else if (mensaje is List<Object> &&
              mensaje.length == 2 &&
              mensaje[0] is List<double> &&
              mensaje[1] is List<int>) {
            if (!resultado.isCompleted) {
              resultado.complete(mensaje);
            }
          } else if (mensaje is List &&
              mensaje.length == 2 &&
              mensaje.first is String) {
            if (!resultado.isCompleted) {
              resultado.completeError(
                StateError('No se pudo calcular las distancias.'),
              );
            }
          }
        });
        try {
          isolate = await Isolate.spawn(
            _calcularEnIsolate,
            [puerto.sendPort, latitud, longitud, coordenadas],
            onError: puerto.sendPort,
            errorsAreFatal: true,
          );
          final datos = await resultado.future;
          distancias = datos[0] as List<double>;
          indicesOrdenados = datos[1] as List<int>;
        } finally {
          isolate?.kill(priority: Isolate.immediate);
          await suscripcion.cancel();
        }
      } finally {
        puerto.close();
      }
    }
    final indices =
        indicesOrdenados ?? List.generate(perfiles.length, (i) => i);
    if (indicesOrdenados == null) {
      indices.sort((a, b) => distancias[a].compareTo(distancias[b]));
    }
    final ordenados = indices
        .map((i) => PerfilDistancia(perfiles[i], distancias[i]))
        .toList();
    return ordenados;
  }
}

void _calcularEnIsolate(List<Object> argumentos) {
  final puerto = argumentos[0] as SendPort;
  final latitud = argumentos[1] as double;
  final longitud = argumentos[2] as double;
  final puntos = argumentos[3] as List<List<double>>;
  final resultado = <double>[];
  for (var i = 0; i < puntos.length; i++) {
    resultado.add(_distancia(latitud, longitud, puntos[i][0], puntos[i][1]));
    puerto.send((i + 1) / puntos.length);
  }
  final indices = List.generate(resultado.length, (i) => i);
  indices.sort((a, b) => resultado[a].compareTo(resultado[b]));
  puerto.send(<Object>[resultado, indices]);
}

double _distancia(double lat1, double lon1, double lat2, double lon2) {
  const radioTerrestre = 6371000.0;
  const radianes = math.pi / 180;
  final deltaLat = (lat2 - lat1) * radianes;
  final deltaLon = (lon2 - lon1) * radianes;
  final a =
      math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1 * radianes) *
          math.cos(lat2 * radianes) *
          math.pow(math.sin(deltaLon / 2), 2);
  return 2 * radioTerrestre * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}
