import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Variables de Estado
  String _selectedType = 'perro'; // perro, gato
  String _selectedAgeGroup = 'adulto'; // cachorro, adulto, senior
  String _selectedSize = 'mediano'; // pequeño, mediano, grande
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Mascota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. NOMBRE
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la mascota', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 20),

              // 2. TIPO (Perro / Gato)
              const Text('Tipo de Animal', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text('Perro 🐶'),
                      value: 'perro',
                      groupValue: _selectedType,
                      onChanged: (val) => setState(() => _selectedType = val.toString()),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text('Gato 🐱'),
                      value: 'gato',
                      groupValue: _selectedType,
                      onChanged: (val) => setState(() => _selectedType = val.toString()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. EDAD Y TAMAÑO
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAgeGroup,
                      decoration: const InputDecoration(labelText: 'Etapa', border: OutlineInputBorder()),
                      items: ['cachorro', 'adulto', 'senior'].map((String val) {
                        return DropdownMenuItem(value: val, child: Text(val.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAgeGroup = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSize,
                      decoration: const InputDecoration(labelText: 'Tamaño', border: OutlineInputBorder()),
                      items: ['pequeño', 'mediano', 'grande'].map((String val) {
                        return DropdownMenuItem(value: val, child: Text(val.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSize = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. PESO Y RAZA
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peso (KG)', border: OutlineInputBorder(), suffixText: 'kg'),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(labelText: 'Raza (Opcional)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 5. BOTÓN GUARDAR
              ElevatedButton(
                onPressed: _isLoading ? null : _savePet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Mascota', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LÓGICA DE NEGOCIO Y GUARDADO ---

  void _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No hay usuario logueado");

      final double peso = double.tryParse(_weightController.text) ?? 5.0;

      // --- AQUÍ ESTÁ LA MAGIA: CÁLCULO AUTOMÁTICO ---
      final int racionComida = _calcularComida(peso, _selectedType, _selectedAgeGroup);
      final int metaAgua = _calcularAgua(peso, _selectedType);

      // Crear objeto para Firebase
      final newPetData = {
        'owner': user.uid,
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'ageGroup': _selectedAgeGroup,
        'size': _selectedSize,
        'weight': peso,
        'breed': _breedController.text.trim(),
        'dailyFoodTarget': racionComida, // Gramos calculados
        'dailyWaterTarget': metaAgua,   // ML calculados
        'linkedDevice': '', // Aún no vinculado
        'createdAt': ServerValue.timestamp,
      };

      // Guardar en 'pets' generando un ID único (.push())
      await FirebaseDatabase.instance.ref('pets').push().set(newPetData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡${_nameController.text} agregado! Comida sugerida: ${racionComida}g')),
        );
        Navigator.pop(context); // Volver a la lista
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lógica de cálculo (Basada en tu investigación)
  int _calcularComida(double peso, String tipo, String edad) {
    double porcentaje = 0.025; // Estándar 2.5%

    if (tipo == 'perro') {
      if (edad == 'cachorro') porcentaje = 0.05; // 5%
      if (edad == 'senior') porcentaje = 0.02;   // 2%
    } else {
      // Gatos
      if (edad == 'cachorro') porcentaje = 0.04; // 4%
    }

    // Peso (kg) * 1000 = gramos * porcentaje
    return (peso * 1000 * porcentaje).toInt();
  }

  int _calcularAgua(double peso, String tipo) {
    int mlPorKg = (tipo == 'perro') ? 50 : 60;
    return (peso * mlPorKg).toInt();
  }
}