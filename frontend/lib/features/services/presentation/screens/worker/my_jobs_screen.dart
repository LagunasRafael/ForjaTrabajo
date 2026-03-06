import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 👇 Imports limpios (asegúrate de que las rutas coincidan)
import '../../providers/job_management_provider.dart';
import '../../widgets/service_status_chip.dart';
import 'package:forja_trabajo/shared/widgets/empty_state_widget.dart';
import 'package:forja_trabajo/shared/widgets/service_card_skeleton.dart';

class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Mis Trabajos',
              style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF4F46E5),
            tabs: [
              Tab(text: 'Abiertos'),
              Tab(text: 'En Curso'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFilteredJobList(ref, 'open'),
            _buildFilteredJobList(ref, 'in_progress'),
            _buildFilteredJobList(ref, 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredJobList(WidgetRef ref, String status) {
    final jobsAsync = ref.watch(jobManagementProvider);

    return jobsAsync.when(
      data: (jobs) {
        // 2. Filtramos la lista según el estado de la pestaña
        final filtered = jobs
            .where((j) => j.status.toString().split('.').last == status)
            .toList();

        if (filtered.isEmpty) {
          return _getEmptyStateForStatus(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) =>
              _buildJobCard(context, filtered[index]),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => const ServiceCardSkeleton(),
      ),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  // ✨ Función para personalizar el Empty State según la pestaña del trabajador
  Widget _getEmptyStateForStatus(String status) {
    switch (status) {
      case 'open':
        return const EmptyStateWidget(
          icon: Icons.assignment_late_outlined,
          title: "No hay solicitudes",
          message: "No tienes solicitudes nuevas pendientes de aceptar.",
        );
      case 'in_progress':
        return const EmptyStateWidget(
          icon: Icons.run_circle_outlined,
          title: "Nada en curso",
          message: "No tienes trabajos activos ahora mismo. ¡Manos a la obra!",
        );
      case 'completed':
        return const EmptyStateWidget(
          icon: Icons.check_circle_outline,
          title: "Historial vacío",
          message: "Aquí verás todos los trabajos que vayas terminando.",
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildJobCard(BuildContext context, dynamic job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ServiceStatusChip(
                    status: job.status.toString().split('.').last),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              // TODO: Cuando Juan Luis arregle el backend, cambiaremos esto por job.clientName
              'Cliente Anónimo',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${job.basePrice}",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5)),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Acción para ver detalles del trabajo
                  },
                  child: const Text("Ver detalles"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
