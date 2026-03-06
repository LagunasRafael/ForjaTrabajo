import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/shared/widgets/empty_state_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_pending_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_active_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_completed_job_card.dart';

class WorkerJobListView extends ConsumerWidget {
  final JobStatus status;

  const WorkerJobListView({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(workerJobsProvider);

    return jobsAsync.when(
      data: (jobs) {
        final filtered = jobs.where((j) {
          if (status == JobStatus.matched) {
            return j.status == JobStatus.matched || j.status == JobStatus.waiting_confirmation;
          }
          return j.status == status;
        }).toList();

        if (filtered.isEmpty) {
          return Center(child: _EmptyStateHelper(status: status));
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(workerJobsProvider.future),
          color: const Color(0xFF10B981),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final job = filtered[index];
              
              return switch (status) {
                JobStatus.open      => WorkerPendingJobCard(job: job),
                JobStatus.matched   => WorkerActiveJobCard(job: job),
                JobStatus.completed => WorkerCompletedJobCard(job: job),
                _                   => const SizedBox.shrink(),
              };
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Ocurrió un error: $e")),
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