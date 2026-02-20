import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 👇 Importamos el Auth Provider
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart'; 

// 👇 Lo cambiamos a ConsumerWidget para que pueda leer a Riverpod
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 👇 Extraemos el nombre del administrador
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Administrador';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel de Control', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
            // 👇 Aquí imprimimos su nombre
            Text('Hola, $userName', style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _buildStatCard('Usuarios', '124', Icons.people, Colors.blue),
          _buildStatCard('Servicios', '45', Icons.handyman, Colors.orange),
          _buildStatCard('Reportes', '3', Icons.report_problem, Colors.red),
          _buildStatCard('Categorías', '12', Icons.category, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 10),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }
}