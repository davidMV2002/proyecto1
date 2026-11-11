import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto1/services/gps_admin.dart';

void main() {
  test('calcula distancia aproximada entre Madrid y Lisboa en línea recta', () {
    final distancia = GPSAdmin().distanciaEnMetros(
      latitudOrigen: 40.4168,
      longitudOrigen: -3.7038,
      latitudDestino: 38.7223,
      longitudDestino: -9.1393,
    );
    expect(distancia, inInclusiveRange(490000, 515000));
  });

  test('distancia entre un punto y sí mismo es cero', () {
    expect(
      GPSAdmin().distanciaEnMetros(
        latitudOrigen: 40.4168,
        longitudOrigen: -3.7038,
        latitudDestino: 40.4168,
        longitudDestino: -3.7038,
      ),
      0,
    );
  });
}
