import 'package:flutter/material.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_status_chip.dart';

class WorkerCompletedJobCard extends StatelessWidget {
  final dynamic job;

  const WorkerCompletedJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.grey.shade100, // Fondo grisáceo para indicar que ya pasó
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ServiceStatusChip(status: job.status.toString().split('.').last),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cobrado: \$${job.basePrice}",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Ver resumen
                  },
                  child: const Text("Ver resumen", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}