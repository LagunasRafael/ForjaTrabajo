import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import '../../providers/service_offers_provider.dart';
import '../shared/contracts_screen.dart';

class OffersReceivedScreen extends ConsumerWidget {
  final ServiceEntity service;
  const OffersReceivedScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersListProvider(service.id));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Postulaciones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black)),
          Text(service.title.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
        ]),
      ),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (offers) {
          if (offers == null || offers.isEmpty) {
            return const Center(child: Text("Aún no hay postulaciones", style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (c, i) => _CandidateCard(offer: offers[i], ref: ref, serviceId: service.id),
          );
        },
      ),
    );
  }
}

class _CandidateCard extends StatefulWidget {
  final dynamic offer;
  final WidgetRef ref;
  final String serviceId;
  const _CandidateCard({required this.offer, required this.ref, required this.serviceId});
  
  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  bool _showInput = false;
  final _ctrl = TextEditingController();

  // 👇 Lógica de Aceptar (Ajustada para volver a la pestaña 0)
  Future<void> _handleAccept() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Contratar?"),
        content: const Text("¿Estás seguro de contratar a este postulante?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text("Sí, contratar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
    );

    try {
      final success = await widget.ref.read(acceptOfferProvider.notifier).acceptWorker(widget.offer.id);

      if (success && mounted) {
        // Refrescar las listas
        widget.ref.invalidate(myRequestsProvider);
        widget.ref.invalidate(offersListProvider(widget.serviceId));

        // 👇 CAMBIO AQUÍ: Regresamos a la pestaña "Abiertos" (Índice 0)
        widget.ref.read(myRequestsTabProvider.notifier).state = 0;

        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          Navigator.of(context).pop(); // Quita Loader
          Navigator.of(context).pop(); // Regresa de pantalla
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Postulante aceptado"), 
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF10B981),
            )
          );
        }
      } else {
        if (mounted) Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al aceptar")));
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      print("🚨 Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👇 SE RESPETA TODA TU LÓGICA DE IMÁGENES
    final String? imgUrl = widget.offer.authorImageUrl; 
    
    String inicial = "U";
    final nombreWorker = widget.offer.workerName;
    if (nombreWorker != null && nombreWorker.toString().trim().isNotEmpty) {
      inicial = nombreWorker.toString().trim()[0].toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 24, 
            backgroundColor: const Color(0xFFF3F4F6),
            // Mantenemos tus NetworkImages intactas
            backgroundImage: (imgUrl != null && imgUrl.isNotEmpty) ? NetworkImage(imgUrl) : null,
            child: (imgUrl == null || imgUrl.isEmpty) ? Text(inicial, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 18)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(nombreWorker ?? "Trabajador", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
            child: Text("\$${widget.offer.proposedPrice?.toStringAsFixed(0) ?? '0'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          )
        ]),
        
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12), 
          padding: const EdgeInsets.all(12), 
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: Text("\"${widget.offer.description ?? 'Sin mensaje'}\"", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13)),
        ),
        
        Row(children: [
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)), 
            child: IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 20), onPressed: () {}),
          ),
          const SizedBox(width: 8),
          Expanded(child: _actionBtn("Contraoferta", const Color(0xFFEEF2FF), const Color(0xFF4F46E5), () => setState(() => _showInput = !_showInput))),
          const SizedBox(width: 8),
          Expanded(child: _actionBtn("Aceptar", const Color(0xFF10B981), Colors.white, _handleAccept)),
        ]),
        
        if (_showInput) _buildPriceField(),
      ]),
    );
  }

  Widget _buildPriceField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
        decoration: InputDecoration(
          prefixText: "\$ ", 
          hintText: "00.00", 
          filled: true, 
          fillColor: Colors.white,
          suffixIcon: IconButton(icon: const Icon(Icons.send, color: Color(0xFF4F46E5)), onPressed: () => setState(() => _showInput = false)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        ),
      ),
    );
  }

  Widget _actionBtn(String l, Color b, Color f, VoidCallback o) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: b, 
      foregroundColor: f, 
      elevation: 0, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
      padding: EdgeInsets.zero
    ), 
    onPressed: o, 
    child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
  );
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '00.00', selection: TextSelection.collapsed(offset: 4));
    double value = double.parse(digitsOnly) / 100;
    String formatted = value.toStringAsFixed(2);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}