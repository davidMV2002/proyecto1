import 'package:cloud_firestore/cloud_firestore.dart';

class Perfil {
  String? uid;
  String? nombre;
  int? edad;
  bool deslizablesVistos;

  Perfil({this.uid, this.nombre, this.edad, this.deslizablesVistos = false});

  factory Perfil.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Perfil(
      uid: snapshot.id,
      nombre: data?['name'] as String?,
      edad: (data?['edad'] as num?)?.toInt(),
      deslizablesVistos: data?['deslizablesVistos'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'deslizablesVistos': deslizablesVistos,
      if (nombre != null) "name": nombre,
      if (edad != null) "edad": edad,
    };
  }
}
