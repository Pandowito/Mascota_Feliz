import 'package:flutter/material.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mascotas'),
      ),
      body: const Center(
        child: Text('Pantalla de Mascotas (en desarrollo)'),
      ),
    );
  }
}

