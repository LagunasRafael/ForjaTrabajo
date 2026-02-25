import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports de tu lógica de pagos y contenedor de dependencias
import 'package:forja_trabajo/features/payments/presentation/screens/home_screen.dart';
import 'injection_container.dart' as di;

// Imports de la lógica de Rafa y Luis (Auth y Layouts)
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/services/presentation/screens/layout/client_main_layout.dart';
import 'features/services/presentation/screens/layout/worker_main_layout.dart';
import 'features/services/presentation/screens/layout/admin_main_layout.dart';

void main() async {
  // Aseguramos la comunicación con el motor de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mantenemos tu inicialización para que funcionen tus servicios de pagos
  await di.init(); 

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
      debugShowCheckedModeBanner: false,
      title: 'Forja Trabajo',
      // Usamos el tema global del proyecto
      theme: AppTheme.theme, 

      // Iniciamos con la selección de roles para obtener el Token y evitar el error 401
      home: const RoleSelectionScreen(),

      // Registro de rutas para navegar entre módulos
      routes: {
        '/login':       (context) => const LoginScreen(),
        '/roles':       (context) => const RoleSelectionScreen(),
        '/client_home': (context) => const ClientMainLayout(),
        '/worker_home': (context) => const WorkerMainLayout(),
        '/admin_home':  (context) => const AdminMainLayout(),
        // Agregamos tu ruta de pagos por si la necesitas llamar después
        '/payments':    (context) => const HomeScreen(), 
      },
    );
  }
}