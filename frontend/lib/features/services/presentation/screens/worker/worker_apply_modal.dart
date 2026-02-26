import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_request_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_offers_provider.dart';

void showWorkerApplyModal(BuildContext context, WidgetRef ref, ServiceEntity service) {
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const Text("Enviar Postulación", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("Completa los detalles de tu propuesta.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            _buildLabel("Mensaje de propuesta"),
            TextField(controller: descCtrl, maxLines: 3, decoration: _inputStyle("Ej. Tengo experiencia en...")),
            const SizedBox(height: 20),

            _buildLabel("Tu precio (\$ MXN)"),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              decoration: _inputStyle("0.00").copyWith(prefixText: "\$ "),
            ),
            const SizedBox(height: 8),
            Text("SUGERENCIA: \$${service.basePrice.toStringAsFixed(0)} MXN", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            
            const SizedBox(height: 32),
            Consumer(builder: (context, modalRef, _) {
              final status = modalRef.watch(serviceRequestProvider);
              return SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: status.isLoading ? null : () async {
                    final price = double.tryParse(priceCtrl.text) ?? 0.0;
                    if (descCtrl.text.isEmpty || price <= 0) return;
                    final success = await modalRef.read(serviceRequestProvider.notifier).applyToService(service.id, descCtrl.text, price);
                    if (context.mounted && success) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Postulación enviada"), backgroundColor: Color(0xFF10B981)));
                      modalRef.invalidate(offersListProvider(service.id));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: status.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Enviar Postulación", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));

InputDecoration _inputStyle(String hint) => InputDecoration(
  hintText: hint, filled: true, fillColor: Colors.grey[50],
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
);