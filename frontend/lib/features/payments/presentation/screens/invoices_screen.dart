import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/payment_provider.dart';
import '../../domain/entities/payment.dart';
import 'package:forja_trabajo/core/network/api_client.dart';
import 'package:dio/dio.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentHistoryAsync = ref.watch(paymentHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mis Facturas', 
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [],
      ),
      body: paymentHistoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (payments) {
          if (payments.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(paymentHistoryProvider),
              child: ListView(children: [_buildEmptyState()]),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(paymentHistoryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) => _InvoiceCard(payment: payments[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 20),
          const Text('No hay facturas aún', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Tus pagos completados aparecerán aquí.', 
            style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Payment payment;
  const _InvoiceCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    final isCompleted = payment.status.toLowerCase() == 'released' || 
                        payment.status.toLowerCase() == 'completed' ||
                        payment.status.toLowerCase() == 'paid';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showInvoiceDetail(context),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle_outline : Icons.history,
                          color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.serviceTitle ?? 'Factura #${payment.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              payment.serviceCategory ?? '',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(payment.date),
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${payment.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          _StatusTag(status: payment.status),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _showInvoiceDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvoiceDetailSheet(payment: payment),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;
  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color color = Colors.blue;
    String label = status;

    if (s == 'released' || s == 'completed' || s == 'paid') {
      color = const Color(0xFF16A34A);
      label = 'Pagado';
    } else if (s == 'held_in_escrow') {
      color = const Color(0xFFEA580C);
      label = 'En Garantía';
    } else if (s == 'refunded') {
      color = const Color(0xFFDC2626);
      label = 'Reembolsado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class InvoiceDetailSheet extends ConsumerStatefulWidget {
  final Payment payment;
  const InvoiceDetailSheet({required this.payment});

  @override
  ConsumerState<InvoiceDetailSheet> createState() => InvoiceDetailSheetState();
}

class InvoiceDetailSheetState extends ConsumerState<InvoiceDetailSheet> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(
        '/payments/invoice/${widget.payment.id}/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/factura_${widget.payment.id.substring(0, 8).toUpperCase()}.pdf');
      await file.writeAsBytes(response.data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF guardado en: ${file.path}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalle de Factura',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 24),
                    if (widget.payment.serviceTitle != null) ...[
                      _buildDetailRow('Servicio', widget.payment.serviceTitle!),
                      if (widget.payment.serviceCategory != null)
                        _buildDetailRow('Categoría', widget.payment.serviceCategory!),
                      if (widget.payment.serviceDescription != null && widget.payment.serviceDescription!.isNotEmpty)
                        _buildDetailRow('Descripción', widget.payment.serviceDescription!, maxLines: 3),
                      const Divider(height: 24),
                    ],
                    _buildDetailRow('Factura', '#${widget.payment.id.substring(0, 8).toUpperCase()}'),
                    _buildDetailRow('ID de Transacción', '#${widget.payment.id.substring(0, 8).toUpperCase()}'),
                    _buildDetailRow('Fecha', DateFormat('dd MMMM, yyyy HH:mm').format(widget.payment.date)),
                    _buildDetailRow('Método de Pago', widget.payment.paymentMethod.toUpperCase()),
                    _buildDetailRow('Estado', widget.payment.status.toUpperCase()),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pagado', style: TextStyle(fontSize: 18, color: Color(0xFF64748B))),
                      Text('\$${widget.payment.amount.toStringAsFixed(2)} MXN',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF6366F1))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadPdf,
                      icon: _isDownloading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        _isDownloading ? 'Descargando...' : 'Descargar PDF',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w500),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ],
      ),
    );
  }
}
