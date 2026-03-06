import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import '../../providers/job_management_provider.dart'; 
import 'package:forja_trabajo/shared/widgets/empty_state_widget.dart';
import 'package:forja_trabajo/shared/widgets/service_card_skeleton.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_pending_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_active_job_card.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/worker/worker_completed_job_card.dart';
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mis Empleos', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF10B981),
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
        children: [
          // 🚀 Ahora pasamos la responsabilidad a este nuevo widget
          WorkerJobListView(status: JobStatus.open),
          WorkerJobListView(status: JobStatus.matched),
          WorkerJobListView(status: JobStatus.completed),
        ],
      ),
    );
  }
}