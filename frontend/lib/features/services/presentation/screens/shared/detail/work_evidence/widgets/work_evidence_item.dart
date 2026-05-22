import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/work_evidence_entity.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/work_evidence/dialogs/work_evidence_preview_dialog.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/work_evidence/dialogs/delete_evidence_dialog.dart';

class WorkEvidenceItem extends ConsumerWidget {
  final WorkEvidenceEntity evidence;
  final bool canDelete;
  final String serviceId;
  final List<WorkEvidenceEntity>? allEvidences;
  final int? index;

  const WorkEvidenceItem({
    super.key,
    required this.evidence,
    required this.canDelete,
    required this.serviceId,
    this.allEvidences,
    this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => showWorkEvidencePreviewDialog(
            context,
            evidences: allEvidences ?? [evidence],
            initialIndex: index ?? 0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              evidence.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
        if (canDelete)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => showDeleteEvidenceDialog(
                context,
                ref,
                serviceId: serviceId,
                evidenceId: evidence.id,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
