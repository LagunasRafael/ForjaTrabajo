import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_card.dart';
import 'package:forja_trabajo/shared/widgets/service_card_skeleton.dart';

class ServiceListWidget extends ConsumerStatefulWidget {
  const ServiceListWidget({super.key});

  @override
  ConsumerState<ServiceListWidget> createState() => _ServiceListWidgetState();
}

class _ServiceListWidgetState extends ConsumerState<ServiceListWidget> {
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 12;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) return;

    final services = ref.read(serviceListProvider).valueOrNull ?? [];
    if (_visibleCount >= services.length) return;

    setState(() {
      _visibleCount = (_visibleCount + 12).clamp(0, services.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceListProvider);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF10B981),
            onRefresh: () async {
              setState(() => _visibleCount = 12);
              await ref.refresh(serviceListProvider.future);
            },
            child: servicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: const Center(
                          child: Text("No hay servicios disponibles",
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    ],
                  );
                }

                final displayCount = _visibleCount.clamp(0, services.length);
                final allLoaded = displayCount >= services.length;
                final showEndMarker = allLoaded && services.length > 12;

                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(bottom: 80, top: 0),
                  itemCount:
                      showEndMarker ? displayCount + 1 : displayCount,
                  itemBuilder: (context, index) {
                    if (index >= services.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text("Todos los trabajos cargados",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      );
                    }
                    return ServiceCard(service: services[index]);
                  },
                );
              },

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
