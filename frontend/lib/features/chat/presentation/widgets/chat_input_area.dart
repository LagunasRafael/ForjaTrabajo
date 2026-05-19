import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/offer_bottom_sheet.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_media_preview.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/spanish_asset_picker_delegate.dart';

class ChatInputArea extends ConsumerStatefulWidget {
  final String conversationId;
  final bool isClient;
  final bool canSendOffer;
  final bool isEnabled;
  final VoidCallback? onMessageSent;

  const ChatInputArea({
    super.key,
    required this.conversationId,
    required this.isClient,
    this.canSendOffer = true,
    this.isEnabled = true,
    this.onMessageSent,
  });

  @override
  ConsumerState<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends ConsumerState<ChatInputArea> {
  final TextEditingController _messageController = TextEditingController();
  Timer? _typingDebounce;

  List<XFile> _selectedMedia = [];
  List<String> _selectedMediaTypes = [];
  List<Duration?> _selectedMediaDurations = [];
  List<AssetEntity> _selectedAssets = [];

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isLockedRecording = false;
  String? _recordPath;

  @override
  void dispose() {
    _messageController.dispose();
    _typingDebounce?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTyping(String text) {
    setState(() {}); // Provoca rebuild para cambiar icono Mic/Send

    final notifier = ref.read(chatProvider(widget.conversationId).notifier);
    if (text.isNotEmpty) {
      notifier.sendTyping(true);
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        notifier.sendTyping(false);
      });
    } else {
      notifier.sendTyping(false);
      _typingDebounce?.cancel();
    }
  }

