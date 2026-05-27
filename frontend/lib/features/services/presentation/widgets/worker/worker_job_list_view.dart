import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/shared/widgets/empty_state_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_pending_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_active_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_completed_job_card.dart';

class WorkerJobListView extends ConsumerStatefulWidget {
  final JobStatus status;

  const WorkerJobListView({super.key, required this.status});

  @override
  ConsumerState<WorkerJobListView> createState() => _WorkerJobListViewState();
}

class _WorkerJobListViewState extends ConsumerState<WorkerJobListView> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(workerJobsProvider);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(workerJobsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return jobsAsync.when(
      data: (jobs) {
        final filtered = jobs.where((j) {
          if (widget.status == JobStatus.matched) {
            return j.status == JobStatus.matched || j.status == JobStatus.waiting_confirmation || j.status == JobStatus.disputed;
          }
          if (widget.status == JobStatus.completed) {
            return j.status == JobStatus.completed || j.status == JobStatus.cancelled;
          }
          return j.status == widget.status;
        }).toList();

        return RefreshIndicator(
          onRefresh: () => ref.refresh(workerJobsProvider.future),
          color: const Color(0xFF10B981),
          child: filtered.isEmpty 
            ? _buildEmptyState(context)
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final job = filtered[index];
                  
                  final isTerminal = job.status == JobStatus.completed || job.status == JobStatus.cancelled;
                  return switch (widget.status) {
                    JobStatus.open      => WorkerPendingJobCard(job: job),
                    JobStatus.matched   => WorkerActiveJobCard(job: job),
                    JobStatus.completed => isTerminal
                      ? WorkerCompletedJobCard(job: job)
                      : const SizedBox.shrink(),
                    _                   => const SizedBox.shrink(),
                  };
                },
              ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      error: (e, s) => _buildErrorState(e, isDark, ref),
    );
  }

  // 🧱 Widget para cuando no hay chamba
  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _EmptyStateHelper(status: widget.status),
        ),
      ],
    );
  }

  // 🧱 Widget para cuando algo explota (Error)
    Widget _buildErrorState(Object e, bool isDark, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          // En lugar de SizedBox con altura fija, usamos Padding
          // para que el contenido respire pero pueda crecer
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 20),
              Text(
                "¡Ups! Algo salió mal",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$e", // Aquí se muestra el error 404 largo
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(workerJobsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text("Reintentar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyStateHelper extends StatelessWidget {
  final JobStatus status;
  const _EmptyStateHelper({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      JobStatus.open => const EmptyStateWidget(
          icon: Icons.assignment_late_outlined,
          title: "Sin postulaciones",
          message: "No tienes ofertas pendientes. ¡Busca nuevos servicios!",
        ),
      JobStatus.matched => const EmptyStateWidget(
          icon: Icons.run_circle_outlined,
          title: "Nada en curso",
          message: "No tienes trabajos activos ahora mismo.",
        ),
      JobStatus.completed => const EmptyStateWidget(
          icon: Icons.check_circle_outline,
          title: "Historial vacío",
          message: "Aquí verás tus trabajos finalizados.",
        ),
      _ => const SizedBox.shrink(),
    };
  }
}