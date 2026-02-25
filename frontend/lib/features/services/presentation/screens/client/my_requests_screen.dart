import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/service_status_chip.dart';
import '../../providers/service_list_provider.dart';
import '/shared/widgets/empty_state_widget.dart';
import '/shared/widgets/service_card_skeleton.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Mis Solicitudes', 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF4F46E5),
            tabs: [
              Tab(text: 'Abiertos'),
              Tab(text: 'En Proceso'),
              Tab(text: 'Finalizados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestList(ref, 'open'),
            _buildRequestList(ref, 'in_progress'),
            _buildRequestList(ref, 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(WidgetRef ref, String status) {
    final servicesAsync = ref.watch(serviceListProvider);

    return servicesAsync.when(
      data: (services) {
        // Filtramos por estado
        final filtered = services.where((s) => s.status == status).toList();

        // 👇 AQUÍ ENTRA LA MAGIA DEL EMPTY STATE
        if (filtered.isEmpty) {
          String title = "";
          String message = "";
          IconData icon = Icons.info_outline;

          // Personalizamos el mensaje según la pestaña
          switch (status) {
            case 'open':
              title = "Sin solicitudes abiertas";
              message = "No tienes ningún servicio pendiente. ¿Necesitas ayuda con algún proyecto en casa o la oficina?";
              icon = Icons.inbox_outlined;
              break;
            case 'in_progress':
              title = "Nada en proceso";
              message = "Actualmente no tienes trabajos realizándose. Aquí verás los servicios cuando el trabajador acepte tu solicitud.";
              icon = Icons.handyman_outlined;
              break;
            case 'completed':
              title = "Sin historial";
              message = "Aún no tienes trabajos finalizados. ¡Todos tus proyectos completados con éxito aparecerán aquí!";
              icon = Icons.history_outlined;
              break;
          }

          return EmptyStateWidget(
            icon: icon,
            title: title,
            message: message,
            // Solo le ponemos botón a la pestaña de "Abiertos" para invitarlo a buscar
            buttonText: status == 'open' ? "Buscar Servicios" : null,
            onButtonPressed: status == 'open' ? () {
              // TODO: Redirigir al inicio (Home)
              print("Ir al inicio a buscar servicios");
            } : null,
          );
        }

        // Si sí hay datos, mostramos tu ListView normal
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildRequestCard(context, filtered[index]),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4, // Mostramos 4 tarjetas fantasma mientras carga
        itemBuilder: (context, index) => const ServiceCardSkeleton(),
      ),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildRequestCard(BuildContext context, dynamic service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.air_outlined, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(service.categoryName ?? 'Servicio', 
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                ServiceStatusChip(status: service.status),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Descripción del problema o tarea realizada...", 
              style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Worker asignado:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                TextButton(
                  onPressed: () {}, 
                  child: const Text("Ver Detalles", style: TextStyle(fontWeight: FontWeight.bold))
                ),
              ],
            ),
            // BOTONES DE ACCIÓN (Como en tu foto)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: const Text("Contactar"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}