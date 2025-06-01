import 'package:flutter/material.dart';
import 'screens/mensajes.dart';
import 'screens/perfil_cliente.dart';
import 'screens/register_Screen.dart';
import 'screens/bienvenida_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/servidor_perfil.dart';
import 'screens/trabajos.dart';
import 'screens/home_quest_screen.dart';

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
        '/register': (context) => const RegisterPage(), 
        '/homescreen': (context) => const HomeScreen(),
        '/servidor_perf': (context) => const ServidorPerfil(),
         '/cleinte_perf': (context) => const PerfilCliente(),
         '/trabajos': (context) => Trabajos(),
         '/mensajes':(context) => Mensajes(),
         '/quest': (context) =>  ProfileIntroPage(),
      },
    );
  }
}