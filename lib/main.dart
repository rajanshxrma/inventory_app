import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/inventory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory Manager',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0D7377),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F3),
      ),
      home: const InventoryScreen(),
    );
  }
}
