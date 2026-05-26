import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forja_trabajo/features/services/presentation/widgets/header_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/category_selector_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_list_widget.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/search_bar_widget.dart';
import 'package:forja_trabajo/shared/widgets/location/location_radius_bar.dart';

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
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderWidget(),
                  SizedBox(height: 20),
                  SearchBarWidget(),
                  SizedBox(height: 12),
                  LocationRadiusBar(),
                  SizedBox(height: 16),
                  CategorySelectorWidget(),
                ],
              ),
            ),
            const Expanded(
              child: ServiceListWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
