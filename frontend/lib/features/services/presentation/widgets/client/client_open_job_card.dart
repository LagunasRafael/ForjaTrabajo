import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/offers_received_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/widgets/shared_job_widgets.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientOpenJobCard extends ConsumerWidget { 
  final ServiceEntity service;

  const ClientOpenJobCard({super.key, required this.service});

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedJobImage(
            imageUrls: service.imageUrls,
            badgeText: "BUSCANDO", 
            badgeColor: const Color(0xFF4F46E5), 
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SharedJobInfo(
                  title: service.title, 
                  price: service.basePrice, 
                  location: "Publicado el ${_formatDate(service.createdAt)} • ${service.exactAddress ?? 'Ubicación remota'}"
                ),
                const SizedBox(height: 20),
                
                _buildActions(context, ref), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => OffersReceivedScreen(service: service)));
            },
            icon: const Icon(Icons.people_alt_rounded, size: 20),
            label: const Text("Ver Postulados"), 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5), 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFEE2E2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
            onPressed: () {
              // 3. LLAMAMOS AL DIÁLOGO AL PICAR LA X
              _showCancelDialog(context, ref);
            },
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("¿Cancelar publicación?", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text("Los trabajadores ya no podrán ver ni postularse a este servicio. Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Volver", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              Navigator.pop(ctx); 
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cancelando publicación..."), duration: Duration(seconds: 1))
              );

              // 🚀 1. SACAMOS EL TOKEN REAL DEL USUARIO
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token') ?? '';
              
              if (token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error: Sesión expirada", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
                );
                return; // Cortamos la función aquí si no hay token
              }
              
              // 🚀 2. MANDAMOS LA PETICIÓN CON EL TOKEN REAL
              await ref.read(serviceControllerProvider.notifier).cancelService(service.id, token);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Publicación cancelada", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
                );
              }
            },
            child: const Text("Sí, cancelar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}