import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:proyecto1/services/foto_perfil_service.dart';

void main() {
  test(
    'comprime una fotografía grande a JPEG base64 por debajo de 300 KiB',
    () {
      final original = img.Image(width: 1200, height: 900);
      final random = Random(42);
      for (final pixel in original) {
        pixel.setRgb(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
      }
      final entrada = Uint8List.fromList(img.encodePng(original));
      final resultado = comprimirMiniatura(entrada);
      expect(resultado, isNotNull);
      expect(resultado!.length, lessThan(300 * 1024));
      final foto = img.decodeJpg(base64Decode(resultado));
      expect(foto, isNotNull);
      expect(foto!.width, lessThanOrEqualTo(800));
      expect(foto.height, lessThanOrEqualTo(800));
      expect(foto.width / foto.height, closeTo(1200 / 900, 0.01));
    },
  );

  test('corrige la orientación EXIF antes de guardar', () {
    final original = img.Image(width: 120, height: 80);
    original.exif.imageIfd.orientation = 6;
    final entrada = Uint8List.fromList(img.encodeJpg(original));
    final resultado = comprimirMiniatura(entrada);
    expect(resultado, isNotNull);
    final foto = img.decodeJpg(base64Decode(resultado!));
    expect(foto, isNotNull);
    expect(foto!.width, 80);
    expect(foto.height, 120);
    expect(foto.exif.imageIfd.orientation, anyOf(isNull, 1));
  });

  test('rechaza archivos corruptos', () {
    expect(comprimirMiniatura(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}
