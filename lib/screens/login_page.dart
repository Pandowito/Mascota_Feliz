import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRegistering = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegistering) {
        // 1. Registrar usuario en Firebase Auth
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Guardar datos adicionales en Realtime Database
        final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${userCredential.user!.uid}');
        await userRef.set({
          'email': _emailController.text.trim(),
          'createdAt': ServerValue.timestamp, // Timestamp de Firebase
          'devices': {}, // Para vincular comederos después
          'pets': {}, // Para mascotas futuras
        });

        // Opcional: Enviar verificación por email
        await userCredential.user!.sendEmailVerification();
      } else {
        // Iniciar sesión
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      // Navegar al Home (reemplaza con tu pantalla)
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _translateAuthError(e.code));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'El correo ya está registrado.';
      case 'invalid-email':
        return 'Correo no válido.';
      case 'weak-password':
        return 'Contraseña débil (mínimo 6 caracteres).';
      case 'user-not-found':
        return 'Usuario no encontrado.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      default:
        return 'Error desconocido. Intenta nuevamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegistering ? "Registro" : "Iniciar sesión")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Ingresa un correo válido'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (value) => value!.length < 6
                    ? 'Mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_isRegistering ? "Registrarse" : "Iniciar sesión"),
              ),
              TextButton(
                onPressed: () => setState(() => _isRegistering = !_isRegistering),
                child: Text(
                  _isRegistering
                      ? "¿Ya tienes cuenta? Inicia sesión"
                      : "¿No tienes cuenta? Regístrate",
                  style: const TextStyle(color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}