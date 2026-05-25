import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class WorkerDragHandle extends StatelessWidget {
  const WorkerDragHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 45, height: 5, margin: const EdgeInsets.only(bottom: 25), 
      decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(10))
    )
  );
}

class WorkerModalHeader extends StatelessWidget {
  final bool isEditing;
  const WorkerModalHeader({super.key, required this.isEditing});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        isEditing ? "Editar Propuesta" : "Enviar Postulación", 
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))
      ),
      const SizedBox(height: 8),
      const Text("Modifica tu tarifa o mensaje para el cliente.", style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
    ],
  );
}

class WorkerFormLabel extends StatelessWidget {
  final String text;
  const WorkerFormLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF374151)))
  );
}

class WorkerDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  const WorkerDescriptionField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, 
    maxLines: 4, 
    style: const TextStyle(fontSize: 15), 
    decoration: workerInputStyle("Agrega una breve descripción de tu trabajo...")
  );
}

class WorkerPriceField extends StatelessWidget {
  final TextEditingController controller;
  const WorkerPriceField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller, 
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
    ],
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
    decoration: workerInputStyle("").copyWith(
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 8), 
        child: Text("\$", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    ),
  );
}

class WorkerSubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isEditing;
  final VoidCallback onPressed;

  const WorkerSubmitButton({
    super.key, required this.isLoading, required this.isEditing, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 62,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E1BFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
      ),
      child: isLoading 
        ? const CircularProgressIndicator(color: Colors.white) 
        : Text(isEditing ? "Guardar Cambios" : "Enviar Postulación", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
    ),
  );
}

InputDecoration workerInputStyle(String hint) => InputDecoration(
  hintText: hint, 
  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14), 
  filled: true, contentPadding: const EdgeInsets.all(16), 
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)) 
);