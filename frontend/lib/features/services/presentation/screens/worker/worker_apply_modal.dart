import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_request_provider.dart';

// 1. FORMATEADOR DE PRECIO (Funcionalidad de derecha a izquierda)
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

void showWorkerApplyModal(BuildContext context, WidgetRef ref, ServiceEntity service) {
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: "0.00");

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Permite que el modal crezca según el contenido
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      // 👇 Manejo dinámico del teclado para evitar desbordamientos
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        // 👇 SingleChildScrollView es la clave para que no salga el error amarillo
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle superior
              Center(
                child: Container(
                  width: 45, height: 5,
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Text("Enviar Postulación", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              const Text("Completa los detalles de tu propuesta para este servicio.", 
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
              const SizedBox(height: 28),
              
              _buildLabel("Mensaje de propuesta"),
              TextField(
                controller: descCtrl, 
                maxLines: 4, 
                style: const TextStyle(fontSize: 15),
                decoration: _inputStyle("Ej. Tengo experiencia en reparaciones de PVC, puedo asistir hoy mismo por la tarde..."),
              ),
              const SizedBox(height: 24),

              _buildLabel("Tu precio (\$ MXN)"),
              _buildPriceField(priceCtrl),
              const SizedBox(height: 10),
              Text("SUGERENCIA DEL CLIENTE: \$${service.basePrice.toStringAsFixed(0)} MXN", 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
              
              const SizedBox(height: 35),
              
              // Botón Principal de Envío
              Consumer(builder: (context, modalRef, _) {
                final status = modalRef.watch(serviceRequestProvider);
                
                return SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: status.isLoading ? null : () async {
                      final cleanPrice = double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0.0;

                      if (descCtrl.text.trim().isEmpty || cleanPrice <= 0) {
                          _showErrorToast(context, "⚠️ Indica un precio y un mensaje");
                          return;
                      }

                      final success = await modalRef.read(serviceRequestProvider.notifier).applyToService(
                          service.id, 
                          descCtrl.text.trim(), 
                          cleanPrice
                      );

                      if (context.mounted && success) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Postulación enviada"), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating)
                          );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1BFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: status.isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Enviar Postulación", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                );
              }),
              
              // Botón Cancelar (Ajustado para que no cause error visual)
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text("Cancelar", 
                    style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ),
  );
}

// Widget de Precio idéntico a la imagen
Widget _buildPriceField(TextEditingController ctrl) {
  return TextFormField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      CurrencyInputFormatter(),
    ],
    // El texto es gris oscuro, no verde (solo el símbolo es verde)
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
    decoration: InputDecoration(
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 8),
        child: Text("\$", 
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981))), // Símbolo verde
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)
      ),
    ),
  );
}

// Estilo de los Labels
Widget _buildLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 10), 
  child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF374151)))
);

// Estilo de los Inputs generales
InputDecoration _inputStyle(String hint) => InputDecoration(
  hintText: hint, 
  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
  filled: true, 
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.all(16),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16), 
    borderSide: const BorderSide(color: Color(0xFFE5E7EB))
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16), 
    borderSide: const BorderSide(color: Color(0xFFE5E7EB))
  ),
);

void _showErrorToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
}