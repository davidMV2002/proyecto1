import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Loginview extends StatelessWidget {
  var faInstance = FirebaseAuth.instance;
  late BuildContext miContext;
  TextEditingController userController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;

  void funClickLogin() async {
    String usuario = userController.text;
    String pass = passwordController.text;

    try {
      await faInstance.signInWithEmailAndPassword(
        email: usuario,
        password: pass,
      );
      if (!miContext.mounted) return;
      Navigator.pushReplacementNamed(miContext, '/SplashView');
    } on FirebaseAuthException catch (e) {
      print("----------------->>>>>> " + e.toString());
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  void funClickRegistro() {
    print("---->>>>>>>> REGISTRO PRESIONADO");
    Navigator.popAndPushNamed(miContext, "/RegistroView");
  }

  @override
  Widget build(BuildContext context) {
    miContext = context;
    return Scaffold(
      appBar: new AppBar(title: new Text("MI APP DAM2627")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "LOGIN",
            style: TextStyle(fontSize: 30, backgroundColor: Colors.red),
          ),
          TextField(
            controller: userController,
            decoration: InputDecoration(hintText: "Usuario"),
          ),
          TextField(
            obscureText: true,
            controller: passwordController,
            decoration: InputDecoration(hintText: "Contraseña"),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: funClickLogin, child: Text("Login")),
              TextButton(
                onPressed: funClickRegistro,
                child: Text("Registrarse"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
