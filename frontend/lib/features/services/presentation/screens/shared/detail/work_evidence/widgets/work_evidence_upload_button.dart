import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:forja_trabajo/features/services/presentation/providers/work_evidence_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/spanish_asset_picker_delegate.dart';

class WorkEvidenceUploadButton extends ConsumerWidget {
  final String serviceId;
  final int currentCount;

  const WorkEvidenceUploadButton({
    super.key,
    required this.serviceId,
    required this.currentCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _pickAndUpload(context, ref),
        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
        label: Text(
          "Subir evidencia ${currentCount > 0 ? "(${currentCount}/8)" : ""}",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Permiso denegado para acceder a la galería.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final remaining = 8 - currentCount;
    if (remaining <= 0) return;

    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: remaining,
        requestType: RequestType.image,
        textDelegate: const SpanishAssetPickerTextDelegate(),
      ),
    );

    if (result == null || result.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    int successCount = 0;
    try {
      for (final asset in result) {
        final file = await asset.file;
        if (file == null) continue;
        try {
          await ref.read(uploadEvidenceProvider(
            UploadEvidenceParams(serviceId: serviceId, imageFile: file),
          ).future);
          successCount++;
        } catch (_) {}
      }

      if (context.mounted) {
        Navigator.pop(context);
        final msg = successCount > 0
            ? "✅ $successCount evidencia${successCount > 1 ? 's' : ''} subida${successCount > 1 ? 's' : ''}"
            : "❌ Error al subir evidencias";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: successCount > 0 ? Colors.green : Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
