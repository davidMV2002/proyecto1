import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../insLib/google_sign_in_button.dart';

class Loginview extends StatefulWidget {
  const Loginview({super.key});

  @override
  State<Loginview> createState() => _LoginviewState();
}

class _LoginviewState extends State<Loginview> {
  final userController = TextEditingController();
  final passwordController = TextEditingController();
  bool _loading = false;
  static bool _googleInitialized = false;

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login({bool google = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final auth = FirebaseAuth.instance;
      if (google) {
        if (kIsWeb) {
          await auth.signInWithPopup(GoogleAuthProvider());
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          if (!_googleInitialized) {
            await GoogleSignIn.instance.initialize();
            _googleInitialized = true;
          }
          final account = await GoogleSignIn.instance.authenticate();
          final token = account.authentication.idToken;
          if (token == null) throw FirebaseAuthException(code: 'missing-token');
          await auth.signInWithCredential(
            GoogleAuthProvider.credential(idToken: token),
          );
        } else {
          throw FirebaseAuthException(code: 'unsupported-platform');
        }
      } else {
        await auth.signInWithEmailAndPassword(
          email: userController.text.trim(),
          password: passwordController.text,
        );
      }
      if (google) {
        final user = auth.currentUser!;
        final firestore = FirebaseFirestore.instance;
        final ref = firestore.collection('Perfiles').doc(user.uid);
        await firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            transaction.set(ref, {
              'Nombre': user.displayName ?? '',
              'deslizablesVistos': false,
            });
          }
        });
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/SplashView');
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      _showError(
        e.code == GoogleSignInExceptionCode.canceled
            ? 'Has cancelado el acceso con Google.'
            : 'No se pudo acceder con Google. Comprueba la configuración e inténtalo de nuevo.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'popup-closed-by-user' ||
        'cancelled-popup-request' => 'Has cancelado el acceso con Google.',
        'account-exists-with-different-credential' =>
          'Ya existe una cuenta con este correo y otro método de acceso.',
        'network-request-failed' =>
          'Comprueba tu conexión a internet e inténtalo de nuevo.',
        'unsupported-platform' =>
          'El acceso con Google está disponible en Android y navegador.',
        _ => 'No se pudo iniciar sesión. Comprueba tus datos o la configuración e inténtalo de nuevo.',
      };
      _showError(message);
    } catch (_) {
      if (mounted) _showError('No se pudo iniciar sesión. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MI APP DAM2627')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Iniciar sesión',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: userController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : () => _login(),
                  child: const Text('Entrar'),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.pushReplacementNamed(
                          context,
                          '/RegistroView',
                        ),
                  child: const Text('Registrarse'),
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  onPressed: _loading ? null : () => _login(google: true),
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
