import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Registroview extends StatelessWidget {
  var faInstance = FirebaseAuth.instance;
  late BuildContext miContext;
  TextEditingController userController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  TextEditingController repasswordController = new TextEditingController();

  void funClickCancelar() async {
    Navigator.popAndPushNamed(miContext, "/LoginView");
  }

  Future<void> funClickAceptar() async {
    if (repasswordController.text != passwordController.text) {
      print("LAS CONTRASEÑAS NO COINCIDEN");
    } else {
      try {
        final credencial = await faInstance.createUserWithEmailAndPassword(
          email: userController.text,
          password: passwordController.text,
        );

        if (credencial.user != null && miContext.mounted) {
          Navigator.popAndPushNamed(miContext, "/SplashView");
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          print('The account already exists for that email.');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    miContext = context;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "REGISTRO",
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
          TextField(
            obscureText: true,
            controller: repasswordController,
            decoration: InputDecoration(hintText: "Repite la Contraseña"),
          ),
          Row(
            children: [
              TextButton(onPressed: funClickAceptar, child: Text("Aceptar")),
              TextButton(onPressed: funClickCancelar, child: Text("Cancelar")),
            ],
          ),
        ],
      ),
    );
  }
}
