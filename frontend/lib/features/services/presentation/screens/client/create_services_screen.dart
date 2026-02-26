import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/service_entity.dart';
import '../../providers/category_provider.dart';
import '../../providers/service_list_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart'; 

import 'create_service_steps/step1_details.dart';
import 'create_service_steps/step2_location.dart';
import 'create_service_steps/step3_summary.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  final ServiceEntity? serviceToEdit;

  const CreateServiceScreen({super.key, this.serviceToEdit});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Declaramos los controladores
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _priceCtrl;
  
  String? _selectedCategoryId;

  bool get _isEditing => widget.serviceToEdit != null;

  @override
  void initState() {
    super.initState();
    // 🔧 INICIALIZACIÓN ROBUSTA: 
    // Si hay servicio para editar, usamos sus datos. Si no, cadena vacía.
    
    _titleCtrl = TextEditingController(text: widget.serviceToEdit?.title ?? '');
    _descCtrl = TextEditingController(text: widget.serviceToEdit?.description ?? '');
    _addressCtrl = TextEditingController(text: widget.serviceToEdit?.exactAddress ?? '');
    
    // El precio hay que convertirlo a String con cuidado
    _priceCtrl = TextEditingController(
      text: (widget.serviceToEdit?.basePrice != null && widget.serviceToEdit!.basePrice > 0)
          ? widget.serviceToEdit!.basePrice.toStringAsFixed(0) // Sin decimales .00
          : ''
    );

    // La categoría seleccionada
    _selectedCategoryId = widget.serviceToEdit?.categoryId;
  }

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
    FocusScope.of(context).unfocus(); // Ocultar teclado

    // Validaciones
    if (_currentStep == 0) {
      if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faltan datos o categoría')));
        return;
      }
    } else if (_currentStep == 1) {
      if (_addressCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta dirección o precio')));
        return;
      }
    }

    // Avanzar página
    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  // Enviar o Actualizar
  void _submitFinal() async {
    final authState = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final realToken = prefs.getString('token');

    if (realToken == null) return;

    // Crear el objeto con los datos del formulario
    final serviceData = ServiceEntity(
      id: widget.serviceToEdit?.id ?? '', // Si editamos, conservamos ID
      title: _titleCtrl.text.trim(),
      summary: _descCtrl.text.length > 50 ? "${_descCtrl.text.substring(0, 50)}..." : _descCtrl.text,
      description: _descCtrl.text.trim(),
      basePrice: double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
      categoryId: _selectedCategoryId!,
      clientId: authState.user?.id ?? '', // ID del usuario actual
      exactAddress: _addressCtrl.text.trim(),
      latitude: authState.user?.latitude ?? 0.0,
      longitude: authState.user?.longitude ?? 0.0,
      status: widget.serviceToEdit?.status ?? JobStatus.open,
      isActive: true,
      createdAt: DateTime.now(),
    );

    if (_isEditing) {
      // 🔵 MODO EDICIÓN: Llamamos a updateService
      await ref.read(serviceControllerProvider.notifier).updateService(serviceData, realToken);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cambios guardados')));
        // Regresamos el objeto nuevo al detalle para que se actualice al instante
        Navigator.pop(context, serviceData); 
      }
    } else {
      // 🟢 MODO CREACIÓN: Llamamos a createService
      await ref.read(serviceControllerProvider.notifier).createService(serviceData, realToken);
      // El listener de abajo se encarga de cerrar si todo sale bien
    }
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(serviceControllerProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    // Escuchamos si se creó exitosamente (solo para creación nueva)
    ref.listen(serviceControllerProvider, (prev, next) {
      if (!_isEditing && !next.isLoading && !next.hasError && next.hasValue) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Servicio publicado!')));
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(_isEditing ? "Editar Servicio" : "Publicar Servicio", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de progreso
          Container(
            color: Colors.white, padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("PASO ${_currentStep + 1} DE 3", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w900, fontSize: 12)),
                  Text(_currentStep == 0 ? "Detalles" : _currentStep == 1 ? "Ubicación" : "Resumen", style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500))
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _buildProgressLine(_currentStep >= 0)), const SizedBox(width: 8),
                  Expanded(child: _buildProgressLine(_currentStep >= 1)), const SizedBox(width: 8),
                  Expanded(child: _buildProgressLine(_currentStep >= 2))
                ])
              ],
            ),
          ),
          
          // Contenido de los Pasos
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Bloquear swipe manual
              children: [
                // PASO 1: Detalles
                Step1Details(
                  titleCtrl: _titleCtrl,
                  descCtrl: _descCtrl,
                  selectedCategoryId: _selectedCategoryId,
                  categoriesAsync: categoriesAsync,
                  onCategoryChanged: (id) => setState(() => _selectedCategoryId = id),
                  onNext: _nextStep
                ),
                
                // PASO 2: Ubicación
                Step2Location(
                  addressCtrl: _addressCtrl,
                  priceCtrl: _priceCtrl,
                  onNext: _nextStep
                ),
                
                // PASO 3: Resumen (Se reconstruye al llegar aquí, mostrando los textos actualizados)
                Step3Summary(
                  title: _titleCtrl.text,
                  desc: _descCtrl.text,
                  address: _addressCtrl.text,
                  price: _priceCtrl.text,
                  categoryId: _selectedCategoryId,
                  categoriesAsync: categoriesAsync,
                  isLoading: creationState.isLoading,
                  onSubmit: _submitFinal,
                  onEdit: () {
                    _pageController.jumpToPage(0);
                    setState(() => _currentStep = 0);
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) => AnimatedContainer(
    duration: const Duration(milliseconds: 300), 
    height: 6, 
    decoration: BoxDecoration(
      color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB), 
      borderRadius: BorderRadius.circular(3)
    )
  );
}