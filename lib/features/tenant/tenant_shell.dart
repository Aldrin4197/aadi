import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers.dart';
import '../../shared/widgets/coming_soon_view.dart';
import '../profile/profile_screen.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'host_tab.dart';

/// Bottom-nav shell for Aadi Spaces. Every account sees the same shell;
/// verified landlords additionally see live host tools in the Host tab.
class TenantShell extends ConsumerWidget {
  const TenantShell({super.key});

  static const _tabs = [
    ExploreScreen(),
    FavoritesScreen(),
    HostTab(),
    ComingSoonView(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Messages',
      message: 'Chat with landlords arrives in a later milestone.',
    ),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tenantShellTabIndexProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(tenantShellTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work_rounded),
            label: 'Host',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
