import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Perfil {
  String? uid;
  String? nombre;
  int? edad;

  Perfil({this.uid, this.nombre, this.edad});

  factory Perfil.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,) {
    final data = snapshot.data();
    return Perfil(
      uid: snapshot.id,
      nombre: data?['name'] as String?,
      edad: (data?['edad'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (nombre != null) "name": nombre,
      if (edad != null) "edad": edad,
    };
  }
}