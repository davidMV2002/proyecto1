import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../DataHolder.dart';
import '../FbObjects/Perfil.dart';

/// Decisión compartida por el splash y la continuación tras autenticarse.
class EntradaApp {
  static String rutaPara({required bool haySesion, Perfil? perfil}) {
    if (!haySesion) return '/LoginView';
    if (perfil == null) return '/CreatePerfilView';
    return perfil.deslizablesVistos ? '/HomeView' : '/OnBoardingView';
  }

  static Future<String> destino() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return rutaPara(haySesion: false);
    final snapshot = await FirebaseFirestore.instance
        .collection('Perfiles')
        .doc(user.uid)
        .withConverter<Perfil>(
          fromFirestore: Perfil.fromFirestore,
          toFirestore: (perfil, _) => perfil.toFirestore(),
        )
        .get();
    final perfil = snapshot.data();
    if (perfil != null) Dataholder.instance.perfilUsuario = perfil;
    return rutaPara(haySesion: true, perfil: perfil);
  }

  static Future<void> completarOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Se necesita una sesión activa');
    // update falla si no existe el perfil: nunca crea un perfil incompleto.
    await FirebaseFirestore.instance
        .collection('Perfiles')
        .doc(user.uid)
        .update({'deslizablesVistos': true});
    // Refrescar el perfil cuando el splash vuelva a decidir la entrada.
  }
}
