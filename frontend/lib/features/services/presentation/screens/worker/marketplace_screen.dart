import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🚀 TUS COMPONENTES MODULARES (Ganó tu HEAD)
import 'package:forja_trabajo/features/services/presentation/widgets/header_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/category_selector_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_list_widget.dart'; 
import 'package:forja_trabajo/features/services/presentation/widgets/search_bar_widget.dart'; 

// 🎯 Cambiamos a ConsumerWidget para que Riverpod funcione bien aquí
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              // 🎨 Aplicamos el cambio de color adaptable de tus compañeros
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🤝 FUSIÓN: Usamos tu Header modular
                  HeaderWidget(), 
                  SizedBox(height: 20),
                  
                  // 🤝 FUSIÓN: Usamos tu Buscador modular
                  SearchBarWidget(), 
                  SizedBox(height: 20),
                  
                  // 🤝 FUSIÓN: Usamos tu Selector de categorías modular
                  CategorySelectorWidget(),
                ],
              ),
            ),
            
            // 🤝 FUSIÓN: Tu lista de servicios modular (que ya maneja los esqueletos de carga)
            const Expanded(
              child: ServiceListWidget(), 
            ),
          ],
        ),
      ),
    );
  }
}