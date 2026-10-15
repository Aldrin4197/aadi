import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/viewing_request.dart';
import '../../shared/widgets/aadi_app_bar.dart';
import '../../shared/widgets/aadi_greeting_header.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/providers.dart';
import '../auth/auth_controller.dart';
import '../viewings/viewings_controller.dart';
import 'my_listings_screen.dart';

/// Landlord management tab: a quick pulse on listings and viewing activity.
class LandlordDashboardScreen extends ConsumerWidget {
  const LandlordDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);
    final requestsAsync = ref.watch(incomingViewingsProvider);

    return Scaffold(
      appBar: AadiAppBar(
        onBack: () =>
            ref.read(tenantShellTabIndexProvider.notifier).state = 0,
      ),
      body: _buildBody(context, ref, listingsAsync, requestsAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Listing>> listingsAsync,
    AsyncValue<List<ViewingRequest>> requestsAsync,
  ) {
    if (listingsAsync.isLoading || requestsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (listingsAsync.hasError || requestsAsync.hasError) {
      return ErrorRetryView(
        message: 'We couldn\'t load your insights. Please try again.',
        onRetry: () {
          ref.invalidate(myListingsProvider);
          ref.invalidate(viewingsProvider);
        },
      );
    }

    final listings = listingsAsync.value ?? const <Listing>[];
    final requests = requestsAsync.value ?? const <ViewingRequest>[];

    if (listings.isEmpty) {
      return EmptyStateView(
        icon: Icons.insights_rounded,
        title: 'No insights yet',
        message: 'Publish your first listing to start tracking activity here.',
        actionLabel: 'Create listing',
        onAction: () => context.push(AppRoutes.newListing),
      );
    }

    final active = listings
        .where((l) => l.status == ListingStatus.active)
        .length;
    final drafts = listings
        .where((l) => l.status == ListingStatus.draft)
        .length;
    final pending = requests
        .where((r) => r.status == ViewingStatus.pending)
        .length;
    final confirmed = requests
        .where((r) => r.status == ViewingStatus.confirmed)
        .length;

    final avgPrice =
        listings.map((l) => l.price).reduce((a, b) => a + b) / listings.length;
    final avgPriceLabel =
        '${listings.first.currency}${NumberFormat('#,##0', 'en_US').format(avgPrice)}';

    final landlordName = ref.watch(authControllerProvider).user?.name;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AadiGreetingHeader(
              name: landlordName,
              subtitle: 'Here\'s how your rentals are performing.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.home_work_rounded,
                          label: 'Active listings',
                          value: '$active',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          icon: Icons.edit_note_rounded,
                          label: 'Drafts',
                          value: '$drafts',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.schedule_rounded,
                          label: 'Pending requests',
                          value: '$pending',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          icon: Icons.event_available_rounded,
                          label: 'Confirmed viewings',
                          value: '$confirmed',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Average asking price',
                    value: avgPriceLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
