import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:forja_trabajo/features/payments/presentation/providers/wallet_status_provider.dart';
import 'package:forja_trabajo/features/payments/presentation/screens/wallet_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/marketplace_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/unread_count_provider.dart';
import '../worker/my_jobs_screen.dart';
import 'package:forja_trabajo/features/chat/presentation/screens/chat_list_screen.dart';
import '../worker/worker_profile_screen.dart';

class WorkerMainLayout extends ConsumerStatefulWidget {
  const WorkerMainLayout({super.key});

  @override
  ConsumerState<WorkerMainLayout> createState() => _WorkerMainLayoutState();
}

class _WorkerMainLayoutState extends ConsumerState<WorkerMainLayout> with WidgetsBindingObserver {
  bool _walletBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(walletStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(workerNavProvider);
    final unreadChatCount = ref.watch(unreadCountProvider);
    final walletStatus = ref.watch(walletStatusProvider).valueOrNull;
    final theme = Theme.of(context);

    final List<Widget> screens = [
      const MarketplaceScreen(),
      const ChatListScreen(),
      const MyJobsScreen(),
      const WorkerProfileScreen(),
    ];

    final showBanner = walletStatus != null && !walletStatus.isReady && !_walletBannerDismissed;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBanner)
            _walletBanner(context),
          NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              ref.read(workerNavProvider.notifier).state = index;
            },
            backgroundColor: theme.colorScheme.surface,
            elevation: 3,
            indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search, color: Color(0xFF1E1B4B)),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unreadChatCount > 0,
                  label: Text(
                    unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unreadChatCount > 0,
                  label: Text(
                    unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  child: const Icon(Icons.chat_bubble, color: Color(0xFF1E1B4B)),
                ),
                label: 'Mensajes',
              ),
              const NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work, color: Color(0xFF1E1B4B)),
                label: 'Mis Trabajos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: Color(0xFF1E1B4B)),
                label: 'Perfil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wallet, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              ),
              child: const Text(
                'Configura tu billetera para postularte',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _walletBannerDismissed = true),
          ),
        ],
      ),
    );
  }
}
