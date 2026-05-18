import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_capture_screen.dart';

class CameraGuideScreen extends StatefulWidget {
  final CaptureType captureType;
  final Function(File) onPhotoTaken;

  const CameraGuideScreen({
    super.key,
    required this.captureType,
    required this.onPhotoTaken,
  });

  @override
  State<CameraGuideScreen> createState() => _CameraGuideScreenState();
}

class _CameraGuideScreenState extends State<CameraGuideScreen> {
  String get _title {
    switch (widget.captureType) {
      case CaptureType.ineFront:
        return 'INE - Frente';
      case CaptureType.ineBack:
        return 'INE - Reverso';
      case CaptureType.selfie:
        return 'Selfie';
    }
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró cámara en el dispositivo')),
        );
        return;
      }

      await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (_) => CameraCaptureScreen(
            captureType: widget.captureType,
            onPhotoTaken: widget.onPhotoTaken,
            cameras: cameras,
          ),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error abriendo cámara: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSelfie = widget.captureType == CaptureType.selfie;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size.width,
                    height: size.width * 1.4,
                    color: Colors.grey.shade900,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Toca el botón para abrir la cámara',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _OverlayPainter(
                          isSelfie: isSelfie,
                          screenSize: Size(size.width, size.width * 1.4),
                        ),
                      ),
                    ),
                  ),

                  if (isSelfie)
                    Positioned(
                      top: size.width * 0.3,
                      child: Container(
                        width: size.width * 0.55,
                        height: size.width * 0.55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: size.width * 0.15,
                      child: Container(
                        width: size.width * 0.82,
                        height: size.width * 1.05,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instrucciones:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (isSelfie) ...[
                  _buildInstruction(Icons.face, 'Centra tu rostro en el círculo'),
                  _buildInstruction(Icons.visibility_off, 'Quítate lentes y gorras'),
                  _buildInstruction(Icons.wb_sunny, 'Busca buena iluminación frontal'),
                  _buildInstruction(Icons.person_off, 'Que no haya otras personas en la foto'),
                ] else ...[
                  _buildInstruction(Icons.crop_square, 'Centra la credencial en el recuadro'),
                  _buildInstruction(Icons.flash_on, 'Evita reflejos y brillos'),
                  _buildInstruction(Icons.image, 'Que se vean todos los datos claros'),
                  _buildInstruction(Icons.panorama_fish_eye, 'Toma la foto de frente, sin ángulo'),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _openCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      'Abrir Cámara',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade300, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final bool isSelfie;
  final Size screenSize;

  _OverlayPainter({required this.isSelfie, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);

    if (isSelfie) {
      final centerX = size.width / 2;
      final centerY = size.width * 0.3 + size.width * 0.275;
      final radius = size.width * 0.275;

      final path = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius))
        ..fillType = PathFillType.evenOdd;

      canvas.drawPath(path, paint);
    } else {
      final rectLeft = size.width * 0.09;
      final rectTop = size.width * 0.15;
      final rectWidth = size.width * 0.82;
      final rectHeight = size.width * 1.05;

      final path = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight),
          const Radius.circular(12),
        ))
        ..fillType = PathFillType.evenOdd;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
