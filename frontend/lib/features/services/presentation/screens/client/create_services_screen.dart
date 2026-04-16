import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/entities/service_entity.dart';
import '../../providers/category_provider.dart';
import '../../providers/service_list_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart'; 
import '../../providers/create_service_form_provider.dart'; // 👈 El cerebro importado

import 'create_service_steps/step1_details.dart'; // 👈 Tu widget separado
import 'create_service_steps/step2_location.dart'; // 👈 Tu widget separado
import 'create_service_steps/step3_summary.dart'; // 👈 Tu widget separado
import 'package:forja_trabajo/features/services/presentation/widgets/createservices/create_services_header.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  final ServiceEntity? serviceToEdit;
  const CreateServiceScreen({super.key, this.serviceToEdit});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl, _descCtrl, _addressCtrl, _priceCtrl;
  bool get _isEditing => widget.serviceToEdit != null;

  @override
  void initState() {
    super.initState();
    final s = widget.serviceToEdit;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _addressCtrl = TextEditingController(text: s?.exactAddress ?? '');
    _priceCtrl = TextEditingController(text: s?.basePrice != null ? s!.basePrice.toStringAsFixed(0) : '');

    Future.microtask(() {
      ref.read(createServiceFormProvider.notifier).loadInitialData(
        categoryId: s?.categoryId, lat: s?.latitude, lng: s?.longitude,
      );
    });
  }

  @override
  void dispose() {
    for (var c in [_pageController, _titleCtrl, _descCtrl, _addressCtrl, _priceCtrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) ref.read(createServiceFormProvider.notifier).addImage(File(image.path));
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    
    final formState = ref.read(createServiceFormProvider);

    if (formState.step == 0 && formState.categoryId == null) {
      _showError('Selecciona una categoría'); return;
    } 
    if (formState.step == 1 && formState.latitude == null) {
      _showError('Captura tu ubicación en el mapa'); return;
    }
    
    if (formState.step < 2) {
      final next = formState.step + 1;
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      ref.read(createServiceFormProvider.notifier).setStep(next);
    }
  }

  ServiceEntity _buildServiceFromInputs() {
    final user = ref.read(authProvider).user;
    final formState = ref.read(createServiceFormProvider); 
    
    return ServiceEntity(
      id: widget.serviceToEdit?.id ?? '',
      title: _titleCtrl.text.trim(),
      summary: _descCtrl.text.length > 50 ? "${_descCtrl.text.substring(0, 50)}..." : _descCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      basePrice: double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
      categoryId: formState.categoryId!,
      clientId: user?.id ?? '',
      exactAddress: _addressCtrl.text.trim(),
      latitude: formState.latitude, 
      longitude: formState.longitude,
      status: widget.serviceToEdit?.status ?? JobStatus.open,
      isActive: true, 
      createdAt: DateTime.now(),
      imageUrls: widget.serviceToEdit?.imageUrls ?? [],
    );
  }

  void _submitFinal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return _showError("Sesión expirada.");

    final serviceData = _buildServiceFromInputs(); 
    final notifier = ref.read(serviceControllerProvider.notifier);
    final formState = ref.read(createServiceFormProvider);

    if (_isEditing) {
      await notifier.updateService(serviceData, token); 
    } else {
      await notifier.createService(serviceData, token, images: formState.images);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(serviceControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) _showError("Error: ${next.error}");
      if (previous?.isLoading == true && !next.isLoading && !next.hasError) {
        ref.invalidate(serviceListProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Proceso completado!'), backgroundColor: Color(0xFF10B981)));
      }
    });

    final formState = ref.watch(createServiceFormProvider);
    final creationState = ref.watch(serviceControllerProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(formState.step),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            CreateServiceHeader(currentStep: formState.step),
            Expanded(
              child: PageView(
                controller: _pageController, 
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Step1Details(
                    titleCtrl: _titleCtrl, descCtrl: _descCtrl, 
                    selectedCategoryId: formState.categoryId, categoriesAsync: categoriesAsync, 
                    onCategoryChanged: (id) => ref.read(createServiceFormProvider.notifier).setCategory(id), 
                    onNext: _nextStep
                  ),
                  Step2Location(
                    addressCtrl: _addressCtrl, priceCtrl: _priceCtrl, lat: formState.latitude, lng: formState.longitude,
                    onLocationCaptured: (lat, lng) => ref.read(createServiceFormProvider.notifier).setLocation(lat, lng), 
                    onNext: _nextStep
                  ),
                  Step3Summary(
                    title: _titleCtrl.text, desc: _descCtrl.text, address: _addressCtrl.text, price: _priceCtrl.text, 
                    categoryId: formState.categoryId, categoriesAsync: categoriesAsync, 
                    isLoading: creationState.isLoading, images: formState.images,
                    onAddImage: _pickImage,
                    onRemoveImage: (i) => ref.read(createServiceFormProvider.notifier).removeImage(i), 
                    onSubmit: _submitFinal, 
                    onEdit: () { _pageController.jumpToPage(0); ref.read(createServiceFormProvider.notifier).setStep(0); }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int currentStep) {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () {
          if (currentStep > 0) {
            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            ref.read(createServiceFormProvider.notifier).setStep(currentStep - 1);
          } else { Navigator.pop(context); }
        },
      ),
      title: Text(_isEditing ? "Editar Servicio" : "Publicar Servicio", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}