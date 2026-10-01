import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Registroview extends StatelessWidget{
  late BuildContext miContext;
  TextEditingController userController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  TextEditingController repasswordController = new TextEditingController();

  void funClickCancelar(){
    Navigator.popAndPushNamed(miContext, "/RegisterView");
  }

  void funClickAceptar(){

  }

  @override
  Widget build(BuildContext context) {
    miContext=context;

    return Scaffold(
      body: Column(
        mainAxisAlignment:MainAxisAlignment.start,
        children: [
          Text("REGISTRO",style: TextStyle(fontSize: 30,backgroundColor:Colors.red),),
          TextField(controller: userController,decoration: InputDecoration(hintText: "Usuario"),),
          TextField(obscureText: true,controller:passwordController,decoration: InputDecoration(hintText: "Contraseña"),),
          TextField(obscureText: true,controller:repasswordController,decoration: InputDecoration(hintText: "Repite la Contraseña"),),
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