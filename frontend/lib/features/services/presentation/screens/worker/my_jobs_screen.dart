import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import '../../providers/job_management_provider.dart'; 
import 'package:forja_trabajo/shared/widgets/empty_state_widget.dart';
import 'package:forja_trabajo/shared/widgets/service_card_skeleton.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_pending_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_active_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_completed_job_card.dart';

class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _WorkerMyJobsScreenState();
}

class _WorkerMyJobsScreenState extends ConsumerState<MyJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 3 Pestañas: Postulaciones, En Curso, Historial
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mis Empleos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Postulaciones'),
            Tab(text: 'En Curso'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 0. Postulaciones
          _buildFilteredJobList(ref, JobStatus.open),
          // 1. En Curso
          _buildFilteredJobList(ref, JobStatus.matched),
          // 2. Historial
          _buildFilteredJobList(ref, JobStatus.completed),
        ],
      ),
    );
  }

  Widget _buildFilteredJobList(WidgetRef ref, JobStatus status) {
    final jobsAsync = ref.watch(workerJobsProvider); 
    
    return jobsAsync.when(
      data: (jobs) {
        // Filtramos asegurándonos de que JobStatus coincida exactamente con el objeto
        final filtered = jobs.where((j) {
          if (status == JobStatus.matched) {
            return j.status == JobStatus.matched || j.status == JobStatus.waiting_confirmation;
          }
          return j.status == status;
        }).toList();

        if (filtered.isEmpty) {
          return Center(child: _getEmptyStateForStatus(status));
        }
        
        // 🚀 AGREGAMOS REFRESH INDICATOR: Para que puedas jalar hacia abajo y actualizar
        return RefreshIndicator(
          onRefresh: () => ref.refresh(workerJobsProvider.future),
          color: const Color(0xFF10B981),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final job = filtered[index];
              
              switch (status) {
                case JobStatus.open:
                  return WorkerPendingJobCard(job: job);
                case JobStatus.matched:
                  return WorkerActiveJobCard(job: job);
                case JobStatus.completed:
                  return WorkerCompletedJobCard(job: job);
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  // ✨ Textos personalizados
  Widget _getEmptyStateForStatus(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return const EmptyStateWidget(
          icon: Icons.assignment_late_outlined,
          title: "Sin postulaciones",
          message: "No tienes ofertas pendientes. ¡Busca nuevos servicios y postúlate!",
        );
      case JobStatus.matched:
        return const EmptyStateWidget(
          icon: Icons.run_circle_outlined,
          title: "Nada en curso",
          message: "No tienes trabajos activos ahora mismo. ¡Manos a la obra!",
        );
      case JobStatus.completed:
        return const EmptyStateWidget(
          icon: Icons.check_circle_outline,
          title: "Historial vacío",
          message: "Aquí verás todos los trabajos que vayas terminando y cobrando.",
        );
      default:
        return const SizedBox.shrink();
    }
  }
}