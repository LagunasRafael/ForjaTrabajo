import 'package:flutter/material.dart';

class Step2Location extends StatelessWidget {
  final TextEditingController addressCtrl;
  final TextEditingController priceCtrl;
  final VoidCallback onNext;

  const Step2Location({super.key, required this.addressCtrl, required this.priceCtrl, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("¿Dónde se realizará?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(image: NetworkImage('https://i.stack.imgur.com/vhoa0.jpg'), fit: BoxFit.cover, opacity: 0.3),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(top: 50, child: Icon(Icons.location_on, size: 50, color: Color(0xFFEF4444))),
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Row(children: [Icon(Icons.map, size: 16, color: Color(0xFF4F46E5)), SizedBox(width: 8), Text("Ajustar en el mapa", style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold))]),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text("Dirección detallada", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
          const SizedBox(height: 8),
          TextFormField(
            controller: addressCtrl,
            decoration: InputDecoration(hintText: "Ej: Calle Morelos #45", prefixIcon: const Icon(Icons.my_location), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200))),
          ),
          
          const SizedBox(height: 40),
          const Text("Presupuesto estimado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
            decoration: InputDecoration(
              prefixText: "\$ ",
              prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
              hintText: "0.00",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111827), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Siguiente", style: TextStyle(fontSize: 16, color: Colors.white)), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, color: Colors.white)]),
            ),
          )
        ],
      ),
    );
  }
}