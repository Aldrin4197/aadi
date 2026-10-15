import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/viewing_request.dart';
import '../../shared/widgets/aadi_app_bar.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/app_toast.dart';
import 'viewing_schedule_sheet.dart';
import 'viewing_status_visuals.dart';
import 'viewings_controller.dart';

/// Lists viewing requests for the signed-in user.
///
/// The same screen serves both roles: tenants track requests they sent and can
/// accept a landlord's proposed time or cancel; landlords review incoming
/// requests and confirm, decline, or propose a new time. Each row can be
/// swiped left to reveal Edit (reschedule) and Delete actions, or tapped to
/// open the full request details.
class ViewingRequestsScreen extends ConsumerStatefulWidget {
  const ViewingRequestsScreen({super.key, required this.asLandlord});

  final bool asLandlord;

  @override
  ConsumerState<ViewingRequestsScreen> createState() =>
      _ViewingRequestsScreenState();
}

class _ViewingRequestsScreenState extends ConsumerState<ViewingRequestsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  bool get _asLandlord => widget.asLandlord;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) => setState(() => _search = value);

  void _clearSearch() {
    _searchController.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(
      _asLandlord ? incomingViewingsProvider : myViewingsProvider,
    );

    return Scaffold(
      appBar: const AadiAppBar(),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorRetryView(
          message: 'We couldn\'t load viewing requests. Please try again.',
          onRetry: () => ref.invalidate(viewingsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyStateView(
              icon: Icons.event_available_outlined,
              title: _asLandlord ? 'No viewing requests' : 'No viewings yet',
              message: _asLandlord
                  ? 'When tenants ask to view your listings, their requests '
                        'show up here for you to confirm or reschedule.'
                  : 'Ask to view a listing and you can track the landlord\'s '
                        'response here.',
            );
          }
          final query = _search.trim();
          final filtered = _filterViewings(list, query, _asLandlord);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: AppSearchField(
                      controller: _searchController,
                      hintText: _asLandlord
                          ? 'Search by tenant or listing'
                          : 'Search by listing or host',
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? _NoRequestMatches(query: query, onClear: _clearSearch)
                        : SlidableAutoCloseBehavior(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                0,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, i) => _ViewingCard(
                                request: filtered[i],
                                asLandlord: _asLandlord,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Filters viewing requests by listing title or the counterparty's name.
List<ViewingRequest> _filterViewings(
  List<ViewingRequest> list,
  String query,
  bool asLandlord,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return list;
  return list.where((r) {
    final counterparty = asLandlord ? r.tenantName : r.ownerName;
    return r.listingTitle.toLowerCase().contains(q) ||
        counterparty.toLowerCase().contains(q);
  }).toList();
}

/// Inline empty state shown when a search matches no requests.
class _NoRequestMatches extends StatelessWidget {
  const _NoRequestMatches({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No requests match "$query"',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onClear, child: const Text('Clear search')),
          ],
        ),
      ),
    );
  }
}

/// A single viewing request row.
class _ViewingCard extends ConsumerStatefulWidget {
  const _ViewingCard({required this.request, required this.asLandlord});

  final ViewingRequest request;
  final bool asLandlord;

  @override
  ConsumerState<_ViewingCard> createState() => _ViewingCardState();
}

class _ViewingCardState extends ConsumerState<_ViewingCard> {
  bool _busy = false;

  ViewingRequest get _r => widget.request;

  Future<void> _run(Future<void> Function() action, {String? toast}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && toast != null) showAppToast(context, toast);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancel() => _run(
    () => ref.read(viewingsProvider.notifier).cancel(_r.id),
    toast: 'Viewing request removed.',
  );

  /// Swipe "Edit": pick a new time. Landlords propose it to the tenant;
  /// tenants update their own pending request.
  Future<void> _reschedule() async {
    final picked = await pickViewingDateTime(context, initial: _r.effectiveAt);
    if (picked == null) return;
    await _run(
      () => widget.asLandlord
          ? ref.read(viewingsProvider.notifier).propose(_r.id, picked)
          : ref.read(viewingsProvider.notifier).reschedule(_r.id, picked),
      toast: widget.asLandlord ? 'New time proposed.' : 'Viewing time updated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final r = _r;
    final counterparty = widget.asLandlord
        ? 'From ${r.tenantName}'
        : 'With ${r.ownerName}';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        key: ValueKey(r.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.52,
          children: [
            SlidableAction(
              onPressed: (_) => _reschedule(),
              icon: Icons.edit_calendar_outlined,
              label: 'Edit',
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
            ),
            SlidableAction(
              onPressed: (_) => _cancel(),
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
            ),
          ],
        ),
        child: InkWell(
          onTap: _busy
              ? null
              : () => context.push(AppRoutes.viewingDetail(r.id)),
          child: Opacity(
            opacity: _busy ? 0.6 : 1,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  ViewingStatusAvatar(status: r.status),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.listingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                viewingDateFormat.format(r.effectiveAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          counterparty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ViewingStatusChip(status: r.status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
