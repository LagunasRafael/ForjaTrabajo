import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import '../../providers/service_offers_provider.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/candidate_card.dart';

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
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
        error: (e, s) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
        data: (offers) {
          if (offers == null || offers.isEmpty) {
            return const Center(child: Text("Aún no hay postulaciones", style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            // 🚀 LLAMAMOS A LA TARJETA SEPARADA
            itemBuilder: (context, index) => CandidateCard(
              offer: offers[index], 
              serviceId: service.id
            ),
          );
        },
      ),
    );
  }
}