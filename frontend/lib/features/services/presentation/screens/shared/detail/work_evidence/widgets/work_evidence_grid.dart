import 'package:flutter/material.dart';
import 'package:forja_trabajo/features/services/domain/entities/work_evidence_entity.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/work_evidence/widgets/work_evidence_item.dart';

class WorkEvidenceGrid extends StatelessWidget {
  final List<WorkEvidenceEntity> evidences;
  final String serviceId;
  final String? currentUserId;
  final bool isActive;

  const WorkEvidenceGrid({
    super.key,
    required this.evidences,
    required this.serviceId,
    required this.currentUserId,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: evidences.length,
      itemBuilder: (context, index) {
        final evidence = evidences[index];
        final canDelete = isActive && currentUserId == evidence.workerId;
        return WorkEvidenceItem(
          evidence: evidence,
          canDelete: canDelete,
          serviceId: serviceId,
          allEvidences: evidences,
          index: index,
        );
      },
    );
  }
}
