import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart'; // 👈 Asegúrate de importar tu Login

// 👇 TUS LAYOUTS
import 'features/services/presentation/screens/layout/client_main_layout.dart';
import 'features/services/presentation/screens/layout/worker_main_layout.dart';
import 'features/services/presentation/screens/layout/admin_main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: ForjaTrabajoApp(),
    ),
  );
}

class ForjaTrabajoApp extends ConsumerWidget {
  const ForjaTrabajoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Forja Trabajo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Pantalla inicial
      home: const RoleSelectionScreen(),

      // 👇 RUTAS REGISTRADAS
      routes: {
        '/login': (context) =>
            const LoginScreen(), // 👈 RUTA CLAVE PARA CERRAR SESIÓN
        '/roles': (context) => const RoleSelectionScreen(),
        '/client_home': (context) => const ClientMainLayout(),
        '/worker_home': (context) => const WorkerMainLayout(),
        '/admin_home': (context) => AdminMainLayout(), // ✅ ASÍ ESTÁ BIEN
      },
    );
  }
}
