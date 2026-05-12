import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- TUS IMPORTS ---
import '../../../../payments/data/models/payment_model.dart';
import '../../../../payments/presentation/providers/payment_provider.dart';
import '../../../../payments/presentation/providers/payment_state.dart';

// Provider local para la selección del método de pago
final selectedMethodProvider = StateProvider<String>((ref) => 'visa_4242');

class CheckoutScreen extends ConsumerWidget {
  final dynamic contract; // Objeto que trae id y amount
  const CheckoutScreen({super.key, required this.contract});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentProvider);
    final selectedMethod = ref.watch(selectedMethodProvider);

    // Listener para el éxito o error del pago
    ref.listen<PaymentState>(paymentProvider, (previous, next) {
      if (next is PaymentSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pago Procesado!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else if (next is PaymentError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.message}'), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Checkout Payment', 
          style: TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. IMAGEN SUPERIOR CON DATOS DEL CONTRATO ---
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?q=80&w=500'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("CONTRACT #${contract.id.toString().length > 8 ? contract.id.toString().substring(0, 8) : contract.id}", 
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Website Design\nService", 
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1)),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Total Amount", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text("\$${contract.amount.toStringAsFixed(2)}", 
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            const Text("Payment Method", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
            const SizedBox(height: 15),

            // --- 2. MÉTODOS DE PAGO (RADIO SELECTION) ---
            _buildMethodTile(ref, 
              id: 'visa_4242', title: "Visa ending in 4242", subtitle: "Expires 12/25", 
              iconAsset: Icons.credit_card, isSelected: selectedMethod == 'visa_4242'),
            _buildMethodTile(ref, 
              id: 'mastercard_8899', title: "Mastercard ending in 8899", subtitle: "Expires 08/24", 
              iconAsset: Icons.credit_card_outlined, isSelected: selectedMethod == 'mastercard_8899'),
            _buildMethodTile(ref, 
              id: 'apple_pay', title: "Apple Pay", subtitle: "Default wallet", 
              iconAsset: Icons.apple, isSelected: selectedMethod == 'apple_pay'),

            const SizedBox(height: 25),

            // --- 3. RESUMEN DE PAGO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB), // Gris claro del diseño
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildPriceRow("Subtotal", "\$${contract.amount.toStringAsFixed(2)}"),
                  _buildPriceRow("Tax (0%)", "\$0.00"),
                  const Divider(height: 30, color: Color(0xFFEEF0F2)),
                  _buildPriceRow("Total", "\$${contract.amount.toStringAsFixed(2)}", isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 4. BOTÓN DE ACCIÓN CON LÓGICA ---
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: paymentState is PaymentLoading 
                  ? null 
                  : () {
                      final newPayment = PaymentModel(
                        id: '', 
                        contractId: contract.id.toString(),
                        amount: (contract.amount as num).toDouble(),
                        status: 'pending',
                        date: DateTime.now(),
                        paymentMethod: selectedMethod, 
                      );
                      ref.read(paymentProvider.notifier).pay(newPayment);
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B4DFF), // Púrpura exacto
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: paymentState is PaymentLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Pagar Ahora", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
              ),
            ),
            
            // Footer de seguridad
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFF8A8D94)),
                  SizedBox(width: 5),
                  Text("SECURE ENCRYPTED PAYMENT", 
                    style: TextStyle(fontSize: 10, color: Color(0xFF8A8D94), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para cada método de pago
  Widget _buildMethodTile(WidgetRef ref, {
    required String id, required String title, required String subtitle, 
    required IconData iconAsset, required bool isSelected
  }) {
    return GestureDetector(
      onTap: () => ref.read(selectedMethodProvider.notifier).state = id,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B4DFF) : const Color(0xFFF1F4F9), 
            width: 2
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconAsset, color: const Color(0xFF1A1C1E)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C1E))),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8D94))),
                ],
              ),
            ),
            // Radio button personalizado
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF7B4DFF) : const Color(0xFFD1D5DB),
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row para el desglose de precios
  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: isTotal ? const Color(0xFF1A1C1E) : const Color(0xFF8A8D94), 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 16 : 14
          )),
          Text(value, style: TextStyle(
            color: isTotal ? const Color(0xFF7B4DFF) : const Color(0xFF1A1C1E), 
            fontWeight: FontWeight.bold, 
            fontSize: isTotal ? 20 : 14
          )),
        ],
      ),
    );
  }
}