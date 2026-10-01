import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../DataHolder.dart';
import '../FbObjects/Perfil.dart';

class Onboardingview extends StatefulWidget{
  const Onboardingview({ super.key });

  @override
  State<Onboardingview> createState() =>_Onboardingview();
}

class _Onboardingview extends State<Onboardingview>{
  FirebaseFirestore db = FirebaseFirestore.instance;
  int _iProgress = 0;
  bool deslizablesVistos = false;


  @override
  void initState() {
    super.initState();
    cargarRecursos();
  }

  void cargarRecursos() async{
    await recursos1();
    setState(() {
      _iProgress=20;
    });
    await recursos2();
    setState(() {
      _iProgress=80;
    });
    await recursos3();
    setState(() {
      _iProgress=100;
    });


    if(FirebaseAuth.instance.currentUser==null){
      Navigator.popAndPushNamed(context, "/LoginView");
    }
    //SIEMPRE Y CUANDO SE HAYA LOGEADO O REGISTRO ANTES
    else{
      String uid=FirebaseAuth.instance.currentUser!.uid;
      print("EL UID DEL URUSARIO LOGEADO ES: "+uid);

      final docRef = db.collection("Perfiles").doc(uid).withConverter(
        fromFirestore: Perfil.fromFirestore,
        toFirestore: (Perfil perfil, _) => perfil.toFirestore(),
      );

      final docSnap = await docRef.get();
      Dataholder.instance.perfilUsuario=docSnap.data()!;

      //NO TIENE PERFIL EN LA BASE DE DATOS
      if(Dataholder.instance.perfilUsuario==null){
        Navigator.popAndPushNamed(context, "/Profileview");
      }
      else{
        //SI TIENE PERFIL EN LA BASE DATOS
        Navigator.popAndPushNamed(context, "/HomeView");
      }
    }
  }

  Future<void> recursos1() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> recursos2() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> recursos3() async {
    await Future.delayed(const Duration(seconds: 1));
  }



  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}