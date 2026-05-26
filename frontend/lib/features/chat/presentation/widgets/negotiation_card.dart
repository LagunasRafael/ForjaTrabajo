import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/domain/entities/message_entity.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/core/utils/formatters.dart';

class NegotiationCard extends ConsumerStatefulWidget {
  final MessageEntity message; // 👈 Entidad correcta
  final bool isMe;
  final bool isClient;
  final String conversationId; 
  final String? serviceImageUrl;
  final bool isProcessed; 
  final String? time;
  final String? myRole; // 👈 Agregado

  const NegotiationCard({
    super.key, 
    required this.message, 
    required this.isMe,
    required this.isClient,
    required this.conversationId,
    this.serviceImageUrl,
    this.isProcessed = false, 
    this.time,
    this.myRole, // 👈 Agregado
  });

  @override
  ConsumerState<NegotiationCard> createState() => _NegotiationCardState();
}

class _NegotiationCardState extends ConsumerState<NegotiationCard> {
  String? _localAction; 
  bool _isLoading = false;

  Future<void> _handleResponse(String action) async {
    setState(() => _isLoading = true);
    
    await ref.read(chatProvider(widget.conversationId).notifier)
             .respondOffer(widget.message.id, action); // 👈 Ahora usa .id
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _localAction = action; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // La lógica universal: si YO lo mandé, es mi tarjeta (derecha/clara), 
    // si lo recibí, es la tarjeta del otro (izquierda/oscura).
    return widget.isMe 
        ? _buildMyCard() 
        : _buildTheirCard();
  }

  // Anterior _buildClientCard (ahora genérico para MI mensaje)
  Widget _buildMyCard() {
    final amount = Formatters.formatCurrency(widget.message.content);
    final String status = widget.message.status.toLowerCase();
    String finalStatus = _localAction ?? status;
    if (widget.isProcessed && finalStatus == 'pending') {
      finalStatus = 'withdrawn';
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4, left: 8, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: _clientCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, 
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "CONTRAOFERTA", 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 11, 
                    color: Color(0xFF4F46E5), 
                    letterSpacing: 1.2
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  "\$$amount MXN", 
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w900, 
                    color: Theme.of(context).colorScheme.onSurface,
                  )
            ),
            const SizedBox(height: 12),
                _buildClientStatusRow(), 
                if (finalStatus == 'pending') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : () => _handleResponse('withdraw'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLoading 
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                            : const Icon(Icons.remove_circle_outline, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        const Text(
                          "Retirar oferta",
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.time != null)
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 16),
              child: Text(
                widget.time!,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration _clientCardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(4), 
    ),
    border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)), 
    boxShadow: [
      BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))
    ],
  );

  Widget _buildClientStatusRow() {
    final String status = widget.message.status.toLowerCase(); // 👈 Ahora usa .status
    String finalStatus = _localAction ?? status;
    
    if (widget.isProcessed && finalStatus == 'pending') {
      finalStatus = 'withdrawn';
    }

    Color color;
    String text;
    IconData icon;

    if (finalStatus == 'accept' || finalStatus == 'accepted') {
      color = const Color(0xFF10B981); 
      text = "Aceptada";
      icon = Icons.check_circle_outline;
    } else if (finalStatus == 'reject' || finalStatus == 'rejected' || finalStatus == 'withdrawn') {
      color = Colors.grey.shade500; 
      text = "Retirada";
      icon = Icons.history;
    } else {
      color = const Color(0xFFF59E0B); 
      text = "Esperando respuesta...";
      icon = Icons.access_time;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Anterior _buildWorkerCard (ahora genérico para mensaje RECIBIDO)
  Widget _buildTheirCard() {
    final String status = widget.message.status.toLowerCase(); // 👈 Ahora usa .status
    final bool alreadyProcessed = widget.isProcessed || status != 'pending' || _localAction != null;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWorkerImageHeader(),
            const SizedBox(height: 12),
            
            if (widget.time != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  widget.time!,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ),

            alreadyProcessed ? _buildProcessedLabel() : _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerImageHeader() {
    final amount = Formatters.formatCurrency(widget.message.content);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1B4B), 
            Color(0xFF4F46E5), 
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3), 
            blurRadius: 12, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.handshake_rounded, 
              size: 160,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "NUEVA NOTIFICACIÓN", 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 10, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 1.2
                  )
                ),
                const SizedBox(height: 12),
                
                const Text(
                  "CONTRAOFERTA\nRECIBIDA", 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    height: 1.2 
                  )
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        "\$$amount MXN", 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 28, 
                          fontWeight: FontWeight.w900
                        )
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_outlined, 
                        color: Colors.white, 
                        size: 26
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            label: "Aceptar Oferta", 
            icon: Icons.check_circle, 
            color: const Color(0xFF10B981), 
            action: 'accept'
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildButton(
            label: "Rechazar", 
            icon: Icons.cancel, 
            color: const Color(0xFFEF4444), 
            action: 'reject'
          ),
        ),
      ],
    );
  }

  Widget _buildButton({required String label, required IconData icon, required Color color, required String action}) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () => _handleResponse(action),
      icon: _isLoading && action == 'accept'
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildProcessedLabel() {
    final String status = widget.message.status.toLowerCase(); // 👈 Ahora usa .status
    String finalStatus = _localAction ?? status;
    
    if (widget.isProcessed && finalStatus == 'pending') {
      finalStatus = 'withdrawn';
    }

    Color bgColor;
    Color contentColor;
    String label;
    IconData icon;

    if (finalStatus == 'accept' || finalStatus == 'accepted') {
      bgColor = const Color(0xFFD1FAE5);
      contentColor = const Color(0xFF065F46);
      label = "OFERTA ACEPTADA";
      icon = Icons.check_circle;
    } else {
      bgColor = Colors.grey.shade200;
      contentColor = Colors.grey.shade600;
      label = "OFERTA RETIRADA";
      icon = Icons.history;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: contentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: contentColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: contentColor, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ],
      ),
    );
  }
}