import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/checkout_screen.dart';

// --- ENUMERACIÓN (El "molde" de los estados) ---
enum ContractStatus { active, finished }

class ContractsScreen extends ConsumerStatefulWidget {
  final String? serviceId;
  final String? workerId;
  final String? workerName;
  final double? proposedPrice;

  const ContractsScreen({
    super.key,
    this.serviceId,
    this.workerId,
    this.workerName,
    this.proposedPrice,
  });

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  final primaryColor = const Color(0xFF7F13EC);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!mounted) return;
        // Limpia el foco para evitar el bug de Windows al salir
        FocusScope.of(context).unfocus();
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F6F8),
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Mis Contratos',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 20),
            ),
            bottom: TabBar(
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Todos"),
                Tab(text: "Activos"),
                Tab(text: "Finalizados"),
              ],
            ),
          ),
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildDynamicContractList(null),
              _buildDynamicContractList(ContractStatus.active),
              _buildDynamicContractList(ContractStatus.finished),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildDynamicContractList(ContractStatus? statusFilter) {
    final servicesAsync = ref.watch(myRequestsProvider);

    return servicesAsync.when(
      data: (services) {
        // Filtramos para obtener solo En Proceso (matched) o Finalizados (completed)
        var filteredServices = services.where((s) => s.status == JobStatus.matched || s.status == JobStatus.completed).toList();

        if (statusFilter == ContractStatus.active) {
          filteredServices = filteredServices.where((s) => s.status == JobStatus.matched).toList();
        } else if (statusFilter == ContractStatus.finished) {
          filteredServices = filteredServices.where((s) => s.status == JobStatus.completed).toList();
        }

        if (filteredServices.isEmpty) {
          return Center(
            child: Text(
              statusFilter == ContractStatus.active ? "No tienes contratos activos" : statusFilter == ContractStatus.finished ? "No tienes contratos finalizados" : "No tienes contratos",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredServices.length,
          itemBuilder: (context, index) {
            final service = filteredServices[index];
            final isFinished = service.status == JobStatus.completed;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ContractCard(
                title: service.title,
                subtitle: "Trabajador: ${service.authorName ?? 'Asignado'}",
                price: "\$${service.basePrice.toStringAsFixed(2)}",
                date: "Fecha: ${service.createdAt.day}/${service.createdAt.month}/${service.createdAt.year}",
                status: isFinished ? ContractStatus.finished : ContractStatus.active,
                bottomContent: const AvatarStack(),
                onTap: () {
                  if (!isFinished) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                          jobId: service.id,
                          amount: service.basePrice.toDouble(),
                        ),
                      ),
                    );
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este contrato ya está pagado/finalizado.')));
                  }
                },
              ),
            );
          },
        );
      },
      loading: () => ListView(padding: const EdgeInsets.all(16), children: const [SkeletonCard(), SizedBox(height: 16), SkeletonCard()]),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Inicio", false),
            _buildNavItem(Icons.description, "Contratos", true, color: primaryColor),
            const SizedBox(width: 48),
            _buildNavItem(Icons.chat_bubble_outline, "Mensajes", false),
            _buildNavItem(Icons.person_outline, "Perfil", false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color ?? Colors.grey.shade400),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color ?? Colors.grey.shade400)),
      ],
    );
  }
}

// --- WIDGETS DE SOPORTE (Aquí estaban los errores) ---

class ContractCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String date;
  final ContractStatus status;
  final Widget bottomContent;
  final VoidCallback onTap;

  const ContractCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.date,
    required this.status,
    required this.bottomContent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = status == ContractStatus.finished;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBadge(isFinished),
                        const SizedBox(height: 8),
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7F13EC))),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  bottomContent,
                  const Row(
                    children: [
                      Text("Ver Pago ", style: TextStyle(color: Color(0xFF7F13EC), fontWeight: FontWeight.bold)),
                      Icon(Icons.chevron_right, color: Color(0xFF7F13EC), size: 18),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isFinished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFinished ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isFinished ? "FINALIZADO" : "ACTIVO",
        style: TextStyle(
          color: isFinished ? const Color(0xFF4B5563) : const Color(0xFF166534),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 14,
      backgroundColor: Color(0xFFF3F4F6),
      child: Icon(Icons.person, size: 16, color: Colors.grey),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
    );
  }
}

// Clase temporal para pasar los parámetros justos a CheckoutScreen
class _TempContract {
  final String id;
  final num amount;
  _TempContract({required this.id, required this.amount});
}