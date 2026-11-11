import 'package:cloud_firestore/cloud_firestore.dart';

/// Lecturas puntuales para los filtros de la colección de capitales.
/// Los errores de Firestore se propagan a la vista para que pueda mostrarlos.
class ConsultasCapitalesService {
  ConsultasCapitalesService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _capitales =>
      _firestore.collection('Capitales');

  /// Combina igualdad por zona y población mínima; requiere índice compuesto.
  Future<QuerySnapshot<Map<String, dynamic>>> filtrarZonaPoblacion({
    required String zona,
    required int poblacionMinima,
  }) => _capitales
      .where('zona', isEqualTo: zona)
      .where('poblacion', isGreaterThanOrEqualTo: poblacionMinima)
      .orderBy('poblacion')
      .orderBy(FieldPath.documentId)
      .get();

  /// Las capitales con mayor población, con un orden estable en empates.
  Future<QuerySnapshot<Map<String, dynamic>>> masPobladas({int limite = 10}) =>
      _capitales
          .orderBy('poblacion', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limite)
          .get();

  /// Incluye todos los instantes de ambas fechas en la zona horaria local.
  Future<QuerySnapshot<Map<String, dynamic>>> porFechas({
    required DateTime desde,
    required DateTime hasta,
  }) {
    final inicio = DateTime(desde.year, desde.month, desde.day);
    final finExclusivo = DateTime(hasta.year, hasta.month, hasta.day + 1);
    if (!finExclusivo.isAfter(inicio)) {
      throw ArgumentError('La fecha final debe ser posterior a la inicial.');
    }
    return _capitales
        .where(
          'fechaAnadida',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('fechaAnadida', isLessThan: Timestamp.fromDate(finExclusivo))
        .orderBy('fechaAnadida')
        .orderBy(FieldPath.documentId)
        .get();
  }

  /// La última instantánea de una página sirve de cursor para la siguiente.
  Future<QuerySnapshot<Map<String, dynamic>>> pagina({
    DocumentSnapshot<Map<String, dynamic>>? despues,
    int limite = 10,
  }) {
    Query<Map<String, dynamic>> consulta = _capitales
        .orderBy('nombre')
        .orderBy(FieldPath.documentId)
        .limit(limite);
    if (despues != null) consulta = consulta.startAfterDocument(despues);
    return consulta.get();
  }
}
