import 'package:cloud_firestore/cloud_firestore.dart';

/// Un perfil que tiene coordenadas válidas y puede mostrarse en el mapa.
class PerfilMapa {
  const PerfilMapa({
    required this.uid,
    required this.nombre,
    required this.edad,
    required this.ubicacion,
    required this.fechaUbicacion,
  });

  final String uid;
  final String nombre;
  final int? edad;
  final GeoPoint ubicacion;
  final Timestamp? fechaUbicacion;
}
