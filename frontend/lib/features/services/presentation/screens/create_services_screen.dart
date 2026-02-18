import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/category_provider.dart';
import '../providers/service_list_provider.dart'; // Importamos el provider unificado

class CreateServiceScreen extends ConsumerStatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  
  String? _selectedCategoryId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Escuchamos el estado de creación (para saber si está cargando)
    final creationState = ref.watch(serviceControllerProvider);
    // 2. Escuchamos las categorías para llenar el Dropdown
    final categoriesAsync = ref.watch(categoryListProvider);

    // Listener para cerrar pantalla si hay éxito o mostrar error
    ref.listen(serviceControllerProvider, (prev, next) {
      if (!next.isLoading && !next.hasError && next.hasValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Servicio publicado correctamente')),
        );
        Navigator.pop(context); // Volver al Home
      }
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Publicar Servicio")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // TÍTULO
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Título del trabajo",
                      hintText: "Ej. Reparación de tubería",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 20),

                  // CATEGORÍA (Dropdown dinámico)
                  categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: "Categoría",
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                      validator: (v) => v == null ? "Selecciona una categoría" : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_,__) => const Text("No se pudieron cargar categorías"),
                  ),
                  const SizedBox(height: 20),

                  // DESCRIPCIÓN
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Detalles",
                      hintText: "Describe qué necesitas hacer...",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 20),

                  // PRECIO
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Presupuesto (MXN)",
                      prefixText: "\$ ",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  ),
                  const SizedBox(height: 30),

                  // BOTÓN PUBLICAR
                  ElevatedButton(
                    onPressed: creationState.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF4F46E5),
                    ),
                    child: creationState.isLoading
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text("PUBLICAR AHORA", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      // 1. Crear el objeto entidad
      final newService = ServiceEntity(
        id: '', // El backend genera el ID
        title: _titleCtrl.text,
        description: _descCtrl.text,
        basePrice: double.tryParse(_priceCtrl.text) ?? 0.0,
        categoryId: _selectedCategoryId!,
        clientId: '', // El backend usa el ID del token
        status: JobStatus.open,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // 2. Llamar al provider (TOKEN QUEMADO PARA PRUEBA)
      // En el futuro, sacarás este token de tu AuthProvider
      const testToken = "TOKEN_DE_PRUEBA_AQUI"; 
      
      ref.read(serviceControllerProvider.notifier).createService(newService, testToken);
    }
  }
}