import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto1/FbObjects/Perfil.dart';

void main() {
  test('El perfil nuevo guarda false y el completado guarda true', () {
    final perfil = Perfil(nombre: 'Ana', edad: 20);
    expect(perfil.toFirestore()['deslizablesVistos'], false);
    perfil.deslizablesVistos = true;
    expect(perfil.toFirestore()['deslizablesVistos'], true);
  });
}
