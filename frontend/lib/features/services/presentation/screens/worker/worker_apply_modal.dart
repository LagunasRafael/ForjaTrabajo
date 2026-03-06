import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_request_provider.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_apply_widgets.dart';

void showWorkerApplyModal(
  BuildContext context, ServiceEntity service, {
  String? existingMessage, double? existingPrice, String? requestId,
}) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (ctx) => _WorkerApplyModalWidget(
      service: service, existingMessage: existingMessage, existingPrice: existingPrice, requestId: requestId,
    ),
  );
}

class _WorkerApplyModalWidget extends ConsumerStatefulWidget {
  final ServiceEntity service;
  final String? existingMessage;
  final double? existingPrice;
  final String? requestId;

  const _WorkerApplyModalWidget({
    required this.service, this.existingMessage, this.existingPrice, this.requestId,
  });

  @override
  ConsumerState<_WorkerApplyModalWidget> createState() => _WorkerApplyModalWidgetState();
}

class _WorkerApplyModalWidgetState extends ConsumerState<_WorkerApplyModalWidget> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  bool get _isEditing => widget.requestId != null;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.existingMessage ?? "");

    if (_isEditing && widget.existingPrice != null) {
      final String cents = (widget.existingPrice! * 100).toInt().toString();
      _priceCtrl = TextEditingController(text: _applyCurrencyFormat(cents));
    } else {
      _priceCtrl = TextEditingController(text: "00.00");
    }
  }

  String _applyCurrencyFormat(String value) {
    if (value.isEmpty) return "00.00";
    double amount = double.parse(value) / 100;
    return amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAction() async {
    final cleanPrice = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0;
                      
    if (_descCtrl.text.trim().isEmpty || cleanPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Indica un precio y un mensaje"), backgroundColor: Colors.orange));
        return;
    }
    FocusScope.of(context).unfocus();

    bool success = false;
    final notifier = ref.read(serviceRequestProvider.notifier);

    if (_isEditing) {
      success = await notifier.updateApplication(widget.requestId!, _descCtrl.text.trim(), cleanPrice);
    } else {
      success = await notifier.applyToService(widget.service.id, _descCtrl.text.trim(), cleanPrice);
    }

    if (mounted && success) {
        ref.invalidate(workerJobsProvider); 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? "✅ Propuesta actualizada" : "✅ Postulación enviada"), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WorkerDragHandle(),
              WorkerModalHeader(isEditing: _isEditing),
              const SizedBox(height: 28),
              
              const WorkerFormLabel(text: "Mensaje de propuesta"),
              WorkerDescriptionField(controller: _descCtrl),
              const SizedBox(height: 24),

              const WorkerFormLabel(text: "Tu precio (\$ MXN)"),
              WorkerPriceField(controller: _priceCtrl),
              const SizedBox(height: 10),
              
              Text(
                "SUGERENCIA DEL CLIENTE: \$${widget.service.basePrice.toStringAsFixed(0)} MXN", 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)
              ),
              const SizedBox(height: 35),
              
              Consumer(
                builder: (context, buttonRef, child) {
                  final status = buttonRef.watch(serviceRequestProvider);
                  return WorkerSubmitButton(isLoading: status.isLoading, isEditing: _isEditing, onPressed: _submitAction);
                }
              ),
              
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Cancelar", style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w600, fontSize: 16))
                )
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}