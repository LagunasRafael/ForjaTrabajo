import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart'; // 👈 Asegúrate de importar tu Login

// 👇 TUS LAYOUTS
import 'features/services/presentation/screens/layout/client_main_layout.dart';
import 'features/services/presentation/screens/layout/worker_main_layout.dart';
import 'features/services/presentation/screens/layout/admin_main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // Pantalla inicial
      home: const RoleSelectionScreen(),

      // 👇 RUTAS REGISTRADAS
      routes: {
        '/login':       (context) => const LoginScreen(),         // 👈 RUTA CLAVE PARA CERRAR SESIÓN
        '/roles':       (context) => const RoleSelectionScreen(),
        '/client_home': (context) => const ClientMainLayout(),
        '/worker_home': (context) => const WorkerMainLayout(),
        '/admin_home': (context) => AdminMainLayout(), // ✅ ASÍ ESTÁ BIEN
      },
    );
  }
}