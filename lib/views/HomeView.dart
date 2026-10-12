import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Homeview extends StatelessWidget{

  void cerrarSesion(){

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body:
        Column(
          children: [
            TextButton(onPressed: cerrarSesion, child: Text("Cerrar sesión"))
          ],
        )
    );
  }
}