import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env/app_env.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_screen.dart';
import '../provider/provider_dashboard_screen.dart';

/// Minimal home for a service whose marketplace browsing isn't built yet
/// (Aadi Haul, Aadi Raketeer). Still gives a plain user a real path to apply
/// for that service's provider role, same as Aadi Spaces landlords.
class ComingSoonServiceShell extends StatefulWidget {
  const ComingSoonServiceShell({
    super.key,
    required this.service,
    required this.providerKind,
  });

  final AadiService service;
  final ProviderKind providerKind;

  @override
  State<ComingSoonServiceShell> createState() => _ComingSoonServiceShellState();
}

class _ComingSoonServiceShellState extends State<ComingSoonServiceShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _ServiceHomeTab(service: widget.service, providerKind: widget.providerKind),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Home',
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

class _ServiceHomeTab extends ConsumerWidget {
  const _ServiceHomeTab({required this.service, required this.providerKind});

  final AadiService service;
  final ProviderKind providerKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).user;
    final status = user?.statusFor(providerKind) ?? VerificationStatus.none;

    if (AppEnv.current.isProviderUnlocked(user, providerKind)) {
      return ProviderDashboardScreen(category: service);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.spacesHome),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rocket_launch_outlined,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${service.name} is on its way',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                service.description,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ProviderCta(providerKind: providerKind, status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCta extends StatelessWidget {
  const _ProviderCta({required this.providerKind, required this.status});

  final ProviderKind providerKind;
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      VerificationStatus.verified => 'You\'re a verified ${providerKind.title}',
      VerificationStatus.pending => 'Application under review',
      VerificationStatus.rejected => 'Re-apply as ${providerKind.title}',
      VerificationStatus.none => 'Become a ${providerKind.title}',
    };
    final enabled = status != VerificationStatus.pending &&
        status != VerificationStatus.verified;

    return FilledButton.icon(
      onPressed: enabled
          ? () => context.push(AppRoutes.providerApply(providerKind))
          : null,
      icon: const Icon(Icons.badge_outlined),
      label: Text(label),
    );
  }
}
