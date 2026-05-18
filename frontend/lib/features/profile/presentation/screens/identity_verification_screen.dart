import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/verification_remote_data_source.dart';
import '../widgets/camera_capture_screen.dart';
import '../widgets/camera_guide_overlay.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends ConsumerState<IdentityVerificationScreen> {
  File? _ineFront;
  File? _ineBack;
  File? _selfie;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final ds = ref.read(verificationDataSourceProvider);
      final status = await ds.getVerificationStatus();
      if (mounted && status['verification'] != null) {
        setState(() => _result = status);
      }
    } catch (_) {}
  }

  Future<void> _openCameraFor(String type) async {
    final captureType = type == 'front'
        ? CaptureType.ineFront
        : type == 'back'
            ? CaptureType.ineBack
            : CaptureType.selfie;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraGuideScreen(
          captureType: captureType,
          onPhotoTaken: (file) {
            if (mounted) {
              setState(() {
                switch (type) {
                  case 'front':
                    _ineFront = file;
                    break;
                  case 'back':
                    _ineBack = file;
                    break;
                  case 'selfie':
                    _selfie = file;
                    break;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_ineFront == null || _ineBack == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toma las 3 fotos requeridas'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ds = ref.read(verificationDataSourceProvider);
      final result = await ds.uploadVerification(
        ineFront: _ineFront!,
        ineBack: _ineBack!,
        selfie: _selfie!,
      );
      if (mounted) {
        final msg = result['message'] ?? 'Verificación enviada';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_result != null && _result!['verification'] != null) {
      return _buildResultView(theme);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Verificar Identidad'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 32),
                  SizedBox(height: 12),
                  Text(
                    'Para verificar tu identidad necesitas:\n'
                    '1. Foto del frente de tu INE\n'
                    '2. Foto del reverso de tu INE\n'
                    '3. Una selfie tuya',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildPhotoButton('INE - Frente', _ineFront, () => _openCameraFor('front')),
            const SizedBox(height: 12),
            _buildPhotoButton('INE - Reverso', _ineBack, () => _openCameraFor('back')),
            const SizedBox(height: 12),
            _buildPhotoButton('Selfie', _selfie, () => _openCameraFor('selfie')),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Enviar Verificación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoButton(String label, File? image, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image, fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 32, color: Colors.grey.shade500),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  Widget _buildResultView(ThemeData theme) {
    final v = _result!['verification'];
    final status = v['status'] as String;
    final isVerified = _result!['is_identity_verified'] == true;
    final similarity = v['face_similarity'];
    final reason = v['rejection_reason'];

    IconData icon;
    Color color;
    String title;
    if (status == 'approved' || isVerified) {
      icon = Icons.verified;
      color = Colors.green;
      title = '¡Identidad Verificada!';
    } else if (status == 'rejected') {
      icon = Icons.cancel;
      color = Colors.red;
      title = 'Verificación Rechazada';
    } else {
      icon = Icons.hourglass_bottom;
      color = Colors.orange;
      title = 'Verificación Pendiente';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Verificar Identidad'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              if (similarity != null) ...[
                const SizedBox(height: 16),
                Text('Similitud facial: ${similarity.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16)),
              ],
              if (reason != null && reason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Motivo: $reason', style: TextStyle(color: Colors.red.shade700)),
                ),
              ],
              if (status == 'rejected') ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _result = null);
                  },
                  child: const Text('Intentar de nuevo'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
