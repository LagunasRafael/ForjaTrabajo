import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_card.dart';
import 'package:forja_trabajo/shared/widgets/service_card_skeleton.dart';

class ServiceListWidget extends ConsumerWidget {
  const ServiceListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);

    // 🚀 ENVOLVEMOS LA LISTA EN UNA COLUMNA PARA AGREGAR EL TÍTULO
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF10B981),
            onRefresh: () => ref.refresh(serviceListProvider.future), 
            child: servicesAsync.when(
              data: (services) => services.isEmpty 
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: const Center(child: Text("No hay servicios disponibles", style: TextStyle(color: Colors.grey))),
                      )
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(bottom: 80, top: 0), // 👈 Ajusté el padding top a 0 para que no choque con el título
                    itemCount: services.length,
                    itemBuilder: (context, index) => ServiceCard(service: services[index]),
                  ),
              
              loading: () => ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => const ServiceCardSkeleton(),
              ),
              
              error: (e, s) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Ocurrió un error. Desliza hacia abajo para reintentar.\n\nDetalle: $e", 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}