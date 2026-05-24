import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/payments/presentation/providers/wallet_status_provider.dart';
import 'package:forja_trabajo/features/payments/presentation/screens/wallet_screen.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_request_provider.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_apply_widgets.dart';

void showWorkerApplyModal(
  BuildContext context, ServiceEntity service, {
  String? existingMessage, double? existingPrice, String? requestId,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final walletStatus = await container.read(walletStatusProvider.future);

  if (!walletStatus.isReady) {
    if (!context.mounted) return;
    _showWalletRequiredDialog(context);
    return;
  }

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (ctx) => _WorkerApplyModalWidget(
      service: service, existingMessage: existingMessage, existingPrice: existingPrice, requestId: requestId,
    ),
  );
}

void _showWalletRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.wallet_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 10),
          Text('Billetera requerida', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: const Text(
        'Para postularte a trabajos necesitas configurar tu billetera (Stripe) primero.\n\n'
        'Ve a "Mi Billetera" en tu perfil para configurarla.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Ahora no'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            _navigateToWallet(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7F13EC),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Ir a Mi Billetera'),
        ),
      ],
    ),
  );
}

void _navigateToWallet(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WalletScreen()),
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
    _priceCtrl = TextEditingController(
      text: widget.existingPrice != null ? widget.existingPrice!.toStringAsFixed(0) : ""
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAction() async {
    final cleanPrice = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0;
                      
    if (_descCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Por favor escribe un mensaje de propuesta"), backgroundColor: Colors.orange));
        return;
    }
    if (cleanPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ El precio debe ser mayor a 0"), backgroundColor: Colors.orange));
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

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final screenHeight = MediaQuery.of(context).size.height;

      Navigator.pop(context);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? "Propuesta actualizada" : "Postulación enviada",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF4F46E5)),
          ),
          backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: screenHeight - 900,
            left: 24,
            right: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
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
                "PRESUPUESTO SUGERIDO POR EL CLIENTE: \$${widget.service.basePrice.toStringAsFixed(0)} MXN", 
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