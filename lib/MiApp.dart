import 'package:flutter/material.dart';
import 'package:proyecto1/views/LoginView.dart';
import 'package:proyecto1/views/OnBoardingView.dart';
import 'package:proyecto1/views/RegistroView.dart';

class Miapp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {

    return new MaterialApp(
      title: "PRIMER PROYECTO",
      routes: {
        "/OnBoardingView":(context) => Onboardingview(),
        "/LoginView":(context) => Loginview(),
        "/RegistroView":(context) => Registroview(),

      },
      initialRoute: "/OnBoardingView",
    );
  }
}