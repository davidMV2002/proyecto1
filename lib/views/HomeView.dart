import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proyecto1/DataHolder.dart';
import 'package:proyecto1/insLib/BotBarStyle.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});

  @override
  State<Homeview> createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  late BuildContext miContext;
  FirebaseFirestore db=FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    Dataholder.instance.iBarIndex=0;

  }

  void cerrarSesion(){
    FirebaseAuth.instance.signOut();
    Navigator.popAndPushNamed(miContext, "/LoginView");
  }

  @override
  Widget build(BuildContext context) {
    miContext = context;
    return Scaffold(
      body: Column(
        mainAxisAlignment: .center,
        children: [
          Text("Hola " + Dataholder.instance.perfilUsuario.nombre.toString()),
          TextButton(onPressed: cerrarSesion, child: Text("Cerrar sesión")),
        ],
      ),
      bottomNavigationBar: Botbarstyle(
        iBarIndex: Dataholder.instance.iBarIndex,
      ),
    );
  }
}
