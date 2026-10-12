import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Botbarstyle extends StatefulWidget{

  @override
  State<Botbarstyle> createState() => _BotbarstyleState();
}

class _BotbarstyleState extends State<Botbarstyle>{
  late BuildContext miContext;

  @override
  void initState() {

    super.initState();
  }

  void seleccionNavegador(int index){
    switch(index){
      case 0: {
        Navigator.popAndPushNamed(context, "/HomeView");
      }

      case 1:{
        print("PROXIMAMENTE");
      }

      case 2:{
        Navigator.popAndPushNamed(context, "/XXX");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    miContext=context;

    return NavigationBar(
      onDestinationSelected: seleccionNavegador,
    );
  }
}