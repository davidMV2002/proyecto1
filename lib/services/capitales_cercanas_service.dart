import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'capitales_service.dart';

class CapitalCercana {
  const CapitalCercana({required this.capital, required this.metros});
  final Capital capital;
  final double metros;
}

/// Ordena capitales por distancia en línea recta a la posición indicada.
class CapitalesCercanasService {
  Future<List<CapitalCercana>> calcular({
    required double latitud,
    required double longitud,
    required List<Capital> capitales,
    void Function(double progreso)? onProgress,
  }) async {
    if (capitales.isEmpty) {
      onProgress?.call(1);
      return [];
    }
    final coordenadas = capitales
        .map(
          (capital) => [
            capital.ubicacion.latitude,
            capital.ubicacion.longitude,
          ],
        )
        .toList();
    onProgress?.call(0);
    late final List<double> distancias;
    late final List<int> indices;
    if (kIsWeb) {
      // Isolate.spawn no está disponible en web. Cedemos entre lotes.
      distancias = [];
      for (var i = 0; i < coordenadas.length; i++) {
        distancias.add(
          _distancia(latitud, longitud, coordenadas[i][0], coordenadas[i][1]),
        );
        onProgress?.call((i + 1) / (coordenadas.length + 1));
        if ((i + 1) % 20 == 0) await Future<void>.delayed(Duration.zero);
      }
      indices = List.generate(capitales.length, (i) => i)
        ..sort((a, b) => distancias[a].compareTo(distancias[b]));
    } else {
      final puerto = ReceivePort();
      final terminado = Completer<List<Object>>();
      Isolate? isolate;
      final suscripcion = puerto.listen((mensaje) {
        if (mensaje is double) {
          onProgress?.call(mensaje);
        } else if (mensaje is List<Object> &&
            mensaje.length == 2 &&
            mensaje[0] is List<double> &&
            mensaje[1] is List<int>) {
          if (!terminado.isCompleted) terminado.complete(mensaje);
        } else if (mensaje is List &&
            mensaje.length == 2 &&
            mensaje.first is String) {
          if (!terminado.isCompleted) {
            terminado.completeError(
              StateError('No se pudieron calcular las distancias.'),
            );
          }
        } else if (mensaje == null && !terminado.isCompleted) {
          terminado.completeError(
            StateError('El cálculo de distancias terminó sin resultado.'),
          );
        }
      });
      try {
        isolate = await Isolate.spawn(
          _calcularEnIsolate,
          [puerto.sendPort, latitud, longitud, coordenadas],
          onError: puerto.sendPort,
          onExit: puerto.sendPort,
          errorsAreFatal: true,
        );
        final resultado = await terminado.future;
        distancias = resultado[0] as List<double>;
        indices = resultado[1] as List<int>;
      } finally {
        isolate?.kill(priority: Isolate.immediate);
        await suscripcion.cancel();
        puerto.close();
      }
    }
    onProgress?.call(1);
    return [
      for (final i in indices)
        CapitalCercana(capital: capitales[i], metros: distancias[i]),
    ];
  }
}

void _calcularEnIsolate(List<Object> argumentos) {
  final puerto = argumentos[0] as SendPort;
  final latitud = argumentos[1] as double;
  final longitud = argumentos[2] as double;
  final coordenadas = argumentos[3] as List<List<double>>;
  final distancias = <double>[];
  for (var i = 0; i < coordenadas.length; i++) {
    distancias.add(
      _distancia(latitud, longitud, coordenadas[i][0], coordenadas[i][1]),
    );
    puerto.send((i + 1) / (coordenadas.length + 1));
  }
  final indices = List.generate(coordenadas.length, (i) => i)
    ..sort((a, b) => distancias[a].compareTo(distancias[b]));
  puerto.send(<Object>[distancias, indices]);
}

// Misma fórmula y radio terrestre que Geolocator.distanceBetween.
double _distancia(double lat1, double lon1, double lat2, double lon2) {
  const radianes = math.pi / 180;
  final deltaLat = (lat2 - lat1) * radianes;
  final deltaLon = (lon2 - lon1) * radianes;
  final a =
      math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1 * radianes) *
          math.cos(lat2 * radianes) *
          math.pow(math.sin(deltaLon / 2), 2);
  return 2 * 6378137.0 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}
