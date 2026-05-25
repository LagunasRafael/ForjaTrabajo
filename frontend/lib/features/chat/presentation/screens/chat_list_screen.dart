import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_list_provider.dart';
import '../widgets/chat_list_view.dart'; // 👈 Importamos la lista separada

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatListProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Text("Mensajes", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 22)),
          actions: [
            IconButton(icon: Icon(Icons.search, color: theme.colorScheme.onSurface), onPressed: () {}),
            IconButton(icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface), onPressed: () {}),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF4F46E5),
            indicatorWeight: 3,
            tabs: [Tab(text: "Activos"), Tab(text: "Archivados")],
          ),
        ),
        body: chatState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
          error: (err, stack) => Center(child: Text("Error cargando chats: $err")),
          data: (chats) {
            final activeChats = chats.where((c) => c.isArchived != true).toList();
            final archivedChats = chats.where((c) => c.isArchived == true).toList();

            return TabBarView(
              children: [
                ChatListView(chats: activeChats, emptyMessage: "No tienes mensajes activos", isRefreshable: true),
                ChatListView(chats: archivedChats, emptyMessage: "No hay chats archivados", isRefreshable: false),
              ],
            );
          },
        ),
      ),
    );
  }
}