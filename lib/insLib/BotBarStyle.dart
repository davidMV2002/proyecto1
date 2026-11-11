import 'package:flutter/material.dart';

class Botbarstyle extends StatelessWidget {
  const Botbarstyle({super.key, required this.iBarIndex});
  final int iBarIndex;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: iBarIndex,
    indicatorColor: Colors.redAccent,
    onDestinationSelected: (index) {
      if (index == iBarIndex) return;
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/HomeView');
        case 1:
          Navigator.pushReplacementNamed(context, '/MapaView');
        case 2:
          Navigator.pushReplacementNamed(context, '/CapitalesView');
        case 3:
          Navigator.pushReplacementNamed(context, '/PerfilView');
      }
    },
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home), label: 'Principal'),
      NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
      NavigationDestination(
        icon: Icon(Icons.location_city_outlined),
        label: 'Capitales',
      ),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
    ],
  );
}
