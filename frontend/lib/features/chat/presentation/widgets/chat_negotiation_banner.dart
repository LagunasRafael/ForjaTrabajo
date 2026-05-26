import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/offer_bottom_sheet.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/core/utils/formatters.dart';

class ChatNegotiationBanner extends ConsumerWidget {
  final String amount;
  final String conversationId;

  const ChatNegotiationBanner({
    super.key,
    required this.amount,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4B5FD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ESTADO DE NEGOCIACIÓN", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 9, fontWeight: FontWeight.w900)),
              Text("Oferta actual: \$${Formatters.formatCurrency(amount)} MXN", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              final scaffoldContext = context;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => OfferBottomSheet(
                  onSendOffer: (newAmount) async {
                    try {
                      await ref.read(chatProvider(conversationId).notifier).sendOffer(newAmount);
                      if (scaffoldContext.mounted) {
                        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                          SnackBar(
                            content: Text("✅ Contraoferta de \$${newAmount.toStringAsFixed(0)} enviada"),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    } catch (e) {
                      if (scaffoldContext.mounted) {
                        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                          SnackBar(content: Text("🚨 Error: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 14, color: Colors.white),
            label: const Text("Modificar", style: TextStyle(fontSize: 12, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
