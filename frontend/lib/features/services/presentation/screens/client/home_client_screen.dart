import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/header_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/category_selector_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_list_widget.dart'; 
import 'package:forja_trabajo/features/services/presentation/widgets/search_bar_widget.dart'; 
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/shared/widgets/location/location_radius_bar.dart';

class HomeClientScreen extends ConsumerWidget {
  const HomeClientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔔 Escuchar eventos de notificación para refrescar el marketplace en tiempo real
    ref.listen<AsyncValue<RemoteMessage>>(notificationEventProvider, (previous, next) {
      next.whenData((message) {
        final type = message.data['type'] ?? '';
        // Si llega una señal de nuevo servicio o actualización general, refrescamos
        if (type == 'new_service' || type == 'marketplace_refresh') {
          debugPrint('🔄 [HomeClientScreen] Refrescando marketplace...');
          ref.invalidate(serviceListProvider);
        }
      });
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Column( 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const  HeaderWidget(),
                  const  SizedBox(height: 10),
                  const  SearchBarWidget(), 
                  const  SizedBox(height: 10),
                  const  LocationRadiusBar(),
                  const  SizedBox(height: 10),
                  const  CategorySelectorWidget(),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF10B981),
                backgroundColor: Colors.white,
                onRefresh: () async {
                  ref.invalidate(serviceListProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: const ServiceListWidget(), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}