  void _onSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedMedia.isEmpty) return;
    
    final notifier = ref.read(chatProvider(widget.conversationId).notifier);
    notifier.sendTyping(false);
    _typingDebounce?.cancel();

    if (_selectedMedia.isNotEmpty) {
      final paths = _selectedMedia.map((m) => m.path).toList();
      notifier.sendMediaBatch(paths, text.isNotEmpty ? text : null);
      
      setState(() {
        _selectedMedia.clear();
        _selectedMediaTypes.clear();
        _selectedMediaDurations.clear();
        _selectedAssets.clear();
      });
    } else {
      notifier.sendMessage(text, "text");
    }

    _messageController.clear();
    widget.onMessageSent?.call();
  }

  void _showOfferDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferBottomSheet(
        onSendOffer: (amount) {
          ref.read(chatProvider(widget.conversationId).notifier).sendOffer(amount);
          widget.onMessageSent?.call();
        },
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isClient && widget.canSendOffer)
                ListTile(
                  leading: const Icon(Icons.local_offer, color: Color(0xFF4F46E5)),
                  title: const Text("Generar Oferta", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showOfferDialog();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text("Galería"),
                onTap: () {
                  Navigator.pop(context);
                  _pickGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: const Text("Compartir Ubicación"),
                onTap: () {
                  Navigator.pop(context);
                  _sendLocation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack, color: Colors.orange),
                title: const Text("Enviar Audio"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAudio();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null && mounted) {
      setState(() {
        _selectedMedia = [XFile(result.files.single.path!)];
        _selectedMediaTypes = ['audio'];
        _selectedMediaDurations = [null];
      });
    }
  }

  Future<void> _pickGallery() async {
    try {
      // Solicitar permisos explícitamente antes de abrir la galería
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Permiso denegado para acceder a la galería.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 5,
          selectedAssets: _selectedAssets,
          requestType: RequestType.common,
          textDelegate: const SpanishAssetPickerTextDelegate(),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _selectedAssets = result;
        });

        List<XFile> currentMedia = [];
        List<String> currentTypes = [];
        List<Duration?> currentDurations = [];

        for (var asset in result) {
          final file = await asset.file;
          if (file != null) {
            currentMedia.add(XFile(file.path));
            
            if (asset.type == AssetType.video) {
              currentTypes.add('video');
              currentDurations.add(Duration(seconds: asset.duration));
            } else {
              currentTypes.add('image');
              currentDurations.add(null);
            }
          }
        }

        setState(() {
          _selectedMedia = currentMedia;
          _selectedMediaTypes = currentTypes;
          _selectedMediaDurations = currentDurations;
        });
      }
    } catch (e) {
      print("🚨 Error en _pickGallery: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error al abrir galería"),
            content: Text("Ocurrió un detalle técnico:\n$e\n\nIntenta reiniciar la app."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showMaxLimitError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Límite alcanzado"),
        content: const Text("Solo puedes enviar hasta 5 archivos por mensaje."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  void _sendLocation() {
    final notifier = ref.read(chatProvider(widget.conversationId).notifier);
    notifier.sendLocation(); 
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    try {
      print("🎤 Attempting to start recording...");
      
      if (await _audioRecorder.isRecording()) {
        print("⚠️ Recorder is already active, stopping first...");
        await _audioRecorder.stop();
      }
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print("🚨 Microphone permission denied");
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      print("🎤 Starting recorder at path: $path");
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordPath = path;
      });
      print("✅ Recording started");
    } catch (e, stack) {
      print("🚨 Error in _startRecording: $e");
      print(stack);
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (!_isRecording && !_isLockedRecording) return;
      print("🎤 Stopping recording...");
      
      bool active = await _audioRecorder.isRecording();
      if (!active) {
         print("⚠️ Stop called but recorder was not active");
         setState(() { _isRecording = false; _isLockedRecording = false; });
         return;
      }
      
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isLockedRecording = false;
      });

      if (path != null) {
        print("✅ Recording stopped, adding to preview list: $path");
        
        // 🧪 Obtener duración
        Duration? duration;
        try {
          final tempPlayer = AudioPlayer();
          await tempPlayer.setSourceDeviceFile(path);
          duration = await tempPlayer.getDuration();
          await tempPlayer.dispose();
        } catch (e) {
          print("🚨 Error al obtener duración para previa: $e");
        }

        setState(() {
          _selectedMedia.add(XFile(path));
          _selectedMediaTypes.add('audio');
          _selectedMediaDurations.add(duration);
        });
      } else {
        print("⚠️ Recording stopped but path was null");
      }
    } catch (e, stack) {
      print("🚨 Error in _stopRecording: $e");
      print(stack);
      setState(() {
        _isRecording = false;
        _isLockedRecording = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    try {
      if (!_isRecording && !_isLockedRecording) return;
      print("🎤 Cancelling recording...");
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isLockedRecording = false;
      });
      if (_recordPath != null) {
        final file = File(_recordPath!);
        if (await file.exists()) {
          await file.delete();
          print("🗑️ Deleted cancelled record file");
        }
      }
    } catch (e) {
      print("🚨 Error in _cancelRecording: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasInput = _messageController.text.isNotEmpty || _selectedMedia.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedMedia.isNotEmpty)
           ChatMediaPreview(
              mediaList: _selectedMedia,
              mediaTypes: _selectedMediaTypes,
              mediaDurations: _selectedMediaDurations,
              onRemove: (index) {
                setState(() {
                  _selectedMedia.removeAt(index);
                  _selectedMediaTypes.removeAt(index);
                  _selectedMediaDurations.removeAt(index);
                  if (index < _selectedAssets.length) {
                    _selectedAssets.removeAt(index);
                  }
                });
              },
           ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: SafeArea(
        child: Row(
          children: [
            if (_isLockedRecording)
              Expanded(
                child: Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text("Cancelar", style: TextStyle(color: Colors.red)),
                      onPressed: _cancelRecording,
                    ),
                    Expanded(
                      child: Center(
                         child: TweenAnimationBuilder<double>(
                           tween: Tween(begin: 1.0, end: 0.0),
                           duration: Duration(milliseconds: 800),
                           builder: (context, value, child) => Opacity(
                             opacity: value,
                             child: const Text(
                               "Grabando (Manos Libres)", 
                               style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                             ),
                           ),
                         ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isRecording)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.red),
                      const SizedBox(width: 8),
                      const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: const Text("Desliza ⬆ para bloquear", style: TextStyle(color: Colors.red, fontSize: 13)),
                          );
                        },
                        onEnd: () {},
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.grey, size: 28),
                  onPressed: widget.isEnabled ? () => _showActionMenu(context) : null,
                ),
              ),
              if (widget.isClient && widget.canSendOffer)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.local_offer_rounded, color: Color(0xFF10B981), size: 28),
                    onPressed: widget.isEnabled ? _showOfferDialog : null,
                    tooltip: 'Enviar Propuesta',
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  onChanged: _onTyping,
                  enabled: widget.isEnabled,
                  decoration: InputDecoration(
                    hintText: widget.isEnabled ? "Escribe un mensaje..." : "Chat finalizado",
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _isRecording || _isLockedRecording ? Colors.red : const Color(0xFF4F46E5), 
                shape: BoxShape.circle
              ),
              child: GestureDetector(
                onLongPress: widget.isEnabled && !hasInput && !_isLockedRecording ? _startRecording : null,
                onLongPressEnd: widget.isEnabled && !hasInput && !_isLockedRecording ? (details) => _stopRecording() : null,
                onPanUpdate: (!hasInput && _isRecording && !_isLockedRecording) 
                     ? (details) {
                         if (details.localPosition.dx < -30) {
                             _cancelRecording();
                         } else if (details.localPosition.dy < -50) {
                             setState(() { _isLockedRecording = true; });
                         }
                       }
                     : null,
                onTap: _isLockedRecording 
                     ? () => _stopRecording() 
                     : hasInput ? _onSend : () { 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mantén presionado para enviar voz')));
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    (_isLockedRecording || hasInput) ? Icons.send_rounded : Icons.mic, 
                    color: Colors.white, 
                    size: 20
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
      ],
    );
  }
}
