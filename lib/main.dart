import 'package:flutter/material.dart';
import 'screens/bienvenida_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/servidor_perfil.dart';
import 'screens/trabajos.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

 @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Forja Trabajo',
      initialRoute: '/',
      routes: {
        '/': (context) => const BienvenidaScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterPage(), // opcional dos
        '/homescreen': (context) => const HomeScreen(),
         '/servidor_perf': (context) => const ServidorPerfil(),
         '/trabajos': (context) => Trabajos(),
      },
    );
  }
}
