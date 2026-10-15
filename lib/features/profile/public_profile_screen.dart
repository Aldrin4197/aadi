import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/app_user.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/listing_card.dart';
import '../../shared/widgets/profile_header.dart';
import '../../shared/widgets/trust.dart';
import '../auth/auth_controller.dart';

/// Public, read-only profile for any user (host or tenant). Reachable from a
/// listing's "Hosted by" card and from the owner's own "View public profile".
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).user;
    // Resolve your own profile from the session so "view my public profile"
    // works even for accounts not present in the public user directory.
    if (currentUser != null && currentUser.id == userId) {
      return _scaffold(context, currentUser, _ProfileBody(user: currentUser));
    }

    final userAsync = ref.watch(userByIdProvider(userId));
    return _scaffold(
      context,
      userAsync.valueOrNull,
      userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorRetryView(
          message: 'We couldn\'t load this profile. Please try again.',
          onRetry: () => ref.invalidate(userByIdProvider(userId)),
        ),
        data: (user) {
          if (user == null) {
            return const EmptyStateView(
              icon: Icons.person_off_outlined,
              title: 'Profile unavailable',
              message: 'This user is no longer available on Aadi.',
            );
          }
          return _ProfileBody(user: user);
        },
      ),
    );
  }

  Widget _scaffold(BuildContext context, AppUser? shareUser, Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Share profile',
            onPressed: () => _share(context, shareUser),
          ),
        ],
      ),
      body: body,
    );
  }

  void _share(BuildContext context, AppUser? user) {
    if (user == null) return;
    Clipboard.setData(ClipboardData(text: '${user.name} on Aadi'));
    showAppToast(context, 'Profile link copied.', kind: ToastKind.success);
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLandlord = user.canHostAsLandlord;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ProfileHeader(
              name: user.name,
              roleLabel: isLandlord ? 'Verified landlord' : 'Member',
              roleIcon: isLandlord
                  ? Icons.verified_user_outlined
                  : Icons.person_outline_rounded,
              roleHighlighted: isLandlord,
            ),
            const SizedBox(height: AppSpacing.lg),
            _TrustCard(user: user),
            if (isLandlord) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Listings by ${user.name.split(' ').first}',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _OwnerListings(ownerId: user.id),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trust', style: textTheme.titleMedium),
                TrustScoreChip(score: user.trustScore, isNew: user.isNewUser),
              ],
            ),
            if (!user.isNewUser) ...[
              const SizedBox(height: AppSpacing.sm),
              RatingLabel(average: user.ratingAverage, count: user.ratingCount),
            ],
            const SizedBox(height: AppSpacing.md),
            TrustBadgeList(
              badges: user.badges,
              emptyText: 'No verification badges yet.',
            ),
          ],
        ),
      ),
    );
  }
}

/// The host's currently active listings, with its own async states so a slow
/// or failed listings fetch doesn't block the profile header.
class _OwnerListings extends ConsumerWidget {
  const _OwnerListings({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeListingsByOwnerProvider(ownerId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const _InlineNote(
        icon: Icons.error_outline_rounded,
        text: 'Couldn\'t load listings.',
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return const _InlineNote(
            icon: Icons.home_work_outlined,
            text: 'No active listings right now.',
          );
        }
        return Column(
          children: [
            for (final listing in listings)
              ListingCard(
                listing: listing,
                onTap: () => context.push(AppRoutes.listingDetail(listing.id)),
              ),
          ],
        );
      },
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
