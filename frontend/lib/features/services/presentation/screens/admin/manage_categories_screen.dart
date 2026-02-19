import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/category_provider.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Gestionar Categorías', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.category, color: Color(0xFF4F46E5)),
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(cat.description ?? ''), // Mostramos la descripción
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteConfirm(context, ref, cat.id, cat.name),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error al cargar categorías: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCategoryDialog(context, ref),
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nueva Categoría", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController(); // 👈 Controlador para descripción

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final status = ref.watch(categoryActionProvider);
            final isLoading = status is AsyncLoading;

            return AlertDialog(
              title: const Text("Crear Categoría"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      hintText: "Nombre (ej. Construcción)",
                      labelText: "Nombre",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: descController, // 👈 Asignamos el nuevo controlador
                    enabled: !isLoading,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Breve descripción de los servicios...",
                      labelText: "Descripción",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                  onPressed: isLoading ? null : () async {
                    if (nameController.text.isNotEmpty && descController.text.isNotEmpty) {
                      // 👇 PASAMOS AMBOS ARGUMENTOS
                      await ref.read(categoryActionProvider.notifier)
                          .createCategory(
                            nameController.text.trim(), 
                            descController.text.trim()
                          );
                      
                      if (ref.read(categoryActionProvider) is! AsyncError) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Categoría creada con éxito"), 
                            backgroundColor: Colors.green),
                          );
                        }
                      }
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(width: 20, height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Guardar", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar categoría?"),
        content: Text("¿Estás seguro de que quieres borrar '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await ref.read(categoryActionProvider.notifier).deleteCategory(id);
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text("Eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }
}