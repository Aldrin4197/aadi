import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../domain/enums.dart';
import '../../domain/models/app_user.dart';
import '../auth/auth_controller.dart';

/// Shared profile tab for every account: identity, trust signals, provider
/// applications, and logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(user.email,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final kind in ProviderKind.values)
                          if (user.isVerifiedProvider(kind))
                            Chip(
                              label: Text(kind.title),
                              visualDensity: VisualDensity.compact,
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _TrustSection(user: user),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                for (final service in AadiService.values)
                  ListTile(
                    leading: Icon(_serviceIcon(service)),
                    title: Text(service.name),
                    subtitle: Text(service.description),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(_serviceHome(service)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                for (final kind in ProviderKind.values)
                  _ProviderTile(kind: kind, user: user),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.star_border_rounded),
                  title: const Text('Reviews'),
                  subtitle: const Text('Ratings & feedback (coming soon)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _soon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Theme'),
              subtitle: Text(_themeLabel(ref.watch(themeModeProvider))),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickTheme(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final chosen = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (v) => Navigator.of(dialogContext).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(_themeLabel(mode)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null) {
      await ref.read(themeModeProvider.notifier).setMode(chosen);
    }
  }

  IconData _serviceIcon(AadiService service) => switch (service) {
        AadiService.spaces => Icons.home_work_rounded,
        AadiService.haul => Icons.local_shipping_rounded,
        AadiService.raketeer => Icons.handyman_rounded,
      };

  String _serviceHome(AadiService service) => switch (service) {
        AadiService.spaces => AppRoutes.spacesHome,
        AadiService.haul => AppRoutes.haulHome,
        AadiService.raketeer => AppRoutes.raketeerHome,
      };

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming in a later milestone.')),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.kind, required this.user});

  final ProviderKind kind;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final status = user.statusFor(kind);
    final subtitle = switch (status) {
      VerificationStatus.verified => 'Verified',
      VerificationStatus.pending => 'Application under review',
      VerificationStatus.rejected => 'Application needs another look',
      VerificationStatus.none => 'Apply to unlock ${kind.title.toLowerCase()} tools',
    };
    return ListTile(
      leading: Icon(
        status == VerificationStatus.verified
            ? Icons.verified_user_rounded
            : Icons.verified_user_outlined,
      ),
      title: Text('${kind.title} on ${kind.service.name}'),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(AppRoutes.providerApply(kind)),
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trust', style: Theme.of(context).textTheme.titleMedium),
                if (user.isNewUser)
                  const Chip(
                    label: Text('New to Aadi'),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Chip(
                    avatar: const Icon(Icons.shield_rounded,
                        size: 18, color: AppColors.secondary),
                    label: Text('Trust score ${user.trustScore}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!user.isNewUser)
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.accent, size: 20),
                  Text(' ${user.ratingAverage.toStringAsFixed(1)} '
                      '(${user.ratingCount} reviews)'),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final badge in user.badges)
                  Chip(
                    avatar: Icon(
                      badge.isVerified
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded,
                      size: 18,
                      color: badge.isVerified
                          ? AppColors.secondary
                          : AppColors.accent,
                    ),
                    label: Text(_badgeLabel(badge.type)),
                    visualDensity: VisualDensity.compact,
                  ),
                if (user.badges.isEmpty)
                  const Text('No verification badges yet.'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _badgeLabel(BadgeType type) => switch (type) {
        BadgeType.emailVerified => 'Email',
        BadgeType.phoneVerified => 'Phone',
        BadgeType.idVerified => 'ID',
        BadgeType.landlordVerified => 'Landlord',
        BadgeType.propertyVerified => 'Property',
        BadgeType.reliableTenant => 'Reliable',
        BadgeType.responsive => 'Responsive',
      };
}
