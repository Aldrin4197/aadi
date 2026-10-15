import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env/app_env.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../auth/auth_controller.dart';
import '../landlord/landlord_dashboard_screen.dart';

/// The "Host" tab of the Aadi Spaces shell. A plain user sees an apply CTA;
/// a pending applicant sees a status card; a verified landlord sees the full
/// host dashboard (listings, drafts, viewing requests).
class HostTab extends ConsumerWidget {
  const HostTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final status = user?.statusFor(ProviderKind.landlord) ?? VerificationStatus.none;
    final unlocked = AppEnv.current.isProviderUnlocked(user, ProviderKind.landlord);

    return unlocked ? const LandlordDashboardScreen() : _HostGate(status: status);
  }
}

class _HostGate extends ConsumerWidget {
  const _HostGate({required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isPending = status == VerificationStatus.pending;
    final isRejected = status == VerificationStatus.rejected;

    return Scaffold(
      appBar: AppBar(title: const Text('Host')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPending
                    ? Icons.hourglass_top_rounded
                    : Icons.home_work_outlined,
                size: 56,
                color: isPending ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isPending
                    ? 'Application under review'
                    : isRejected
                        ? 'Application needs another look'
                        : 'List your spaces on Aadi',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isPending
                    ? 'We\'ll notify you once an admin reviews your documents.'
                    : 'Get verified as a landlord to post listings and manage '
                        'inquiries.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!isPending)
                FilledButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.providerApply(ProviderKind.landlord)),
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(isRejected ? 'Re-apply as Landlord' : 'Become a Landlord'),
                ),
              if (isPending && AppEnv.current.flavor == AppFlavor.dev) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(authControllerProvider)
                      .debugApproveProvider(ProviderKind.landlord),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Simulate approval (dev)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
