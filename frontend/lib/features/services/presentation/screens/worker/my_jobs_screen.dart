import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🚀 TUS IMPORTS MODULARES (Ganaron por ordern)
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_job_list_view.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';

class MyJobsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const MyJobsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MyJobsScreen> createState() => _WorkerMyJobsScreenState();
}

class _WorkerMyJobsScreenState extends ConsumerState<MyJobsScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Prioridad: 1. Índice que viene por constructor 2. Índice del provider
    final index = widget.initialIndex != 0 ? widget.initialIndex : ref.read(workerJobsTabProvider);
    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: index
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      ref.invalidate(workerJobsProvider);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(workerJobsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos si el provider cambia para animar la pestaña
    ref.listen<int>(workerJobsTabProvider, (previous, nextIndex) {
      _tabController.animateTo(nextIndex);
    });

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
            Tab(text: 'En Proceso'),
            Tab(text: 'Finalizados'),
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