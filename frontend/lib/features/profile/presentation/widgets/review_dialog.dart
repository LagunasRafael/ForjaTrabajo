import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/public_profile_provider.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  final String jobId;
  final String revieweeName;

  const ReviewDialog({
    super.key,
    required this.jobId,
    required this.revieweeName,
  });

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final dataSource = ref.read(profileRemoteDataSourceProvider);
      await dataSource.leaveReview(
        widget.jobId,
        _rating,
        _commentController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Devuelve true si fue exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Reseña enviada con éxito!')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll("Exception:", "");
        // Si es un error de Dio, intentamos extraer el mensaje real del backend
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('detail')) {
            errorMessage = data['detail'];
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Califica a ${widget.revieweeName}', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Cómo fue tu experiencia trabajando con esta persona?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escribe un comentario (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enviar Reseña'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
