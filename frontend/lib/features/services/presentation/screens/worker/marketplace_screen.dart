import 'package:flutter/material.dart';

import 'package:forja_trabajo/features/services/presentation/widgets/header_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/category_selector_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_list_widget.dart'; 
import 'package:forja_trabajo/features/services/presentation/widgets/search_bar_widget.dart'; 


class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(),        // 🚀 Nuevo
                  SizedBox(height: 20),
                  SearchBarWidget(),     // ♻️ Reutilizado
                  SizedBox(height: 20),
                  CategorySelectorWidget(), // ♻️ Reutilizado
                ],
              ),
            ),
            const Expanded(
              child: ServiceListWidget(), // ♻️ Reutilizado
            ),
          ],
        ),
      ),
    );
  }
}