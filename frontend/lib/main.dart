import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/services/presentation/screens/home_services_screen.dart';

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

      // 👇 Pantalla inicial oficial (flujo correcto)
      home: const RoleSelectionScreen(),

      // 👇 Aquí registramos rutas
      routes: {
        '/services': (context) => const HomeServicesScreen(),
      },
    );
  }
}
