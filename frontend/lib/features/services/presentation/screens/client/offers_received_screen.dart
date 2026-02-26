import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import '../../providers/service_offers_provider.dart';

// 👇 TU RUTA CORRECTA DE PROVIDERS
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart'; 

class OffersReceivedScreen extends ConsumerWidget {
  final ServiceEntity service;
  const OffersReceivedScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersListProvider(service.id));
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Postulantes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
          Text(service.title.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (offers) {
          if (offers.isEmpty) return const Center(child: Text("Sin postulaciones", style: TextStyle(color: Colors.grey, fontSize: 18)));
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

  Future<void> _handleAccept() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Contratar?"),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
    );

    try {
      final success = await widget.ref.read(acceptOfferProvider.notifier).acceptWorker(widget.offer.id);

      if (success && mounted) {
        widget.ref.invalidate(myRequestsProvider);
        widget.ref.invalidate(offersListProvider(widget.serviceId));

        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop(); 
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Postulante aceptado"), 
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2), 
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
    final acceptState = widget.ref.watch(acceptOfferProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 26, child: Text((widget.offer.workerName ?? "U").substring(0,1).toUpperCase())),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.offer.workerName ?? "Trabajador", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Text("\$${widget.offer.proposedPrice?.toStringAsFixed(0) ?? '0'}", style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        Text("\"${widget.offer.description ?? 'Sin mensaje'}\"", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(children: [
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
          Expanded(child: ElevatedButton(
            onPressed: () => setState(() => _showInput = !_showInput),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEEF2FF), elevation: 0),
            child: const Text("Contraoferta", style: TextStyle(color: Color(0xFF4F46E5))),
          )),
          const SizedBox(width: 8),
          Expanded(child: acceptState.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _handleAccept, 
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                child: const Text("Aceptar", style: TextStyle(color: Colors.white)),
              )
          ),
        ]),
        if (_showInput) _buildCounterOfferInput(),
      ]),
    );
  }

  Widget _buildCounterOfferInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: "Monto..."))),
        IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: () => setState(() => _showInput = false)),
      ]),
    );
  }
}