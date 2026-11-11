import 'package:cloud_firestore/cloud_firestore.dart';

/// Datos necesarios para mostrar una capital en el mapa.
class Capital {
  const Capital({
    required this.id,
    required this.nombre,
    required this.pais,
    required this.ubicacion,
  });

  final String id;
  final String nombre;
  final String pais;
  final GeoPoint ubicacion;

  /// Los documentos incompletos o con coordenadas inválidas no se muestran.
  static Capital? desdeDocumento(String id, Map<String, dynamic> datos) {
    final nombre = datos['nombre'];
    final pais = datos['pais'];
    final ubicacion = datos['ubicacion'];
    if (nombre is! String ||
        nombre.trim().isEmpty ||
        pais is! String ||
        pais.trim().isEmpty ||
        ubicacion is! GeoPoint ||
        !ubicacion.latitude.isFinite ||
        !ubicacion.longitude.isFinite ||
        ubicacion.latitude.abs() > 90 ||
        ubicacion.longitude.abs() > 180) {
      return null;
    }
    return Capital(
      id: id,
      nombre: nombre.trim(),
      pais: pais.trim(),
      ubicacion: ubicacion,
    );
  }
}

class CapitalesService {
  CapitalesService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Capital>> observarCapitales() => _firestore
      .collection('Capitales')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Capital.desdeDocumento(doc.id, doc.data()))
            .whereType<Capital>()
            .toList(),
      );
}
