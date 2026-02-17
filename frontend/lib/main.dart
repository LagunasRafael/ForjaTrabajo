import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importamos tu tema y tu nueva pantalla
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';

void main() {
  // Garantiza que los motores internos de Flutter estén listos 
  // (Súper importante si después agregas Firebase, S3 o bases locales)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // 🧠 ENVUELTA MÁGICA DE RIVERPOD: 
    // Esto permite que cualquier pantalla pueda usar "ref.watch" o "ref.read"
    const ProviderScope(
      child: ForjaTrabajoApp(),
    ),
  );
}

class ForjaTrabajoApp extends StatelessWidget {
  const ForjaTrabajoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forja Trabajo',
      // Quitamos la cintilla roja molesta de "DEBUG" en la esquina
      debugShowCheckedModeBanner: false, 
      // Inyectamos la paleta de colores que definiste en app_theme.dart
      theme: AppTheme.theme, 
      // Mandamos al usuario directo a la pantalla que acabas de crear
      home: const RoleSelectionScreen(), 
    );
  }
}