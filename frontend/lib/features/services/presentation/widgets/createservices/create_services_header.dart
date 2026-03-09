import 'package:flutter/material.dart';

class CreateServiceHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const CreateServiceHeader({
    super.key, 
    required this.currentStep,
    this.totalSteps = 3,
    this.stepTitles = const ["Detalles Básicos", "Ubicación", "Resumen"],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PASO ${currentStep + 1} DE $totalSteps", 
                style: const TextStyle(
                  color: Color(0xFF4F46E5), 
                  fontWeight: FontWeight.w900, 
                  fontSize: 12,
                )
              ), 
              Text(
                stepTitles[currentStep], 
                style: TextStyle(
                  color: Colors.grey[500], 
                  fontSize: 13, 
                  fontWeight: FontWeight.w500,
                )
              )
            ],
          ),
          const SizedBox(height: 14),
          // 🚀 Generación dinámica de líneas basada en totalSteps
          Row(
            children: List.generate(totalSteps, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < (totalSteps - 1) ? 8 : 0),
                child: _buildProgressLine(currentStep >= i),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(3)
      ),
    );
  }
}