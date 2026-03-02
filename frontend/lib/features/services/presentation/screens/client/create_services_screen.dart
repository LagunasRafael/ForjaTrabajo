import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

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

  late TextEditingController _titleCtrl, _descCtrl, _addressCtrl, _priceCtrl;
  String? _selectedCategoryId;
  double? _latitude, _longitude;
  List<File> _evidenceImages = [];

  bool get _isEditing => widget.serviceToEdit != null;

  @override
  void initState() {
    super.initState();
    final s = widget.serviceToEdit;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _addressCtrl = TextEditingController(text: s?.exactAddress ?? '');
    _priceCtrl = TextEditingController(text: s?.basePrice != null ? s!.basePrice.toStringAsFixed(0) : '');
    _selectedCategoryId = s?.categoryId;
    _latitude = s?.latitude;
    _longitude = s?.longitude;
  }

  @override
  void dispose() {
    for (var c in [_pageController, _titleCtrl, _descCtrl, _addressCtrl, _priceCtrl]) { c.dispose(); }
    super.dispose();
  }

  // --- LÓGICA DE PASOS Y VALIDACIONES ---

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0 && (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _selectedCategoryId == null)) {
      _showError('Llena los datos y selecciona una categoría'); return;
    } 
    if (_currentStep == 1 && (_addressCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _latitude == null)) {
      _showError('Por favor captura tu ubicación en el mapa'); return;
    }
    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // --- MANEJO DE IMÁGENES ---

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) setState(() => _evidenceImages.add(File(image.path)));
  }

  void _removeImage(int index) => setState(() => _evidenceImages.removeAt(index));

  // --- ENVÍO FINAL ---

  void _submitFinal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showError("Sesión expirada. Por favor, inicia sesión de nuevo.");
      return;
    }

    final serviceData = ServiceEntity(
      id: widget.serviceToEdit?.id ?? '',
      title: _titleCtrl.text.trim(),
      summary: _descCtrl.text.length > 50 
          ? "${_descCtrl.text.substring(0, 50)}..." 
          : _descCtrl.text,
      description: _descCtrl.text.trim(),
      basePrice: double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
      categoryId: _selectedCategoryId!,
      clientId: ref.read(authProvider).user?.id ?? '',
      exactAddress: _addressCtrl.text.trim(),
      latitude: _latitude, 
      longitude: _longitude,
      status: widget.serviceToEdit?.status ?? JobStatus.open,
      isActive: true, 
      createdAt: DateTime.now(),
    );

    final notifier = ref.read(serviceControllerProvider.notifier);
    
    if (_isEditing) {
      await notifier.updateService(serviceData, token);
    } else {
      await notifier.createService(serviceData, token, images: _evidenceImages);
    }

    final state = ref.read(serviceControllerProvider);
    if (state.hasError) {
      _showError("Error al procesar la solicitud: ${state.error}");
      return;
    }

    if (mounted) {
      Navigator.pop(context, _isEditing ? serviceData : null);
      
      Future.microtask(() {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '✅ Cambios guardados' : '✅ ¡Servicio publicado!'),
            backgroundColor: const Color(0xFF10B981),
          )
        );
        ref.invalidate(serviceListProvider);
      });
    }
  }

  void _showSuccessSnackBar() {
    Future.microtask(() => ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(content: Text(_isEditing ? '✅ Cambios guardados' : '✅ ¡Servicio publicado!'), backgroundColor: const Color(0xFF10B981))
    ));
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(serviceControllerProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => _currentStep > 0 
            ? { _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut), setState(() => _currentStep--) } 
            : Navigator.pop(context),
        ),
        title: Text(_isEditing ? "Editar Servicio" : "Publicar Servicio", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          _buildStepHeader(),
          Expanded(
            child: PageView(
              controller: _pageController, physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1Details(
                  titleCtrl: _titleCtrl, descCtrl: _descCtrl, 
                  selectedCategoryId: _selectedCategoryId, categoriesAsync: categoriesAsync, 
                  onCategoryChanged: (id) => setState(() => _selectedCategoryId = id), onNext: _nextStep
                ),
                Step2Location(
                  addressCtrl: _addressCtrl, priceCtrl: _priceCtrl, lat: _latitude, lng: _longitude,
                  onLocationCaptured: (lat, lng) => setState(() { _latitude = lat; _longitude = lng; }), onNext: _nextStep
                ),
                Step3Summary(
                  title: _titleCtrl.text, desc: _descCtrl.text, address: _addressCtrl.text, price: _priceCtrl.text, 
                  categoryId: _selectedCategoryId, categoriesAsync: categoriesAsync, 
                  isLoading: creationState.isLoading, images: _evidenceImages,
                  onAddImage: _pickImage, onRemoveImage: _removeImage, onSubmit: _submitFinal, 
                  onEdit: () { _pageController.jumpToPage(0); setState(() => _currentStep = 0); }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      color: Colors.white, padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("PASO ${_currentStep + 1} DE 3", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w900, fontSize: 12)), 
          Text(_currentStep == 0 ? "Detalles Básicos" : _currentStep == 1 ? "Ubicación" : "Resumen", style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500))
        ]),
        const SizedBox(height: 14),
        Row(children: [for (int i = 0; i < 3; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i < 2 ? 8 : 0), child: _buildProgressLine(_currentStep >= i)))]),
      ]),
    );
  }

  Widget _buildProgressLine(bool isActive) => AnimatedContainer(duration: const Duration(milliseconds: 300), height: 6, decoration: BoxDecoration(color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3)));
}