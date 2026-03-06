import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/domain/models/user_model.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_detail_body.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/create_services_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_offers_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/worker_apply_modal.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final ServiceEntity service;
  final User currentUser;
  final String categoryName;

  const ServiceDetailScreen(
      {super.key,
      required this.service,
      required this.currentUser,
      required this.categoryName});

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  late ServiceEntity _currentService;

  @override
  void initState() {
    super.initState();
    _currentService = widget.service;
  }

  bool get _isOwner =>
      widget.currentUser.id.toString() == _currentService.clientId.toString();
  bool get _isWorker =>
      widget.currentUser.role.toString().toLowerCase().contains('worker') ||
      widget.currentUser.role.toString().toLowerCase().contains('trabajador');

  Future<void> _navigateToEdit() async {
    final updated = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                CreateServiceScreen(serviceToEdit: _currentService)));
    if (updated != null && updated is ServiceEntity)
      setState(() => _currentService = updated);
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.service.id));
    final offersAsync = ref.watch(offersListProvider(_currentService.id));
    final categoriesAsync = ref.watch(categoryListProvider);

    return serviceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (freshService) {
        _currentService = freshService;
        String displayCat = widget.categoryName;
        categoriesAsync.whenData((cats) {
          final found = cats.where(
              (c) => c.id.toString() == freshService.categoryId.toString());
          if (found.isNotEmpty) displayCat = found.first.name;
        });

        final hasApplied = offersAsync.maybeWhen(
          data: (offers) => offers.any((o) =>
              o.workerId.toString().trim() ==
              widget.currentUser.id.toString().trim()),
          orElse: () => false,
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text("Detalles del Servicio",
                style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            centerTitle: true,
          ),
          body: ServiceDetailBody(
            service: _currentService,
            categoryName: displayCat,
            authorName: _isOwner
                ? "${widget.currentUser.fullName} (Tú)"
                : (_currentService.authorName ?? "Cliente"),
            isOwner: _isOwner,

            // 👇 AQUÍ ENVIAMOS LA IMAGEN. Si es el dueño usa su propia foto, si no, usa la que viene en el servicio
            authorImageUrl: _isOwner
                ? widget.currentUser.profilePictureUrl
                : _currentService.profilePictureUrl,
          ),
          bottomNavigationBar: _buildBottomAction(hasApplied),
        );
      },
    );
  }

  Widget? _buildBottomAction(bool hasApplied) {
    if (_isOwner || widget.currentUser.role.contains('admin')) {
      return _BottomBarContainer(
        child: ElevatedButton(
            onPressed: _navigateToEdit,
            style: _btnStyle(const Color(0xFF2563EB)),
            child: const Text("Editar Servicio",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      );
    } else if (_isWorker) {
      return _BottomBarContainer(
        child: hasApplied
            ? ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("Ya te has postulado",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: _btnStyle(Colors.grey))
            : ElevatedButton(
                onPressed: () =>
                    showWorkerApplyModal(context, ref, _currentService),
                style: _btnStyle(const Color(0xFF6200EE)),
                child: const Text("Postularme al Trabajo",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      );
    }
    return null;
  }

  ButtonStyle _btnStyle(Color color) => ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class _BottomBarContainer extends StatelessWidget {
  final Widget child;
  const _BottomBarContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
        ],
      ),
      child: child,
    );
  }
}
