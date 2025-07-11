import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // inicializa Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Comedero IoT',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('estado');

  String nombre = "";
  String nivelAgua = "";
  String ultimaDisp = "";

  @override
  void initState() {
    super.initState();
    _ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map;
      setState(() {
        nombre = data['nombre'] ?? "Sin nombre";
        nivelAgua = data['nivel_agua'] ?? "Desconocido";
        ultimaDisp = data['ultima_disp'] ?? "Nunca";
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mascota Feliz')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🐶 Nombre: $nombre', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('💧 Nivel de agua: $nivelAgua', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('📅 Última dispensación: $ultimaDisp', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
