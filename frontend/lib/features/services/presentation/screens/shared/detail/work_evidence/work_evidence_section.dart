import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/domain/entities/work_evidence_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/work_evidence_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'widgets/work_evidence_header.dart';
import 'widgets/work_evidence_empty_state.dart';
import 'widgets/work_evidence_grid.dart';
import 'widgets/work_evidence_upload_button.dart';
import 'widgets/work_evidence_limit_message.dart';

class WorkEvidenceSection extends ConsumerWidget {
  final ServiceEntity service;

  const WorkEvidenceSection({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evidencesAsync = ref.watch(workEvidenceListProvider(service.id));
    final currentUser = ref.watch(authProvider).user;
    final isWorker = currentUser?.id == service.workerId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = currentUser?.id;
    final isActive = service.status == JobStatus.matched || service.status == JobStatus.waiting_confirmation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkEvidenceHeader(isDark: isDark),
        evidencesAsync.when(
          data: (evidences) => _buildContent(evidences, isWorker, isActive, currentUserId, isDark),
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => Text("Error al cargar evidencias", style: TextStyle(color: Colors.red, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildContent(
    List<WorkEvidenceEntity> evidences,
    bool isWorker,
    bool isActive,
    String? currentUserId,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (evidences.isEmpty)
          WorkEvidenceEmptyState(isDark: isDark)
        else
          WorkEvidenceGrid(
            evidences: evidences,
            serviceId: service.id,
            currentUserId: currentUserId,
            isActive: isActive,
          ),
        const SizedBox(height: 12),
        if (evidences.length >= 8)
          const WorkEvidenceLimitMessage()
        else if (isWorker && isActive)
          WorkEvidenceUploadButton(
            serviceId: service.id,
            currentCount: evidences.length,
          ),
      ],
    );
  }
}
