import 'package:cloud_firestore/cloud_firestore.dart';

class Perfil {
  String? uid;
  String? nombre;
  int? edad;
  String? fotoBase64;
  GeoPoint? ubicacion;
  Timestamp? fechaUbicacion;
  bool deslizablesVistos;

  Perfil({
    this.uid,
    this.nombre,
    this.edad,
    this.fotoBase64,
    this.ubicacion,
    this.fechaUbicacion,
    this.deslizablesVistos = false,
  });

  factory Perfil.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    return Perfil.fromData(snapshot.id, snapshot.data());
  }

  factory Perfil.fromData(String uid, Map<String, dynamic>? data) {
    return Perfil(
      uid: uid,
      nombre: data?['Nombre'] as String?,
      edad: (data?['Edad'] as num?)?.toInt(),
      fotoBase64: data?['fotoBase64'] as String?,
      ubicacion: data?['ubicacion'] is GeoPoint
          ? data!['ubicacion'] as GeoPoint
          : null,
      fechaUbicacion: data?['fechaUbicacion'] is Timestamp
          ? data!['fechaUbicacion'] as Timestamp
          : null,
      deslizablesVistos: data?['deslizablesVistos'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'deslizablesVistos': deslizablesVistos,
      if (nombre != null) "Nombre": nombre,
      if (edad != null) "Edad": edad,
      if (fotoBase64 != null) 'fotoBase64': fotoBase64,
      if (ubicacion != null) 'ubicacion': ubicacion,
      if (fechaUbicacion != null) 'fechaUbicacion': fechaUbicacion,
    };
  }
}

CollectionReference<Perfil> perfilesCollection(FirebaseFirestore firestore) =>
    firestore
        .collection('Perfiles')
        .withConverter<Perfil>(
          fromFirestore: Perfil.fromFirestore,
          toFirestore: (perfil, options) => perfil.toFirestore(),
        );
