import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto1/services/distancias_service.dart';
import 'package:proyecto1/services/perfil_mapa.dart';

PerfilMapa perfil(String uid, double latitud, double longitud) => PerfilMapa(
  uid: uid,
  nombre: uid,
  edad: null,
  ubicacion: GeoPoint(latitud, longitud),
  fechaUbicacion: null,
);

void main() {
  test('ordena perfiles por distancia y comunica el progreso', () async {
    final progreso = <double>[];
    final perfiles = [
      perfil('lejos', 0, 2),
      perfil('mismo sitio', 0, 0),
      perfil('cerca', 0, 1),
    ];

    final resultados = await DistanciasService().calcular(
      latitud: 0,
      longitud: 0,
      perfiles: perfiles,
      onProgress: progreso.add,
    );

    expect(resultados.map((r) => r.perfil.uid), [
      'mismo sitio',
      'cerca',
      'lejos',
    ]);
    expect(resultados[0].metros, closeTo(0, 0.01));
    expect(resultados[1].metros, closeTo(111195, 100));
    expect(resultados[2].metros, closeTo(222390, 200));
    expect(progreso, isNotEmpty);
    expect(progreso.last, 1);
    expect(progreso, orderedEquals([1 / 3, 2 / 3, 1.0]));
  });

  test('devuelve lista vacía y termina el progreso sin perfiles', () async {
    final progreso = <double>[];
    final resultados = await DistanciasService().calcular(
      latitud: 0,
      longitud: 0,
      perfiles: [],
      onProgress: progreso.add,
    );
    expect(resultados, isEmpty);
    expect(progreso, [1.0]);
  });
}
