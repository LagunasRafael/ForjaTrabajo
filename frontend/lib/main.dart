import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/payment_history_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/contracts_screen.dart';
import 'injection_container.dart' as di;
import 'package:firebase_core/firebase_core.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/network/notification_service.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

import 'features/auth/presentation/screens/splash_screen.dart'; // 👈 Importamos el SplashScreen

// 👇 TUS LAYOUTS
import 'features/services/presentation/screens/layout/client_main_layout.dart';
import 'features/services/presentation/screens/layout/worker_main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Stripe con la clave pública
  Stripe.publishableKey = 'pk_test_51TJMelEEBDNiDvB2T001jsfxYvutidQ8BQqrJCQutevL29fBc1IDFdo2Yfvdmf8H0UHWKw8y98kl9ABuFYRMLneC00e16IS4Qy';
  
  // Inicializar servicios de inyección de dependencias
  await di.init(); 
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
      debugShowCheckedModeBanner: false,
      title: 'Forja Trabajo',
      // Usamos el tema global del proyecto
      theme: AppTheme.theme, 
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: navigatorKey, // 🔑 Clave para navegación desde notificaciones

      // Pantalla inicial
      home: const SplashScreen(),

      // Registro de rutas para navegar entre módulos
      routes: {
        '/login':       (context) => const LoginScreen(),
        '/roles':       (context) => const RoleSelectionScreen(),
        '/client_home': (context) => const ClientMainLayout(),
        '/worker_home': (context) => const WorkerMainLayout(),
        '/client/contracts': (context) => const ContractsScreen(),
        '/client/payment_history': (context) => const PaymentHistoryScreen(),
      },
    );
  }
}
