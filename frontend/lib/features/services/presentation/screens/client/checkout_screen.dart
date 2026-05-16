import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../payments/presentation/providers/payment_provider.dart';
import '../../../../payments/presentation/providers/payment_state.dart';
import '../../providers/service_request_provider.dart';
import '../../providers/nav_providers.dart';

// Provider local para la selección del método de pago
final selectedMethodProvider = StateProvider<String>((ref) => 'visa_4242');

class CheckoutScreen extends ConsumerStatefulWidget {
  final dynamic offer;
  final String? serviceId;
  final String? jobId;
  final double? amount;

  const CheckoutScreen({
    super.key,
    this.offer,
    this.serviceId,
    this.jobId,
    this.amount,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    
    try {
      final paymentNotifier = ref.read(paymentProvider.notifier);
      final serviceNotifier = ref.read(serviceRequestProvider.notifier);
      
      String? jobId = widget.jobId;
      double? amount = widget.amount;

      // Si no tenemos jobId, significa que estamos contratando en este momento
      if (jobId == null && widget.offer != null) {
        amount = (widget.offer.proposedPrice as num?)?.toDouble() ?? 0.0;
        final acceptResult = await serviceNotifier.acceptWorker(widget.offer.id);
        if (acceptResult == null || acceptResult['job_id'] == null) {
          throw Exception("Error al procesar la contratación.");
        }
        jobId = acceptResult['job_id'];
      }

      if (jobId == null || amount == null) {
        throw Exception("Faltan datos para procesar el pago.");
      }

      // 2. Crear el PaymentIntent en el backend
      final intentData = await paymentNotifier.createIntent(jobId, amount);
      final clientSecret = intentData['client_secret'];
      final paymentIntentId = intentData['payment_intent_id'];

      // 3. Configurar el Payment Sheet de Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Forja Trabajo',
          style: ThemeMode.light,
        ),
      );

      // 4. Mostrar el Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 5. Confirmar en el backend que el pago fue autorizado (Escrow)
      await paymentNotifier.confirmEscrow(paymentIntentId);

      // 6. Éxito total
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pago en garantía retenido con éxito'), backgroundColor: Colors.green),
        );
        
        // Redirigir a la pestaña de "Mis Trabajos - En Curso"
        ref.read(clientNavProvider.notifier).state = 3;
        ref.read(myRequestsTabProvider.notifier).state = 1; // 1 = "En curso"
        
        Navigator.pushNamedAndRemoveUntil(context, '/client_home', (route) => false);
      }
    } catch (e) {
      debugPrint("🚨 Error en Checkout: $e");
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago cancelado o fallido: ${e.error.localizedMessage}'), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMethod = ref.watch(selectedMethodProvider);
    final amount = widget.amount ?? (widget.offer != null ? (widget.offer.proposedPrice as num).toDouble() : 0.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Confirmar y Pagar', 
          style: TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. RESUMEN DEL SERVICIO ---
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1581094794329-c8112a89af12?q=80&w=500'),
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
                    Text("OFERTA DE: ${widget.offer.workerName?.toUpperCase() ?? "TRABAJADOR"}", 
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    const Text("Contratación de\nServicio Profesional", 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.1)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            const Text("Método de Pago", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
            const SizedBox(height: 15),

            // --- 2. MÉTODOS DE PAGO (Visual) ---
            _buildMethodTile(ref, 
              id: 'stripe_card', title: "Tarjeta de Crédito / Débito", subtitle: "Seguro mediante Stripe", 
              iconAsset: Icons.credit_card, isSelected: selectedMethod == 'stripe_card'),

            const SizedBox(height: 25),

            // --- 3. RESUMEN DE PAGO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildPriceRow("Monto de la Oferta", "\$${amount.toStringAsFixed(2)}"),
                  _buildPriceRow("Tarifa de Servicio", "\$0.00"),
                  const Divider(height: 30, color: Color(0xFFEEF0F2)),
                  _buildPriceRow("Total a Retener", "\$${amount.toStringAsFixed(2)}", isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 4. BOTÓN DE ACCIÓN ---
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B4DFF), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Confirmar y Pagar", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
              ),
            ),
            
            // Footer de seguridad
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Color(0xFF8A8D94)),
                      SizedBox(width: 5),
                      Text("PAGO EN GARANTÍA PROTEGIDO", 
                        style: TextStyle(fontSize: 10, color: Color(0xFF8A8D94), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tu dinero se retiene de forma segura y solo se libera al trabajador cuando confirmes que el trabajo está terminado.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A8D94)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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