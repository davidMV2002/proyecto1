import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto1/FbObjects/Perfil.dart';

void main() {
  test(
    'lee y conserva la ubicación y fecha de Firestore como tipos nativos',
    () {
      const punto = GeoPoint(40.4168, -3.7038);
      final fecha = Timestamp.fromDate(DateTime.utc(2026, 11, 11));
      final perfil = Perfil.fromData('usuario', {
        'Nombre': 'David',
        'ubicacion': punto,
        'fechaUbicacion': fecha,
      });
      expect(perfil.ubicacion, punto);
      expect(perfil.fechaUbicacion, fecha);
      expect(perfil.toFirestore()['ubicacion'], punto);
      expect(perfil.toFirestore()['fechaUbicacion'], fecha);
      expect(perfil.toFirestore()['Nombre'], 'David');
    },
  );

  test('tolera una fecha pendiente o campos antiguos sin coordenadas', () {
    final perfil = Perfil.fromData('usuario', {
      'ubicacion': 'dato incorrecto',
      'fechaUbicacion': null,
    });
    expect(perfil.ubicacion, isNull);
    expect(perfil.fechaUbicacion, isNull);
  });
}
