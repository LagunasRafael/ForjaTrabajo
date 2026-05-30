import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/domain/entities/work_evidence_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/work_evidence_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/shared/widgets/image_gallery_picker.dart';
import 'widgets/work_evidence_header.dart';
import 'widgets/work_evidence_empty_state.dart';
import 'widgets/work_evidence_upload_button.dart';
import 'widgets/work_evidence_limit_message.dart';
import 'dialogs/work_evidence_preview_dialog.dart';
import 'dialogs/delete_evidence_dialog.dart';

class WorkEvidenceSection extends ConsumerStatefulWidget {
  final ServiceEntity service;

  const WorkEvidenceSection({super.key, required this.service});

  @override
  ConsumerState<WorkEvidenceSection> createState() => _WorkEvidenceSectionState();
}

class _WorkEvidenceSectionState extends ConsumerState<WorkEvidenceSection> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(workEvidenceListProvider(widget.service.id));
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
    final evidencesAsync = ref.watch(workEvidenceListProvider(widget.service.id));
    final currentUser = ref.watch(authProvider).user;
    final isWorker = currentUser?.id == widget.service.workerId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = currentUser?.id;
    final isActive = widget.service.status == JobStatus.matched || widget.service.status == JobStatus.waiting_confirmation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkEvidenceHeader(isDark: isDark),
        evidencesAsync.when(
          data: (evidences) => _buildContent(context, ref, evidences, isWorker, isActive, currentUserId, isDark),
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => Text("Error al cargar evidencias", style: TextStyle(color: Colors.red, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
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
          ImageGalleryPicker(
            images: evidences.map((e) => GalleryImageItem.url(e.imageUrl)).toList(),
            axis: Axis.vertical,
            crossAxisCount: 3,
            itemSize: 80,
            borderRadius: 8,
            showAddButton: false,
            canRemove: (i) => isActive && currentUserId == evidences[i].workerId,
            onRemove: (i) => showDeleteEvidenceDialog(
              context, ref,
              serviceId: widget.service.id,
              evidenceId: evidences[i].id,
            ),
            onTapImage: (i) => showWorkEvidencePreviewDialog(
              context,
              evidences: evidences,
              initialIndex: i,
            ),
          ),
        const SizedBox(height: 12),
        if (evidences.length >= 8)
          const WorkEvidenceLimitMessage()
        else if (isWorker && isActive)
          WorkEvidenceUploadButton(
            serviceId: widget.service.id,
            currentCount: evidences.length,
          ),
      ],
    );
  }
}
