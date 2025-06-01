import 'package:flutter/material.dart';

class LaborFormPage extends StatefulWidget {
  const LaborFormPage({super.key});

  @override
  State<LaborFormPage> createState() => _LaborFormPageState();
}

class _LaborFormPageState extends State<LaborFormPage> {
  String? selectedArea;
  String? selectedExperience;
  String? selectedWorkType;

  final List<String> areas = ['Albañilería', 'Electricista', 'Plomero', 'Mecánico'];
  final List<String> experiences = ['1 año', '3 años', '6 años'];
  final List<String> workTypes = ['Sí', 'No'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Encabezado mejorado
          _buildHeader(context),
          
          // Cuerpo del formulario optimizado
          Expanded(
            child: ListView(  // Cambiado de SingleChildScrollView a ListView
              padding: const EdgeInsets.all(16),
              children: [
                _buildQuestionSection(
                  title: '¿Cuál es tu área laboral?',
                  options: areas,
                  value: selectedArea,
                  onChanged: (value) => setState(() => selectedArea = value),
                ),
                
                _buildQuestionSection(
                  title: '¿Cuántos años de experiencia tienes en este oficio?',
                  options: experiences,
                  value: selectedExperience,
                  onChanged: (value) => setState(() => selectedExperience = value),
                ),
                
                _buildQuestionSection(
                  title: '¿Trabajas por tu cuenta o en una empresa/grupo?',
                  options: workTypes,
                  value: selectedWorkType,
                  onChanged: (value) => setState(() => selectedWorkType = value),
                ),
                
                const SizedBox(height: 30),
                
                _buildSubmitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para el encabezado
  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 140,
          color: Colors.blue,
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Cuéntanos sobre ti',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  // Widget reusable para secciones de preguntas
  Widget _buildQuestionSection({
    required String title,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...options.map((option) => RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: value,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,  // Reduce espacio interno
          dense: true,  // Hace los tiles más compactos
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  // Widget para el botón de enviar
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          debugPrint("Área seleccionada: $selectedArea");
          debugPrint("Experiencia: $selectedExperience");
          debugPrint("Tipo de trabajo: $selectedWorkType");
          Navigator.pushNamed(context, '/homescreen');
        },
        child: const Text('Siguiente'),
      ),
    );
  }
}