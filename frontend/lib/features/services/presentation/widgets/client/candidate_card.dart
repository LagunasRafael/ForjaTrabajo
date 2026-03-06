import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/services/domain/usecases/service_requests/accept_postulation_usecase.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_request_provider.dart';

class CandidateCard extends ConsumerStatefulWidget {
  final dynamic offer;
  final String serviceId;
  const CandidateCard({super.key, required this.offer, required this.serviceId});
  
  @override
  ConsumerState<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends ConsumerState<CandidateCard> {
  bool _showInput = false;

  @override
  Widget build(BuildContext context) {
    final isAccepting = ref.watch(isAcceptingProvider(widget.offer.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          _buildHeader(),
          _buildMessage(),
          _buildActions(isAccepting),
          if (_showInput) _buildCounterOfferInput(),
        ]
      ),
    );
  }

  Widget _buildHeader() {
    final imgUrl = widget.offer.authorImageUrl; 
    final name = widget.offer.workerName ?? "Trabajador";
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "U";

    return Row(
      children: [
        CircleAvatar(
          radius: 24, backgroundColor: const Color(0xFFF3F4F6),
          backgroundImage: (imgUrl != null && imgUrl.isNotEmpty) ? NetworkImage(imgUrl) : null,
          child: (imgUrl == null || imgUrl.isEmpty) ? Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 18)) : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
          child: Text("\$${widget.offer.proposedPrice?.toStringAsFixed(0) ?? '0'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        )
      ]
    );
  }

  Widget _buildMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12), padding: const EdgeInsets.all(12), width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
      child: Text("\"${widget.offer.description ?? 'Sin mensaje'}\"", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13)),
    );
  }

  Widget _buildActions(bool isAccepting) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)), 
          child: IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 20), onPressed: isAccepting ? null : () {}),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _btn("Contraoferta", const Color(0xFFEEF2FF), const Color(0xFF4F46E5), isAccepting ? null : () => setState(() => _showInput = !_showInput))
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.zero), 
            onPressed: isAccepting ? null : _handleAccept, 
            child: isAccepting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Aceptar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
          )
        ),
      ]
    );
  }

  Widget _btn(String lbl, Color bg, Color text, VoidCallback? onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: text, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.zero), 
      onPressed: onTap, child: Text(lbl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
    );
  }

  Widget _buildCounterOfferInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
        decoration: InputDecoration(
          prefixText: "\$ ", hintText: "00.00", filled: true, fillColor: Colors.white,
          suffixIcon: IconButton(icon: const Icon(Icons.send, color: Color(0xFF4F46E5)), onPressed: () => setState(() => _showInput = false)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        ),
      ),
    );
  }

  Future<void> _handleAccept() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Contratar?"), content: const Text("Al aceptar, el trabajo pasará a 'En Curso'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Volver")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)), child: const Text("Contratar", style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm != true) return;

    ref.read(isAcceptingProvider(widget.offer.id).notifier).state = true;
    final success = await ref.read(serviceRequestProvider.notifier).acceptWorker(widget.offer.id);
    ref.read(isAcceptingProvider(widget.offer.id).notifier).state = false;

    if (success && mounted) {
      await ref.refresh(myRequestsProvider.future); 
      ref.read(myRequestsTabProvider.notifier).state = 1;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Contratado"), backgroundColor: Color(0xFF10B981)));
    }
  }
}