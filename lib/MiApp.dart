import 'package:flutter/material.dart';
import 'package:proyecto1/views/OnBoardingView.dart';

class Miapp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {

    return new MaterialApp(
      title: "PRIMER PROYECTO",
      routes: {
        "/OnBoardingView":(context) => Onboardingview(),
      },
      initialRoute: "/OnBoardingView",
    );
  }
}