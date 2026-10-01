import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto1/FbObjects/Perfil.dart';
import 'package:proyecto1/services/EntradaApp.dart';

void main() {
  test(
    'La entrada respeta sesión, existencia de perfil y bienvenida vista',
    () {
      expect(EntradaApp.rutaPara(haySesion: false), '/LoginView');
      expect(EntradaApp.rutaPara(haySesion: true), '/CreatePerfilView');
      expect(
        EntradaApp.rutaPara(haySesion: true, perfil: Perfil()),
        '/OnBoardingView',
      );
      expect(
        EntradaApp.rutaPara(
          haySesion: true,
          perfil: Perfil(deslizablesVistos: true),
        ),
        '/HomeView',
      );
    },
  );

  test('El perfil nuevo guarda false y el completado guarda true', () {
    final perfil = Perfil(nombre: 'Ana', edad: 20);
    expect(perfil.toFirestore()['deslizablesVistos'], false);
    perfil.deslizablesVistos = true;
    expect(perfil.toFirestore()['deslizablesVistos'], true);
    expect(perfil.toFirestore()['name'], 'Ana');
  });
}
