import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/service_entity.dart';
import '../../providers/category_provider.dart';
import '../../providers/service_list_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart'; 

// 👇 Importamos nuestras nuevas pantallas divididas
import 'create_service_steps/step1_details.dart';
import 'create_service_steps/step2_location.dart';
import 'create_service_steps/step3_summary.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus(); 
    if (_currentStep == 0 && (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _selectedCategoryId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena los datos y selecciona una categoría')));
      return;
    } else if (_currentStep == 1 && (_addressCtrl.text.isEmpty || _priceCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa tu dirección y un presupuesto')));
      return;
    }

    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _submitFinal() async {
    final authState = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final realToken = prefs.getString('token');

    if (realToken == null) return;

    final newService = ServiceEntity(
      id: '', 
      title: _titleCtrl.text.trim(),
      summary: _descCtrl.text.length > 50 ? "${_descCtrl.text.substring(0, 50)}..." : _descCtrl.text, 
      description: _descCtrl.text.trim(),
      basePrice: double.tryParse(_priceCtrl.text) ?? 0.0,
      categoryId: _selectedCategoryId!,
      clientId: authState.user?.id ?? '', 
      exactAddress: _addressCtrl.text.trim(),
      latitude: authState.user?.latitude, 
      longitude: authState.user?.longitude,
      status: JobStatus.open,
      isActive: true,
      createdAt: DateTime.now(),
    );

    ref.read(serviceControllerProvider.notifier).createService(newService, realToken);
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(serviceControllerProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    ref.listen(serviceControllerProvider, (prev, next) {
      if (!next.isLoading && !next.hasError && next.hasValue) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Servicio publicado con éxito!')));
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => _currentStep > 0 ? { _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut), setState(() => _currentStep--) } : Navigator.pop(context)),
        title: const Text("Publicar Servicio", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)), centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white, padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("PASO ${_currentStep + 1} DE 3", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w900, fontSize: 12)), Text(_currentStep == 0 ? "Detalles Básicos" : _currentStep == 1 ? "Ubicación" : "Resumen", style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 14),
                Row(children: [Expanded(child: _buildProgressLine(_currentStep >= 0)), const SizedBox(width: 8), Expanded(child: _buildProgressLine(_currentStep >= 1)), const SizedBox(width: 8), Expanded(child: _buildProgressLine(_currentStep >= 2))])
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController, physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1Details(titleCtrl: _titleCtrl, descCtrl: _descCtrl, selectedCategoryId: _selectedCategoryId, categoriesAsync: categoriesAsync, onCategoryChanged: (id) => setState(() => _selectedCategoryId = id), onNext: _nextStep),
                Step2Location(addressCtrl: _addressCtrl, priceCtrl: _priceCtrl, onNext: _nextStep),
                Step3Summary(title: _titleCtrl.text, desc: _descCtrl.text, address: _addressCtrl.text, price: _priceCtrl.text, categoryId: _selectedCategoryId, categoriesAsync: categoriesAsync, isLoading: creationState.isLoading, onSubmit: _submitFinal, onEdit: () { _pageController.jumpToPage(0); setState(() => _currentStep = 0); }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) => AnimatedContainer(duration: const Duration(milliseconds: 300), height: 6, decoration: BoxDecoration(color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3)));
}