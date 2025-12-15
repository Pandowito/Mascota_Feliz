import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'pets_screen.dart';
import 'login_page.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? _user = FirebaseAuth.instance.currentUser; // Usuario actual

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Comedero Inteligente'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.monitor), text: 'Monitoreo'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Salud'),
            Tab(icon: Icon(Icons.person), text: 'Cuenta'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonitoringTab(),  // Pestaña 1
          _buildHealthTab(),       // Pestaña 2
          _buildAccountTab(),      // Pestaña 3
        ],
      ),
    );
  }

  // ------------------------ Pestaña de MONITOREO ------------------------
  Widget _buildMonitoringTab() {
    final DatabaseReference deviceRef = FirebaseDatabase.instance.ref('devices/esp32_comedero_1');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // StreamBuilder para los paneles de nivel
          StreamBuilder<DatabaseEvent>(
            stream: deviceRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Column(
                  children: [
                    _buildStatusPanel(
                      icon: Icons.food_bank,
                      title: 'Nivel de Alimento',
                      value: '--%',
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    _buildStatusPanel(
                      icon: Icons.water_drop,
                      title: 'Nivel de Agua',
                      value: '--%',
                      color: Colors.grey,
                    ),
                  ],
                );
              }

              final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
              final foodLevel = (data['foodLevel'] as num?)?.toInt() ?? 0;
              final waterLevel = (data['waterLevel'] as num?)?.toInt() ?? 0;

              return Column(
                children: [
                  _buildStatusPanel(
                    icon: Icons.food_bank,
                    title: 'Nivel de Alimento',
                    value: '$foodLevel%',
                    color: _getLevelColor(foodLevel),
                  ),
                  const SizedBox(height: 20),
                  _buildStatusPanel(
                    icon: Icons.water_drop,
                    title: 'Nivel de Agua',
                    value: '$waterLevel%',
                    color: _getLevelColor(waterLevel),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Panel de Horarios
          _buildSchedulePanel(),

          const SizedBox(height: 20),

          // Botón de Dispensación Manual
          ElevatedButton.icon(
            onPressed: () => _dispenseFoodNow(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Dispensar Ahora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level < 20) return Colors.red;
    if (level < 50) return Colors.orange;
    return Colors.green;
  }



  // ------------------------ Pestaña de SALUD ------------------------
  Widget _buildHealthTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Datos de tu Mascota', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          // Ejemplo de tarjeta de salud (personalizable)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://placekitten.com/200/200'),
                  ),
                  const SizedBox(height: 10),
                  Text('Nombre: Whiskers', style: Theme.of(context).textTheme.titleMedium),
                  Text('Edad: Adulto', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Consumo diario: 150g', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ------------------------ Pestaña de CUENTA ------------------------
  Widget _buildAccountTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: const Icon(Icons.email),
          title: Text('Correo: ${_user?.email ?? 'No disponible'}'),
        ),
        ListTile(
          leading: const Icon(Icons.pets),
          title: const Text('Mis Mascotas'),
          onTap: () => _navigateToPetsScreen(),
        ),
        ListTile(
          leading: const Icon(Icons.device_hub),
          title: const Text('Vincular Comedero'),
          onTap: () => _linkNewDevice(),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notificaciones'),
          onTap: () => _navigateToNotifications(),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          onTap: () => _signOut(context), // Método modificado
        ),
      ],
    );
  }

  // ------------------------ Componentes Reutilizables ------------------------
  Widget _buildStatusPanel({required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18)),
                Text(value, style: TextStyle(fontSize: 24, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSchedulePanel() {
    final DatabaseReference scheduleRef = FirebaseDatabase.instance.ref('devices/esp32_comedero_1/schedule');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Horarios de Dispensación', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            StreamBuilder<DatabaseEvent>(
              stream: scheduleRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final schedules = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
                final scheduleList = schedules.entries.toList();

                return Column(
                  children: [
                    ...scheduleList.map((entry) => ListTile(
                      title: Text('${entry.key}'),
                      subtitle: Text('${entry.value}g'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeSchedule(scheduleRef, entry.key.toString()),
                      ),
                    )),
                    TextButton(
                      onPressed: () => _showAddScheduleDialog(scheduleRef),
                      child: const Text('+ Añadir horario'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------ Funciones ------------------------

  // --------Pestaña de MONITOREO


  //Dispensar Alimento en tiempo real
  void _dispenseFoodNow() {
    final amountController = TextEditingController(text: '50'); // Valor por defecto
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Permite actualizar el estado dentro del diálogo
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Dispensar comida'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad (gramos)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                if (_isLoading) const CircularProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isEmpty) return;

                  setState(() => _isLoading = true);

                  // Lógica para dispensar
                  await _sendDispenseCommand(int.parse(amountController.text));

                  setState(() => _isLoading = false);
                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Dispensado ${amountController.text}g')),
                  );
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendDispenseCommand(int grams) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('devices/esp32_comedero_1/actions');

    await ref.set({
      'type': 'manual_dispense',
      'amount': grams,
      'timestamp': ServerValue.timestamp,
    });
  }

  // PESTAÑA HORARIOS DE DISPENSACION
  void _showAddScheduleDialog(DatabaseReference ref) {
    final amountController = TextEditingController(text: '150');
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo horario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Hora'),
              subtitle: Text(
                selectedTime.format(context),
                style: const TextStyle(fontSize: 18),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (pickedTime != null) {
                    selectedTime = pickedTime;
                    (context as Element).markNeedsBuild(); // Actualiza el diálogo
                  }
                },
              ),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Cantidad (g)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveSchedule(
                ref,
                selectedTime, // Envía el TimeOfDay directamente
                amountController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSchedule(DatabaseReference ref, TimeOfDay time, String amount) async {
    final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'; // Formato 24h
    await ref.child(formattedTime).set(int.tryParse(amount) ?? 150);
  }

  Future<void> _removeSchedule(DatabaseReference ref, String time) async {
    await ref.child(time).remove();
  }

  // --------Pestaña de SALUD



  // --------Pestaña de CUENTA
  //Navegacion de pestañas en cuenta
  void _navigateToPetsScreen() {
    // Navegar a pantalla de mascotas (implementar después)
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PetsScreen()));
  }

  void _linkNewDevice() {
    // Lógica para vincular nuevo comedero
  }

  void _navigateToNotifications() {
    // Navegar a configuración de notificaciones
  }

  // Método para cerrar sesión
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navegar a LoginPage y eliminar el historial de navegación
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
      );
    }
  }
}

