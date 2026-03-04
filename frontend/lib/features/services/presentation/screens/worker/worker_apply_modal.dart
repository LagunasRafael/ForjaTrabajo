import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_request_provider.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '0.00', selection: TextSelection.collapsed(offset: 4));
    double value = double.parse(digitsOnly) / 100;
    String formatted = value.toStringAsFixed(2);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

void showWorkerApplyModal(
  BuildContext context, 
  WidgetRef ref, 
  ServiceEntity service, {
  String? existingMessage,
  double? existingPrice,
  String? requestId, // Si viene con ID, significa que estamos EDITANDO
}) {
  final isEditing = requestId != null;
  
  final descCtrl = TextEditingController(text: existingMessage ?? "");
  final priceCtrl = TextEditingController(text: existingPrice != null ? existingPrice.toStringAsFixed(2) : "0.00");

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45, 
                  height: 5, 
                  margin: const EdgeInsets.only(bottom: 25), 
                  decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(10))
                )
              ),

              // Título dinámico
              Text(
                isEditing ? "Editar Propuesta" : "Enviar Postulación", 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))
              ),
              const SizedBox(height: 8),
              const Text("Modifica tu tarifa o mensaje para el cliente.", style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
              const SizedBox(height: 28),
              
              _buildLabel("Mensaje de propuesta"),
              TextField(
                controller: descCtrl, 
                maxLines: 4, 
                style: const TextStyle(fontSize: 15), 
                decoration: _inputStyle("Ej. Tengo experiencia en reparaciones...")
              ),
              const SizedBox(height: 24),

              _buildLabel("Tu precio (\$ MXN)"),
              _buildPriceField(priceCtrl),
              const SizedBox(height: 10),
              Text(
                "SUGERENCIA DEL CLIENTE: \$${service.basePrice.toStringAsFixed(0)} MXN", 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)
              ),
              
              const SizedBox(height: 35),
              
              Consumer(builder: (context, modalRef, _) {
                final status = modalRef.watch(serviceRequestProvider);
                
                return SizedBox(
                  width: double.infinity, height: 62,
                  child: ElevatedButton(
                    onPressed: status.isLoading ? null : () async {
                      final cleanPrice = double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0.0;
                      
                      if (descCtrl.text.trim().isEmpty || cleanPrice <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Indica un precio y un mensaje"), backgroundColor: Colors.orange));
                          return;
                      }

                      bool success = false;
                      if (isEditing) {
                        // TODO: Llama a tu función update en el provider (el PUT)
                        /* success = await modalRef.read(serviceRequestProvider.notifier).updateApplication(requestId, descCtrl.text.trim(), cleanPrice); */
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pendiente conectar el Provider PUT")));
                        success = true; // Simulación para que cierre
                      } else {
                        // El POST normal
                        success = await modalRef.read(serviceRequestProvider.notifier).applyToService(service.id, descCtrl.text.trim(), cleanPrice);
                      }

                      // ... dentro del ElevatedButton del modal ...
                      if (context.mounted && success) {
                          // 🚀 LA MAGIA: Invalidamos el provider de la lista de trabajos para que se refresque
                          modalRef.invalidate(workerJobsProvider); 

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? "✅ Propuesta actualizada" : "✅ Postulación enviada"), 
                                backgroundColor: const Color(0xFF10B981), 
                                behavior: SnackBarBehavior.floating
                              )
                          );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1BFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                    ),
                    child: status.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(isEditing ? "Guardar Cambios" : "Enviar Postulación", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                );
              }),
              
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text("Cancelar", style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w600, fontSize: 16))
                )
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    ),
  );
}

// =========================================================================
// WIDGETS DE UI REUTILIZABLES (LIMPIOS Y ORGANIZADOS)
// =========================================================================

Widget _buildPriceField(TextEditingController ctrl) {
  return TextFormField(
    controller: ctrl, 
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
    decoration: InputDecoration(
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 8), 
        child: Text("\$", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true, 
      fillColor: Colors.white, 
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
    ),
  );
}

Widget _buildLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF374151)))
  );
}

InputDecoration _inputStyle(String hint) {
  return InputDecoration(
    hintText: hint, 
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14), 
    filled: true, 
    fillColor: Colors.white, 
    contentPadding: const EdgeInsets.all(16), 
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)) 
  );
}