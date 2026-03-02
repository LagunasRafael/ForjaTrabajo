import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- ENUMERACIÓN (El "molde" de los estados) ---
enum ContractStatus { active, finished }

class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

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
              _buildDynamicContractList(),
              const Center(child: Text("Solo Activos")),
              const Center(child: Text("Solo Finalizados")),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildDynamicContractList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🚀 TARJETA REAL: Los $3,000 que inyectamos en Python
        ContractCard(
          title: "Reparación de Lavabo",
          subtitle: "Trabajador: Pendiente de asignar",
          price: "\$3,000.00",
          date: "Hoy",
          status: ContractStatus.active,
          bottomContent: const AvatarStack(),
          onTap: () {
            // Asegúrate de tener esta ruta en main.dart
            Navigator.pushNamed(context, '/client/payment');
          },
        ),
        const SizedBox(height: 16),
        const SkeletonCard(), // Efecto visual de carga
      ],
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