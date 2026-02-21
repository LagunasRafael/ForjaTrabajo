import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_list_provider.dart';
// Importamos los providers de servicios
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';

// 👇 IMPORTANTE: Importamos tu AuthProvider para sacar el nombre del usuario
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart'; 

import '../../widgets/service_card.dart';

class HomeClientScreen extends ConsumerWidget {
  const HomeClientScreen({super.key});

  // 👇 Lógica de íconos inteligentes (misma que usamos en crear servicio)
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('plom') || name.contains('fuga')) return Icons.plumbing;
    if (name.contains('electr') || name.contains('luz')) return Icons.electric_bolt;
    if (name.contains('carp') || name.contains('mueb')) return Icons.handyman;
    if (name.contains('pint')) return Icons.format_paint;
    if (name.contains('limp')) return Icons.cleaning_services;
    if (name.contains('mec') || name.contains('auto')) return Icons.car_repair;
    return Icons.category;
  }

  @override 
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos los providers (una sola vez cada uno)
    final servicesAsync = ref.watch(serviceListProvider);
    final allCategoriesAsync = ref.watch(categoryListProvider);
    final topCategoriesAsync = ref.watch(topCategoryListProvider);
    
    // El resto de variables
    final selectedCatId = ref.watch(selectedCategoryProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Usuario';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👇 Le pasamos el nombre real
                  _buildHeader(userName),
                  const SizedBox(height: 20),
                  _buildSearchBar(ref),
                  const SizedBox(height: 20),

                  // CATEGORÍAS DINÁMICAS DESDE LA DB
                  // 👇 AHORA USAMOS EL TOP PARA EL CARRUSEL
                  topCategoriesAsync.when(
                    data: (topCategories) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCategoryChip(
                              label: "Todos",
                              isSelected: selectedCatId == null,
                              onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                            ),
                            // Aquí pintamos las top (que ya vienen ordenadas de Python)
                            ...topCategories.map((cat) => _buildCategoryChip(
                              label: cat.name,
                              isSelected: selectedCatId == cat.id,
                              onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id,
                            )),
                            
                            // 👇 Y cuando le den a Ver más, pasamos TODAS las categorías
                            allCategoriesAsync.when(
                              data: (allCats) => _buildCategoryChip(
                                label: "Ver más",
                                isSelected: false,
                                icon: Icons.grid_view_rounded,
                                onTap: () => _showAllCategoriesModal(context, allCats, ref, selectedCatId),
                              ),
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => const Text("Error al cargar categorías destacadas"),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  // 👇 EL TÍTULO "EMPLEOS DISPONIBLES"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Empleos Disponibles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Ver todos", style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  // 👇 LA LISTA DE TARJETAS
                  Expanded(
                    child: servicesAsync.when(
                      data: (services) => ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: services.length,
                        itemBuilder: (context, index) => ServiceCard(service: services[index]),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text("Error: $e")),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // EL BOTÓN FLOTANTE SE BORRÓ DE AQUÍ PORQUE AHORA ESTÁ EN EL LAYOUT
    );
  }

  // 👇 AQUÍ ESTÁ EL DIÁLOGO FLOTANTE (FANTASMA) EN EL CENTRO
  void _showAllCategoriesModal(BuildContext context, List<dynamic> allCategories, WidgetRef ref, String? selectedCatId) {
    showDialog(
      context: context,
      barrierDismissible: true, // Permite cerrar tocando fuera
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Fondo transparente para el efecto flotante
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40), // Separación de las orillas
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7, // Altura máxima del 70% de la pantalla
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Se adapta a la cantidad de elementos
              children: [
                // Cabecera del pop-up
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Todas las categorías", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: Icon(Icons.close, color: Colors.grey[600], size: 20)
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                // Lista de categorías
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: allCategories.length,
                    itemBuilder: (context, i) {
                      final cat = allCategories[i];
                      final isSelected = selectedCatId == cat.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFFEEF2FF) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                            child: Icon(_getCategoryIcon(cat.name), color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[600]),
                          ),
                          title: Text(cat.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF374151))),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF4F46E5)) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: isSelected ? const Color(0xFFF5F8FF) : Colors.transparent,
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).state = cat.id;
                            Navigator.pop(context); // Cierra el pop-up automáticamente
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({required String label, required bool isSelected, required VoidCallback onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            if (icon != null) Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            if (icon != null) const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // 👇 Aquí recibimos el nombre real y lo imprimimos
  Widget _buildHeader(String name) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          const Text("Bienvenido de nuevo", style: TextStyle(color: Colors.grey, fontSize: 14)), 
          Text("Hola, $name", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))
        ]
      ),
      CircleAvatar(
        radius: 24,
        backgroundColor: Colors.indigo.shade100,
        child: const Icon(Icons.person, color: Colors.indigo),
      ),
    ]
  );

    // Agregamos (WidgetRef ref) aquí 👇
Widget _buildSearchBar(WidgetRef ref) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), 
          borderRadius: BorderRadius.circular(16)),
      child: TextField(
        onChanged: (value) {
          // Esto es lo que actualiza la lista en tiempo real
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: const InputDecoration(
            hintText: "Buscar trabajos...",
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none),
      ),
    );
}