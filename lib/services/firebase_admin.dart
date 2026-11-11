import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'gps_admin.dart';
import 'perfil_mapa.dart';

class FirebaseAdmin {
  FirebaseAdmin({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Omite perfiles sin coordenadas o con datos incorrectos.
  Stream<List<PerfilMapa>> observarPerfiles() =>
      _firestore.collection('Perfiles').snapshots().map((snapshot) {
        final perfiles = <PerfilMapa>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final posicion = data['ubicacion'];
          if (posicion is! GeoPoint ||
              !posicion.latitude.isFinite ||
              !posicion.longitude.isFinite ||
              posicion.latitude.abs() > 90 ||
              posicion.longitude.abs() > 180) {
            continue;
          }
          final nombre = data['Nombre'];
          final edad = data['Edad'];
          final fecha = data['fechaUbicacion'];
          perfiles.add(
            PerfilMapa(
              uid: doc.id,
              nombre: nombre is String && nombre.trim().isNotEmpty
                  ? nombre.trim()
                  : 'Perfil sin nombre',
              edad: edad is num ? edad.toInt() : null,
              ubicacion: posicion,
              fechaUbicacion: fecha is Timestamp ? fecha : null,
            ),
          );
        }
        return perfiles;
      });

  /// Se debe invocar únicamente tras una acción explícita del usuario.
  Future<void> guardarUbicacion(Position posicion) async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      throw const UbicacionException(
        'Inicia sesión para compartir tu ubicación.',
      );
    }
    await _firestore.collection('Perfiles').doc(usuario.uid).update({
      'ubicacion': GeoPoint(posicion.latitude, posicion.longitude),
      'fechaUbicacion': FieldValue.serverTimestamp(),
    });
  }
}
