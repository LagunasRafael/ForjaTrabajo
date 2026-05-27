import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/domain/models/user_model.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/service_detail_body.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/create_services_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_offers_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/worker_apply_modal.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final ServiceEntity service;
  final User currentUser;
  final String categoryName;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    required this.currentUser,
    required this.categoryName,
  });

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  late ServiceEntity _currentService;

  @override
  void initState() {
    super.initState();
    _currentService = widget.service;
  }

  // 🧠 Lógica de permisos simplificada
  bool get _isOwner => widget.currentUser.id == _currentService.clientId;
  bool get _isWorker => widget.currentUser.role.toLowerCase().contains('worker');

  Future<void> _navigateToEdit() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateServiceScreen(serviceToEdit: _currentService)),
    );
    if (updated != null && updated is ServiceEntity) {
      setState(() => _currentService = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.service.id));
    final offersAsync = ref.watch(offersListProvider(_currentService.id));
    final categoriesAsync = ref.watch(categoryListProvider);

    return serviceAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (freshService) {
        _currentService = freshService;

        final displayCat = categoriesAsync.maybeWhen(
          data: (cats) {
            final foundCat = cats.where((c) => c.id == freshService.categoryId).firstOrNull;
            return foundCat?.name ?? widget.categoryName;
          },
          orElse: () => widget.categoryName,
        );

        final hasApplied = offersAsync.maybeWhen(
          data: (offers) {
            return offers.any((o) {
              final isMyOffer = o.workerId == widget.currentUser.id;
              
              final currentStatus = o.status.toString().toLowerCase().trim();
              final isCanceled = currentStatus == 'canceled'; 
              final isRejected = currentStatus == 'rejected'; 
              final isExpired = currentStatus == 'expired';

              return isMyOffer && !isCanceled && !isRejected && !isExpired;
            });
          },
          orElse: () => false,
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent, // 🎨 Limpio: dejamos que el fondo mande
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Detalles del Servicio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
          ),
          body: ServiceDetailBody(
            service: _currentService,
            categoryName: displayCat,
            authorName: _isOwner ? "${widget.currentUser.fullName} (Tú)" : (_currentService.authorName ?? "Cliente"),
            isOwner: _isOwner,
            authorImageUrl: _isOwner ? widget.currentUser.profilePictureUrl : _currentService.profilePictureUrl,
            authorId: _isOwner ? null : _currentService.clientId,
          ),
          bottomNavigationBar: _buildBottomAction(hasApplied),
        );
      },
    );
  }

  // 🛠️ Generador de botones de acción
  Widget? _buildBottomAction(bool hasApplied) {
    if (_isOwner || widget.currentUser.role == 'admin') {
      final isOpen = _currentService.status.toString().toLowerCase().contains('open');

      return _BottomBarContainer(
        child: ElevatedButton.icon(
          onPressed: isOpen ? _navigateToEdit : null,
          icon: Icon(isOpen ? Icons.edit : Icons.lock_outline, color: Colors.white),
          label: Text(
            isOpen ? "Editar Servicio" : "Servicio En curso", 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          style: _btnStyle(isOpen ? const Color(0xFF2563EB) : Colors.grey),
        ),
      );
    } 
    
    if (_isWorker) {
      final isOpen = _currentService.status.toString().toLowerCase().contains('open');
      if (!isOpen) {
        return null; // Oculta el botón si el servicio ya está en curso/cerrado
      }

      return _BottomBarContainer(
        child: hasApplied
            ? ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("Ya te has postulado", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: _btnStyle(Colors.grey),
              )
            : ElevatedButton(
                onPressed: () => showWorkerApplyModal(context, _currentService),
                style: _btnStyle(const Color(0xFF6200EE)),
                child: const Text("Postularme al Trabajo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
      );
    }
    return null;
  }

  ButtonStyle _btnStyle(Color color) => ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey[400],
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      );
}

class _BottomBarContainer extends StatelessWidget {
  final Widget child;
  const _BottomBarContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30), // 📏 Mejoramos los espacios
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: child,
    );
  }
}