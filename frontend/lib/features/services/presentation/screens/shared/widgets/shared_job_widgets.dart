import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/usecases/jobs/cancel_job_usecase.dart';

// 🚀 PROVIDER DE ESTADO DE CANCELACIÓN (Lo ponemos aquí para que el Lego sea independiente)
final isCancelingProvider = StateProvider.family<bool, String>((ref, id) => false);

// 🧱 LEGO 1: LA IMAGEN UNIVERSAL
class SharedJobImage extends StatelessWidget {
  final List<String> imageUrls;
  final String? badgeText;
  final Color? badgeColor;
  final Widget? floatingMenu;

  const SharedJobImage({
    super.key, 
    required this.imageUrls, 
    this.badgeText, 
    this.badgeColor,
    this.floatingMenu,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrls.isNotEmpty ? imageUrls.first : 'https://placehold.co/600x400/e2e8f0/64748b?text=Sin+Imagen';
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          Image.network(url, height: 140, width: double.infinity, fit: BoxFit.cover, cacheWidth: 600,
            errorBuilder: (_, __, ___) => Container(height: 140, width: double.infinity, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
          ),
          if (badgeText != null && badgeColor != null)
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(badgeText!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          if (floatingMenu != null)
            Positioned(top: 5, left: 5, child: floatingMenu!),
        ],
      ),
    );
  }
}

// 🧱 LEGO 2: LA INFO UNIVERSAL
class SharedJobInfo extends StatelessWidget {
  final String title;
  final double price;
  final String? location;

  const SharedJobInfo({super.key, required this.title, required this.price, this.location});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text("\$${price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(child: Text(location ?? 'Remoto', style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }
}

// 🧱 LEGO 3: MENÚ DE CANCELAR UNIVERSAL
class SharedCancelMenu extends ConsumerWidget {
  final String jobId;
  final VoidCallback onCancelSuccess;

  const SharedCancelMenu({super.key, required this.jobId, required this.onCancelSuccess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCanceling = ref.watch(isCancelingProvider(jobId));

    if (isCanceling) {
      return const CircleAvatar(backgroundColor: Colors.black45, radius: 18, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)));
    }

    return CircleAvatar(
      backgroundColor: Colors.black45, radius: 18,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero, icon: const Icon(Icons.more_vert, color: Colors.white, size: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (val) => val == 'cancel' ? _handleCancel(context, ref) : null,
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, size: 20, color: Colors.black87), SizedBox(width: 10), Text("Reportar")])),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'cancel', child: Row(children: [Icon(Icons.cancel_outlined, size: 20, color: Colors.red), SizedBox(width: 10), Text("Cancelar trabajo", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
        ],
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('¿Cancelar este trabajo?'), content: const Text('Esta acción es irreversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Confirmar', style: TextStyle(color: Colors.white)))
      ]
    ));

    if (confirm == true) {
      ref.read(isCancelingProvider(jobId).notifier).state = true;
      final success = await ref.read(cancelJobUseCaseProvider).execute(jobId);
      ref.read(isCancelingProvider(jobId).notifier).state = false;

      if (success && context.mounted) {
        onCancelSuccess(); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Trabajo cancelado."), backgroundColor: Colors.orange));
      }
    }
  }
}