import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Asegúrate de que esta ruta sea la correcta según tus carpetas
import 'package:forja_trabajo/features/services/presentation/screens/home_services_screen.dart';

void main() {
  runApp(
    // El ProviderScope es OBLIGATORIO para que Riverpod funcione
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Forja Trabajo',
      theme: ThemeData(
        useMaterial3: true,
        // Configuramos el color índigo como color primario de la app
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      ),
      home: const HomeServicesScreen(),
    );
  }
}