import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/network/notification_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';

import 'features/auth/presentation/screens/splash_screen.dart'; // 👈 Importamos el SplashScreen

// 👇 TUS LAYOUTS
import 'features/services/presentation/screens/layout/client_main_layout.dart';
import 'features/services/presentation/screens/layout/worker_main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Configurar timeago para español
  timeago.setLocaleMessages('es', timeago.EsMessages());

  // Manejar notificación si la app fue abierta desde estado terminado
  NotificationService().handleInitialMessage();

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
      navigatorKey: navigatorKey, // 🔑 Clave para navegación desde notificaciones

      // Pantalla inicial
      home: const SplashScreen(),

      // 👇 RUTAS REGISTRADAS
      routes: {
        '/login': (context) => const LoginScreen(),
        '/client_home': (context) => const ClientMainLayout(),
        '/worker_home': (context) => const WorkerMainLayout(),
      },
    );
  }
}
