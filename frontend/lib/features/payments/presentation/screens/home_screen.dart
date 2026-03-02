import 'package:flutter/material.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/checkout_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/payment_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Pruebas')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Probar Pago (Checkout)'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      // SOLUCIÓN: Creamos un objeto rápido con los datos que espera la pantalla
                      contract: _DummyContract(
                        id: "1138c31c-8053-4bca-bc85-184647991fc3", 
                        amount: 2500.0
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Ver Historial'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Esta pequeña clase ayuda a que el CheckoutScreen no falle al leer .id o .amount
class _DummyContract {
  final String id;
  final double amount;
  _DummyContract({required this.id, required this.amount});
}