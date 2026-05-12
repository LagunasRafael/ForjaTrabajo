import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🚀 TUS IMPORTS MODULARES (Ganaron por orden)
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_job_list_view.dart';

class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _WorkerMyJobsScreenState();
}

class _WorkerMyJobsScreenState extends ConsumerState<MyJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Mantenemos tu controlador personalizado porque es más potente que el DefaultTabController
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 LÓGICA DE TUS COMPAÑEROS: Detección de tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mis Empleos', 
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color, 
            fontWeight: FontWeight.bold
          )),
        // 🎨 Color adaptable de tus compañeros
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5), // Color unificado
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Postulaciones'),
            Tab(text: 'En Curso'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // 🚀 USAMOS TU ARQUITECTURA: Cada lista es un widget independiente
          WorkerJobListView(status: JobStatus.open),
          WorkerJobListView(status: JobStatus.matched),
          WorkerJobListView(status: JobStatus.completed),
        ],
      ),
    );
  }
}