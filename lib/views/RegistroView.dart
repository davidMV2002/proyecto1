import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Registroview extends StatelessWidget{
  TextEditingController userController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();

  void funClickCancelar(){

  }

  void funClickAceptar(){

  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: userController,decoration: InputDecoration(hintText: "Usuario"),),
          TextField(obscureText: true,controller:passwordController,decoration: InputDecoration(hintText: "Contraseña"),),
          Row(
            children: [
              TextButton(onPressed: funClickAceptar, child: Text("Aceptar")),
              TextButton(onPressed: funClickCancelar, child: Text("Cancelar"))
            ],
          )
        ],
      ),
    );
  }
}