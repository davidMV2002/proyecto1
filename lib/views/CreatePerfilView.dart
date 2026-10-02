import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../FbObjects/Perfil.dart';

class Createperfilview extends StatelessWidget {
  late BuildContext miContext;
  TextEditingController edadController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;

  void funConfirmar() {
    if (edadController.text.isNotEmpty) {
      final perfiles = db.collection("Perfiles");
      final perfil = new Perfil(
        uid: FirebaseAuth.instance.currentUser!.uid,
        nombre: nombreController.text,
        edad: int.parse(edadController.text),
        deslizablesVistos: false,
      );
      perfiles
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set(perfil.toFirestore());
      Navigator.popAndPushNamed(miContext, "/HomeView");
    }
  }

  void funSalir() {
    Navigator.popAndPushNamed(miContext, "/LoginView");
  }

  @override
  Widget build(BuildContext context) {
    miContext = context;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            TextField(
              controller: nombreController,
              decoration: InputDecoration(hintText: "Nombre"),
            ),
            TextField(
              controller: edadController,
              decoration: InputDecoration(hintText: "Edad"),
            ),
            Row(
              mainAxisAlignment: .center,
              children: [
                TextButton(onPressed: funConfirmar, child: Text("Confirmar")),
                TextButton(onPressed: funSalir, child: Text("Salir")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
