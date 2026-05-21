import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/payment_history_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/contracts_screen.dart';
import 'package:forja_trabajo/features/payments/presentation/screens/invoices_screen.dart';
import 'injection_container.dart' as di;
import 'package:firebase_core/firebase_core.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/network/notification_service.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

import 'features/services/presentation/screens/layout/client_main_layout.dart';
import 'features/services/presentation/screens/layout/worker_main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Stripe con la clave pública
  Stripe.publishableKey = 'pk_test_51TYWIIE3IouDCLunLGxz0gBIg4cOga8dhqaxRdzogAStieRclSPx82y0FFFdYWAIcCIaMZ3snWQ4yZEy3xIceJOK00G7voWt0u';
  
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
      theme: AppTheme.theme, 
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: navigatorKey,

      home: const SplashScreen(),

      routes: {
        '/login':       (context) => const LoginScreen(),
        '/roles':       (context) => const RoleSelectionScreen(),
        '/client_home': (context) => const ClientMainLayout(),
        '/worker_home': (context) => const WorkerMainLayout(),
        '/client/contracts': (context) => const ContractsScreen(),
        '/client/payment_history': (context) => const PaymentHistoryScreen(),
        '/client/invoices': (context) => const InvoicesScreen(),
      },
    );
  }
}
