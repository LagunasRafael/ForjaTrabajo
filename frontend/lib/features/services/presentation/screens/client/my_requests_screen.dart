import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';

// Providers
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
// 👇 IMPORTS CORREGIDOS: Copia y pega estas 3 líneas
import 'package:forja_trabajo/features/services/presentation/widgets/client/client_open_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/client_matched_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/client_completed_job_card.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 👂 AQUÍ OCURRE EL MILAGRO:
    // Escuchamos si alguien (como la pantalla de ofertas) quiere cambiar la pestaña
    ref.listen<int>(myRequestsTabProvider, (previous, nextIndex) {
      _tabController.animateTo(nextIndex);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mis Trabajos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
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
        // 🚀 LA MAGIA: Esto desactiva el deslizamiento lateral (swipe)
        physics: const NeverScrollableScrollPhysics(), 
        children: [
          // 0. Abiertos
          _buildRequestList(ref, JobStatus.open),
          // 1. En Proceso (Matched)
          _buildRequestList(ref, JobStatus.matched),
          // 2. Finalizados
          _buildRequestList(ref, JobStatus.completed),
        ],
      ),
    );
  }

  Widget _buildRequestList(WidgetRef ref, JobStatus status) {
    final servicesAsync = ref.watch(myRequestsProvider);

    // 🚀 ENVOLVEMOS TODO EN EL REFRESH INDICATOR
    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async {
        // Esto obliga a Riverpod a ir al backend de nuevo
        await ref.refresh(myRequestsProvider.future);
      },
      child: servicesAsync.when(
        data: (services) {
          final filtered = services.where((s) {
            if (status == JobStatus.matched) {
              return s.status == JobStatus.matched || s.status == JobStatus.waiting_confirmation;
            }
            return s.status == status;
          }).toList();

          if (filtered.isEmpty) {
            // 💡 IMPORTANTE: Si está vacío, usamos un ListView o SingleChildScrollView 
            // con AlwaysScrollableScrollPhysics para que el gesto de jalar funcione.
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
            // 💡 AlwaysScrollableScrollPhysics permite jalar incluso si hay pocos elementos
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
        error: (e, s) => ListView( // También scrollable en error para re-intentar
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
      case JobStatus.open: return "No hay trabajos publicados";
      case JobStatus.matched: return "No tienes trabajos en curso";
      case JobStatus.completed: return "Historial vacío";
      default: return "No hay datos";
    }
  }
}