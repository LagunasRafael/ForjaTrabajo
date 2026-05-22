import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/work_evidence_provider.dart';

Future<bool> showDeleteEvidenceDialog(
  BuildContext context,
  WidgetRef ref, {
  required String serviceId,
  required String evidenceId,
}) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Eliminar evidencia"),
      content: const Text("¿Estás seguro de eliminar esta evidencia?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Eliminar"),
        ),
      ],
    ),
  );
  if (confirm != true) return false;

  try {
    await ref.read(deleteEvidenceProvider(
      DeleteEvidenceParams(serviceId: serviceId, evidenceId: evidenceId),
    ).future);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Imagen eliminada correctamente",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF4F46E5)),
          ),
          backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 890,
            left: 24,
            right: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error al eliminar: $e",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF4F46E5)),
          ),
          backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 890,
            left: 24,
            right: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return false;
  }
}
