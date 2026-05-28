import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/work_evidence_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_repository_provider.dart';

final workEvidenceListProvider = FutureProvider.autoDispose.family<List<WorkEvidenceEntity>, String>((ref, serviceId) async {
  final repo = ref.watch(serviceRepositoryProvider);
  return repo.getEvidences(serviceId);
});

class UploadEvidenceParams {
  final String serviceId;
  final File imageFile;
  final String? description;

  UploadEvidenceParams({
    required this.serviceId,
    required this.imageFile,
    this.description,
  });
}

final uploadEvidenceProvider = FutureProvider.family<void, UploadEvidenceParams>((ref, params) async {
  final repo = ref.watch(serviceRepositoryProvider);
  await repo.uploadEvidence(params.serviceId, params.imageFile, params.description);
  ref.invalidate(workEvidenceListProvider(params.serviceId));
});

final deleteEvidenceProvider = FutureProvider.family<void, DeleteEvidenceParams>((ref, params) async {
  final repo = ref.watch(serviceRepositoryProvider);
  await repo.deleteEvidence(params.serviceId, params.evidenceId);
  ref.invalidate(workEvidenceListProvider(params.serviceId));
});

class DeleteEvidenceParams {
  final String serviceId;
  final String evidenceId;

  DeleteEvidenceParams({required this.serviceId, required this.evidenceId});
}
