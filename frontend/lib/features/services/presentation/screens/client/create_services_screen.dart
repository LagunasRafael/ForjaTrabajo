import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../../../domain/entities/service_entity.dart';
import '../../providers/category_provider.dart';
import '../../providers/service_list_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/create_service_form_provider.dart';
import 'create_service_steps/step1_details.dart';
import 'create_service_steps/step2_location.dart';
import 'create_service_steps/step3_summary.dart';
import '../../providers/nav_providers.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/createservices/create_services_header.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/spanish_asset_picker_delegate.dart';

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
  ServiceEntity? _pendingResultService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.serviceToEdit;
    _titleCtrl   = TextEditingController(text: s?.title ?? '');
    _descCtrl    = TextEditingController(text: s?.description ?? '');
    _addressCtrl = TextEditingController(text: s?.exactAddress ?? '');
    _priceCtrl   = TextEditingController(text: s?.basePrice != null ? s!.basePrice.toStringAsFixed(0) : '');

    Future.microtask(() {
      ref.read(createServiceFormProvider.notifier).loadInitialData(
        categoryId: s?.categoryId, lat: s?.latitude, lng: s?.longitude,
        existingImageUrls: s?.imageUrls,
      );
    });
  }

  @override
  void dispose() {
    for (var c in [_pageController, _titleCtrl, _descCtrl, _addressCtrl, _priceCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final formState = ref.read(createServiceFormProvider);
    final totalImages = formState.existingImageUrls.length + formState.images.length;
    final remaining = 8 - totalImages;
    if (remaining <= 0) {
      _showError("Máximo 8 fotos");
      return;
    }

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      _showError("Permiso denegado para acceder a la galería");
      return;
    }

    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: remaining,
        requestType: RequestType.image,
        textDelegate: const SpanishAssetPickerTextDelegate(),
      ),
    );

    if (result == null || result.isEmpty) return;
    if (!mounted) return;

    final files = <File>[];
    for (final asset in result) {
      final file = await asset.file;
      if (file != null) files.add(file);
    }
    if (files.isNotEmpty) {
      ref.read(createServiceFormProvider.notifier).addImages(files);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF4F46E5)),
        ),
        backgroundColor: const Color(0xFFF0F0F0),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 210,
          left: 24,
          right: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Avanza al siguiente step. Los steps ya validan antes de llamar a onNext.
  void _nextStep() {
    FocusScope.of(context).unfocus();

    final formState = ref.read(createServiceFormProvider);

    // Guardia extra: step2 requiere ubicación capturada
    if (formState.step == 1 && formState.latitude == null) {
      _showError('Captura tu ubicación en el mapa');
      return;
    }

    if (formState.step < 2) {
      final next = formState.step + 1;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
      imageUrls: const [],
    );
  }

  void _submitFinal() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        if (mounted) _showError("Sesión expirada.");
        return;
      }

      final serviceData = _buildServiceFromInputs();
      final notifier = ref.read(serviceControllerProvider.notifier);
      final formState = ref.read(createServiceFormProvider);

      if (_isEditing) {
        final newUrls = formState.images.isNotEmpty
            ? await notifier.uploadServiceImages(serviceData.id, formState.images, token)
            : <String>[];
        final finalUrls = [...formState.keptImageUrls, ...newUrls];
        _pendingResultService = serviceData.copyWith(imageUrls: finalUrls);
        await notifier.updateService(serviceData.copyWith(imageUrls: finalUrls), token);
      } else {
        await notifier.createService(serviceData, token, images: formState.images);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(serviceControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) _showError("Error: ${next.error}");
      if (previous?.isLoading == true && !next.isLoading && !next.hasError) {
        ref.invalidate(serviceListProvider);
        ref.read(clientNavProvider.notifier).state = 0;
        Navigator.pop(context, _pendingResultService);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? '¡Servicio actualizado con éxito!' : '¡Servicio publicado con éxito!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4F46E5)),
            ),
            backgroundColor: const Color(0xFFF0F0F0),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 900,
              left: 24,
              right: 24,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    final theme = Theme.of(context);
    final formState       = ref.watch(createServiceFormProvider);
    final creationState   = ref.watch(serviceControllerProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return PopScope(
      canPop: formState.step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (formState.step > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          ref.read(createServiceFormProvider.notifier).setStep(formState.step - 1);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
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
                      selectedCategoryId: formState.categoryId,
                      categoriesAsync: categoriesAsync,
                      onCategoryChanged: (id) => ref.read(createServiceFormProvider.notifier).setCategory(id),
                      onNext: _nextStep,
                    ),
                    Step2Location(
                      addressCtrl: _addressCtrl, priceCtrl: _priceCtrl,
                      lat: formState.latitude, lng: formState.longitude,
                      onLocationCaptured: (lat, lng) => ref.read(createServiceFormProvider.notifier).setLocation(lat, lng),
                      onNext: _nextStep,
                    ),
                    Step3Summary(
                      title: _titleCtrl.text, desc: _descCtrl.text,
                      address: _addressCtrl.text, price: _priceCtrl.text,
                      categoryId: formState.categoryId, categoriesAsync: categoriesAsync,
                      isLoading: creationState.isLoading || _isSubmitting, images: formState.images,
                      existingImageUrls: formState.keptImageUrls,
                      onAddImage: _pickImages,
                      onRemoveImage: (i) => ref.read(createServiceFormProvider.notifier).removeImage(i),
                      onRemoveExistingImage: (i) {
                        final url = ref.read(createServiceFormProvider).keptImageUrls[i];
                        ref.read(createServiceFormProvider.notifier).removeExistingImageByUrl(url);
                      },
                      onSubmit: _submitFinal,
                      onEdit: () {
                        _pageController.jumpToPage(0);
                        ref.read(createServiceFormProvider.notifier).setStep(0);
                      },
                      isEditing: _isEditing,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int currentStep) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.colorScheme.surface, elevation: 0, centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
        onPressed: () {
          if (currentStep > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(createServiceFormProvider.notifier).setStep(currentStep - 1);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(_isEditing ? "Editar Servicio" : "Publicar Servicio", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}