import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

enum CaptureType { ineFront, ineBack, selfie }

class CameraCaptureScreen extends StatefulWidget {
  final CaptureType captureType;
  final void Function(File) onPhotoTaken;
  final List<CameraDescription> cameras;

  const CameraCaptureScreen({
    super.key,
    required this.captureType,
    required this.onPhotoTaken,
    required this.cameras,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isReady = false;
  bool _isCapturing = false;

  CameraDescription get _camera {
    final isSelfie = widget.captureType == CaptureType.selfie;
    final desired = isSelfie ? CameraLensDirection.front : CameraLensDirection.back;
    return widget.cameras.firstWhere(
      (c) => c.lensDirection == desired,
      orElse: () => widget.cameras.first,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _controller = CameraController(
        _camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir la cámara')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isReady || _controller == null || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final picture = await _controller!.takePicture();
      if (mounted) {
        widget.onPhotoTaken(File(picture.path));
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error al capturar: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelfie = widget.captureType == CaptureType.selfie;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isReady && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DarkOverlayPainter(
                  isSelfie: isSelfie,
                  screenSize: size,
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.08,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isSelfie
                      ? 'Centra tu rostro en el círculo'
                      : 'Centra la credencial en el recuadro',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.14,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.08,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isReady
                      ? GestureDetector(
                          onTap: _isCapturing ? null : _takePicture,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: _isCapturing
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                            child: _isCapturing
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        )
                      : const CircularProgressIndicator(color: Colors.white),

                  const SizedBox(height: 16),

                  Text(
                    isSelfie
                        ? 'Asegúrate de estar bien iluminado'
                        : 'Evita reflejos y asegura que se lean los datos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkOverlayPainter extends CustomPainter {
  final bool isSelfie;
  final Size screenSize;

  _DarkOverlayPainter({required this.isSelfie, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    if (isSelfie) {
      final centerX = size.width / 2;
      final centerY = size.height * 0.42;
      final radius = size.width * 0.35;

      final path = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius))
        ..fillType = PathFillType.evenOdd;

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawOval(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        borderPaint,
      );
    } else {
      final rectWidth = size.width * 0.86;
      final rectHeight = rectWidth * 0.62;
      final rectLeft = (size.width - rectWidth) / 2;
      final rectTop = size.height * 0.28;

      final path = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight),
            const Radius.circular(12),
          ),
        )
        ..fillType = PathFillType.evenOdd;

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight),
          const Radius.circular(12),
        ),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
