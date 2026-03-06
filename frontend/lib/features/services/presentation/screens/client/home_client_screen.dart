import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/header_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/category_selector_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_list_widget.dart'; 
import 'package:forja_trabajo/features/services/presentation/widgets/search_bar_widget.dart'; 

class HomeClientScreen extends ConsumerWidget {
  const HomeClientScreen({super.key});

  @override 
  Widget build(BuildContext context, WidgetRef ref) {
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
                children: const [
                  Header(),
                  SizedBox(height: 20),
                  SearchBarWidget(), // ✅ Ahora coincide el nombre perfectamente
                  SizedBox(height: 20),
                  CategorySelectorWidget(),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF10B981),
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: const ServiceListWidget(), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}