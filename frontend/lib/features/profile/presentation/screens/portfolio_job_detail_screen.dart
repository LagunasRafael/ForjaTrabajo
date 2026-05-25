import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/service_detail_body.dart';

class PortfolioJobDetailScreen extends ConsumerWidget {
  final String jobId;
  final String? jobTitle;

  const PortfolioJobDetailScreen({
    super.key,
    required this.jobId,
    this.jobTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(jobId));
    final categoriesAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          jobTitle ?? 'Detalle del Trabajo',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: serviceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error al cargar el detalle del trabajo: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
        data: (service) {
          final displayCat = categoriesAsync.maybeWhen(
            data: (cats) {
              final foundCat = cats.where((c) => c.id == service.categoryId).firstOrNull;
              return foundCat?.name ?? 'Servicio';
            },
            orElse: () => 'Servicio',
          );

          return ServiceDetailBody(
            service: service,
            categoryName: displayCat,
            authorName: service.authorName ?? 'Cliente',
            authorImageUrl: service.profilePictureUrl,
            authorId: service.clientId,
            isOwner: false, // De solo lectura, no es dueño en modo edición
          );
        },
      ),
    );
  }
}
