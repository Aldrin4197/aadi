import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/auth_controller.dart';
import 'aadi_logo.dart';

/// App-wide top bar: the brand logo and wordmark sit upper-left; notifications
/// and the account avatar sit upper-right. The brand is shown on every screen
/// instead of a per-page title. Screens can inject their own [actions], which
/// render just before the standard notifications/profile pair.
class AadiAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AadiAppBar({
    super.key,
    this.actions = const [],
    this.showNotifications = true,
    this.showProfile = true,
    this.onBack,
  });

  /// Screen-specific actions placed before the notifications/profile pair.
  final List<Widget> actions;

  final bool showNotifications;
  final bool showProfile;

  /// When set, shows a back arrow instead of the brand mark — for screens
  /// reached without a route to pop (e.g. a bottom-nav tab).
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final theme = Theme.of(context);

    return AppBar(
      titleSpacing: 0,
      leadingWidth: 64,
      leading: onBack != null
          ? Center(
              child: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
              ),
            )
          : const Padding(
              padding: EdgeInsets.only(left: AppSpacing.md),
              child: Center(
                child: AadiLogo(variant: AadiLogoVariant.icon, height: 28),
              ),
            ),
      title: Text(
        AppConstants.appName.toLowerCase(),
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        ...actions,
        if (showNotifications)
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        if (showProfile) _ProfileAvatarButton(initial: _initialOf(user?.name)),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  static String _initialOf(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }
}

/// Round account entry point in the app bar. Opens the signed-in user's
/// profile; keeps a 48x48 touch target for accessibility.
class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Your profile',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          final id = ref.read(authControllerProvider).user?.id;
          if (id != null) context.push(AppRoutes.userProfile(id));
        },
        child: Semantics(
          button: true,
          label: 'Your profile',
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
