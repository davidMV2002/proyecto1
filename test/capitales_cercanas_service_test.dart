import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto1/services/capitales_cercanas_service.dart';
import 'package:proyecto1/services/capitales_service.dart';
import 'package:proyecto1/services/gps_admin.dart';

Capital capital(String nombre, double latitud, double longitud) => Capital(
  id: nombre,
  nombre: nombre,
  pais: 'Prueba',
  ubicacion: GeoPoint(latitud, longitud),
);

void main() {
  test('ordena por cercanía y comunica progreso hasta finalizar', () async {
    final origenLat = 40.4168;
    final origenLon = -3.7038;
    final lista = [
      capital('Roma', 41.9028, 12.4964),
      capital('Madrid', origenLat, origenLon),
      capital('Lisboa', 38.7223, -9.1393),
    ];
    final progreso = <double>[];
    final orden = await CapitalesCercanasService().calcular(
      latitud: origenLat,
      longitud: origenLon,
      capitales: lista,
      onProgress: progreso.add,
    );
    expect(orden.map((e) => e.capital.nombre), ['Madrid', 'Lisboa', 'Roma']);
    expect(orden.first.metros, closeTo(0, 0.01));
    final referencia = GPSAdmin().distanciaEnMetros(
      latitudOrigen: origenLat,
      longitudOrigen: origenLon,
      latitudDestino: 38.7223,
      longitudDestino: -9.1393,
    );
    expect(orden[1].metros, closeTo(referencia, 0.01));
    expect(progreso.first, 0);
    expect(progreso.last, 1);
    expect(progreso, orderedEquals([...progreso]..sort()));
  });
  test('una lista vacía termina sin crear resultados', () async {
    final progreso = <double>[];
    final resultado = await CapitalesCercanasService().calcular(
      latitud: 0,
      longitud: 0,
      capitales: [],
      onProgress: progreso.add,
    );
    expect(resultado, isEmpty);
    expect(progreso, [1]);
  });
}
