import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';

// Providers
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';

// IMPORTS DE LAS TARJETAS
import 'package:forja_trabajo/features/services/presentation/widgets/client/client_open_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/client_matched_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/client_completed_job_card.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const MyRequestsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Prioridad: 1. Índice que viene por constructor (notificaciones) 2. Índice del provider (navegación interna)
    final index = widget.initialIndex != 0 ? widget.initialIndex : ref.read(myRequestsTabProvider);
    _tabController = TabController(length: 3, vsync: this, initialIndex: index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔔 Escuchar eventos de notificación para refrescar la lista en tiempo real
    ref.listen<AsyncValue<RemoteMessage>>(notificationEventProvider, (previous, next) {
      next.whenData((message) {
        final type = message.data['type'] ?? '';
        if (type.toString().contains('job_') || 
            type == 'in_progress' || 
            type == 'new_application' || 
            type == 'offer_responded' || 
            type == 'new_offer') {
          debugPrint('🔄 [MyRequestsScreen] Refrescando por notificación: $type');
          ref.invalidate(myRequestsProvider);
          ref.invalidate(workerJobsProvider);
        }
      });
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mis Trabajos',
            style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Abiertos'),
            Tab(text: 'En Proceso'),
            Tab(text: 'Finalizados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), 
        children: [
          _buildRequestList(ref, JobStatus.open),
          _buildRequestList(ref, JobStatus.matched),
          _buildRequestList(ref, JobStatus.completed),
        ],
      ),
    );
  }

  Widget _buildRequestList(WidgetRef ref, JobStatus status) {
    final servicesAsync = ref.watch(myRequestsProvider);

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async {
        await ref.refresh(myRequestsProvider.future);
      },
      child: servicesAsync.when(
        data: (services) {
          final filtered = services.where((s) {
            if (status == JobStatus.matched) {
              return s.status == JobStatus.matched || s.status == JobStatus.waiting_confirmation;
            }
            if (status == JobStatus.completed) {
              return s.status == JobStatus.completed || s.status == JobStatus.cancelled;
            }
            return s.status == status;
          }).toList();

          if (filtered.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(_getEmptyMessage(status), style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), 
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final service = filtered[index];
              
              switch (status) {
                case JobStatus.open:
                  return ClientOpenJobCard(service: service);
                case JobStatus.matched:
                  return ClientMatchedJobCard(service: service);
                case JobStatus.completed:
                  return ClientCompletedJobCard(service: service);
                default:
                  return const SizedBox();
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(child: Text("Error: $e")),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyMessage(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return "No hay trabajos publicados";
      case JobStatus.matched:
        return "No tienes trabajos en curso";
      case JobStatus.completed:
        return "Historial vacío";
      default:
        return "No hay datos";
    }
  }
}