import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proyecto1/services/capitales_service.dart';
import 'package:proyecto1/views/mapa_view.dart';

void main() {
  testWidgets('muestra capitales ya recibidas sin esperar otra emisión', (
    tester,
  ) async {
    final stream = StreamController<List<Capital>>.broadcast();
    final capitales = [
      const Capital(
        id: 'lisboa',
        nombre: 'Lisboa',
        pais: 'Portugal',
        ubicacion: GeoPoint(38.7223, -9.1393),
      ),
      const Capital(
        id: 'madrid',
        nombre: 'Madrid',
        pais: 'España',
        ubicacion: GeoPoint(40.4168, -3.7038),
      ),
    ];
    final position = Position(
      latitude: 40.4168,
      longitude: -3.7038,
      timestamp: DateTime.utc(2026),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaCapitalesCercanas(
            capitales: stream.stream,
            capitalesIniciales: capitales,
            posicionInicial: position,
            obtenerPosicion: () async => position,
            mensajeUbicacion: () => null,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 20 && find.text('Madrid').evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Madrid'), findsOneWidget);
    expect(find.text('Lisboa'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Madrid')).dy,
      lessThan(tester.getTopLeft(find.text('Lisboa')).dy),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await stream.close();
  });
}
