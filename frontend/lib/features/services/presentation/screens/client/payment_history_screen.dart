import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- TUS IMPORTS (Asegúrate de que las rutas sean correctas) ---
import '../../../../payments/domain/entities/payment.dart';
import '../../../../payments/presentation/providers/payment_provider.dart';

final paymentFilterProvider = StateProvider<String>((ref) => 'All');

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentHistoryAsync = ref.watch(paymentHistoryProvider);
    final selectedFilter = ref.watch(paymentFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Payment History', 
          style: TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(ref, selectedFilter),
          Expanded(
            child: paymentHistoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7B4DFF))),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (payments) {
                // LÓGICA DE FILTRADO CON ALIAS PARA "PAID"
                final filteredList = payments.where((payment) {
                  if (selectedFilter == 'All') return true;
                  final pStatus = payment.status.toLowerCase().trim();
                  final filter = selectedFilter.toLowerCase().trim();

                  if (filter == 'paid') {
                    return pStatus == 'paid' || pStatus == 'completed' || pStatus == 'success';
                  }
                  return pStatus == filter;
                }).toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState(selectedFilter);
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(paymentHistoryProvider),
                  color: const Color(0xFF7B4DFF),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) => _PaymentListItem(payment: filteredList[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(WidgetRef ref, String currentFilter) {
    final filters = ['All', 'Paid', 'Pending', 'Cancelled'];
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) ref.read(paymentFilterProvider.notifier).state = filter;
              },
              selectedColor: const Color(0xFF1A1C1E),
              backgroundColor: const Color(0xFFF1F4F9),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4A4D55),
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No hay pagos en: $filter', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// --- CLASES PRIVADAS (ESTO ES LO QUE TE FALTABA PARA EL ERROR DE LA CAPTURA) ---

class _PaymentListItem extends StatelessWidget {
  final Payment payment;
  const _PaymentListItem({required this.payment});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F4F9))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F0FF), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: const Icon(Icons.videocam_outlined, color: Color(0xFF7B4DFF), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$${payment.amount.toStringAsFixed(2)}', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('ID: #${payment.id.toString().substring(0, 6)} • ${dateFormat.format(payment.date).toUpperCase()}', 
                  style: const TextStyle(color: Color(0xFF8A8D94), fontSize: 12)),
              ],
            ),
          ),
          _StatusBadge(status: payment.status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color color = Colors.orange;
    String text = 'Pending';

    if (s == 'paid' || s == 'completed' || s == 'success') {
      color = const Color(0xFF34C759);
      text = 'Paid';
    } else if (s == 'cancelled') {
      color = const Color(0xFFFF3B30);
      text = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // ACTUALIZADO PARA EVITAR EL WARNING DE DEPRECIACIÓN
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}