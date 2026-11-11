import 'package:cloud_firestore/cloud_firestore.dart';

class Perfil {
  String? uid;
  String? nombre;
  int? edad;
  String? fotoBase64;
  bool deslizablesVistos;

  Perfil({
    this.uid,
    this.nombre,
    this.edad,
    this.fotoBase64,
    this.deslizablesVistos = false,
  });

  factory Perfil.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Perfil(
      uid: snapshot.id,
      nombre: data?['Nombre'] as String?,
      edad: (data?['Edad'] as num?)?.toInt(),
      fotoBase64: data?['fotoBase64'] as String?,
      deslizablesVistos: data?['deslizablesVistos'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'deslizablesVistos': deslizablesVistos,
      if (nombre != null) "Nombre": nombre,
      if (edad != null) "Edad": edad,
      if (fotoBase64 != null) 'fotoBase64': fotoBase64,
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
