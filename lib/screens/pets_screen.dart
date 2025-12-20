import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_pet_screen.dart'; // Asegúrate de crear este archivo después

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    // Referencia a la base de datos: nodo 'pets' ordenado por dueño
    final Query petsQuery = FirebaseDatabase.instance
        .ref('pets')
        .orderByChild('owner')
        .equalTo(user?.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mascotas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. EL BOTÓN HORIZONTAL PARA AGREGAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPetScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.teal, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle, color: Colors.teal, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Agregar Nueva Mascota',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. LISTA DE MASCOTAS EXISTENTES
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: petsQuery.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return _buildEmptyState();
                }

                // Convertir el JSON de Firebase a una lista manejable
                Map<dynamic, dynamic> petsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                var petsList = petsMap.entries.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: petsList.length,
                  itemBuilder: (context, index) {
                    final petData = petsList[index].value;
                    final petKey = petsList[index].key;

                    return _buildPetCard(context, petData, petKey);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de diseño para cada mascota
  Widget _buildPetCard(BuildContext context, Map petData, String petKey) {
    bool isDog = petData['type'] == 'perro';

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: isDog ? Colors.blue.shade100 : Colors.orange.shade100,
          child: Icon(
            isDog ? Icons.pets : Icons.cruelty_free,
            color: isDog ? Colors.blue : Colors.orange,
            size: 30,
          ),
        ),
        title: Text(
          petData['name'] ?? 'Sin Nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text('${petData['breed'] ?? 'Mestizo'} • ${petData['ageGroup']}'),
            Text('Comida sugerida: ${petData['dailyFoodTarget']}g/día',
                style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            // Eliminar mascota
            FirebaseDatabase.instance.ref('pets/$petKey').remove();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.pets, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'No tienes mascotas registradas',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}