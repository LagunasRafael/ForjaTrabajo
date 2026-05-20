import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import '../../providers/service_offers_provider.dart';
import '../../providers/service_list_provider.dart';
import '../../providers/nav_providers.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/candidate_card.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';

class OffersReceivedScreen extends ConsumerWidget {
  final ServiceEntity? service;
  final String? serviceId;

  const OffersReceivedScreen({super.key, this.service, this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveId = service?.id ?? serviceId;
    if (effectiveId == null) return const Scaffold(body: Center(child: Text("Error: ID faltante")));

    // 🔔 Escuchar eventos de notificación para refrescar en tiempo real
    ref.listen<AsyncValue<RemoteMessage>>(notificationEventProvider, (previous, next) {
      next.whenData((message) {
        final type = message.data['type'] ?? '';
        if (type == 'new_application' || type == 'offer_responded' || type.toString().contains('job_')) {
          debugPrint('🔄 [OffersReceivedScreen] Refrescando por notificación: $type');
          ref.invalidate(offersListProvider(effectiveId));
          ref.invalidate(serviceDetailProvider(effectiveId));
        }
      });
    });

    final serviceAsync = service != null 
        ? AsyncValue.data(service!) 
        : ref.watch(serviceDetailProvider(effectiveId));
    
    final offersAsync = ref.watch(offersListProvider(effectiveId));
    
    return serviceAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text("Error cargando servicio: $e"))),
      data: (serviceData) {
        final theme = Theme.of(context);
        final status = serviceData.status.toString().toLowerCase();
        if (!status.contains('open')) {
          // El servicio ya no acepta postulaciones. Redirigir a "Mis Trabajos".
          Future.microtask(() {
            if (context.mounted) {
              // 1. Establecer la pestaña principal (Mis Trabajos = Índice 3)
              ref.read(clientNavProvider.notifier).state = 3;
              
              // 2. Establecer la sub-pestaña (En Proceso = 1, Finalizados = 2)
              final subTabIndex = (status.contains('completed') || status.contains('cancelled')) ? 2 : 1;
              ref.read(myRequestsTabProvider.notifier).state = subTabIndex;

              // 3. Navegar a la Home para que el Layout cargue los providers actualizados
              Navigator.pushNamedAndRemoveUntil(context, '/client_home', (route) => false);
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))));
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface, 
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20), 
              onPressed: () => Navigator.pop(context)
            ),
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Postulaciones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.colorScheme.onSurface)),
              Text(serviceData.title.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
            ]),
          ),
          body: RefreshIndicator(
            onRefresh: () async => ref.invalidate(offersListProvider(effectiveId)),
          child: offersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
            error: (e, s) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
            data: (offers) {
              if (offers == null || offers.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text("Aún no hay postulaciones", style: TextStyle(color: Colors.grey))),
                  ],
                );
              }
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                itemBuilder: (context, index) => CandidateCard(
                  offer: offers[index], 
                  serviceId: effectiveId,
                  serviceTitle: serviceData.title,
                ),
              );
            },
          ),
          ),
        );
      },
    );
  }
}