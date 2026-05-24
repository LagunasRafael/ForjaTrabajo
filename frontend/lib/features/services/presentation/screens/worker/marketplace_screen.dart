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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HeaderWidget(),
              SizedBox(height: 20),
              SearchBarWidget(),
              SizedBox(height: 12),
              LocationRadiusBar(),
              SizedBox(height: 16),
              CategorySelectorWidget(),
              SizedBox(height: 16),
              Expanded(
                child: ServiceListWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}