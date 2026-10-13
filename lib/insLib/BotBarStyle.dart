import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Botbarstyle extends StatefulWidget{
  int iBarIndex = 0;

  Botbarstyle({required this.iBarIndex});

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
    setState(() {
      widget.iBarIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    miContext=context;

    return NavigationBar(
      onDestinationSelected: seleccionNavegador,
      indicatorColor: Colors.redAccent,
      selectedIndex: widget.iBarIndex,
      destinations: [
        NavigationDestination(icon: Icon(Icons.home), label: 'Principal'),
        NavigationDestination(icon: Icon(Icons.notifications_sharp), label: 'Notificaciones'),
        NavigationDestination(icon: Icon(Icons.messenger_sharp), label: 'Mensajes')
      ],
    );
  }
}