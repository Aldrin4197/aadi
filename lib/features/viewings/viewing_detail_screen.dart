import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/viewing_request.dart';
import '../../shared/widgets/app_network_image.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/app_toast.dart';
import '../auth/auth_controller.dart';
import '../tenant/listing_detail_screen.dart' show listingByIdProvider;
import 'viewing_schedule_sheet.dart';
import 'viewing_status_visuals.dart';
import 'viewings_controller.dart';

/// Full-screen detail for a single viewing request.
///
/// Serves both roles: the current user's relationship to the request (owner vs.
/// tenant) decides which actions are offered. Shows the listing, schedule, the
/// counterparty, and the tenant's note so either side can review before acting.
class ViewingDetailScreen extends ConsumerStatefulWidget {
  const ViewingDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<ViewingDetailScreen> createState() =>
      _ViewingDetailScreenState();
}

class _ViewingDetailScreenState extends ConsumerState<ViewingDetailScreen> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function() action, {
    String? toast,
    bool popAfter = false,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (toast != null) showAppToast(context, toast);
      if (popAfter && context.canPop()) context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirm(ViewingRequest r) => _run(
    () => ref.read(viewingsProvider.notifier).confirm(r.id),
    toast: 'Viewing confirmed.',
  );

  void _decline(ViewingRequest r) => _run(
    () => ref.read(viewingsProvider.notifier).decline(r.id),
    toast: 'Request declined.',
  );

  void _accept(ViewingRequest r) => _run(
    () => ref.read(viewingsProvider.notifier).acceptProposed(r.id),
    toast: 'New time accepted.',
  );

  void _remove(ViewingRequest r) => _run(
    () => ref.read(viewingsProvider.notifier).cancel(r.id),
    toast: 'Viewing request removed.',
    popAfter: true,
  );

  Future<void> _reschedule(ViewingRequest r, bool asLandlord) async {
    final picked = await pickViewingDateTime(context, initial: r.effectiveAt);
    if (picked == null) return;
    await _run(
      () => asLandlord
          ? ref.read(viewingsProvider.notifier).propose(r.id, picked)
          : ref.read(viewingsProvider.notifier).reschedule(r.id, picked),
      toast: asLandlord ? 'New time proposed.' : 'Viewing time updated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(viewingByIdProvider(widget.requestId));
    final me = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Request details')),
      body: request == null
          ? const EmptyStateView(
              icon: Icons.event_busy_outlined,
              title: 'Request unavailable',
              message:
                  'This viewing request is no longer available. It may have '
                  'been cancelled or removed.',
            )
          : _RequestDetailBody(
              request: request,
              asLandlord: request.ownerId == me,
              busy: _busy,
              onConfirm: () => _confirm(request),
              onDecline: () => _decline(request),
              onAccept: () => _accept(request),
              onRemove: () => _remove(request),
              onReschedule: (asLandlord) => _reschedule(request, asLandlord),
            ),
    );
  }
}

class _RequestDetailBody extends StatelessWidget {
  const _RequestDetailBody({
    required this.request,
    required this.asLandlord,
    required this.busy,
    required this.onConfirm,
    required this.onDecline,
    required this.onAccept,
    required this.onRemove,
    required this.onReschedule,
  });

  final ViewingRequest request;
  final bool asLandlord;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  final VoidCallback onRemove;
  final void Function(bool asLandlord) onReschedule;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasProposed =
        r.status == ViewingStatus.rescheduled && r.proposedAt != null;
    final note = r.note?.trim();
    final counterpartyName = asLandlord ? r.tenantName : r.ownerName;
    final counterpartyId = asLandlord ? r.tenantId : r.ownerId;

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _ListingTile(request: r),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    ViewingStatusAvatar(status: r.status),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ViewingStatusChip(status: r.status),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _statusSummary(asLandlord, r.status),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel('Schedule'),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  icon: Icons.event_rounded,
                  label: hasProposed ? 'Originally requested' : 'Viewing time',
                  value: viewingDateFormat.format(r.requestedAt),
                ),
                if (hasProposed) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.update_rounded,
                    label: 'Proposed new time',
                    value: viewingDateFormat.format(r.proposedAt!),
                    emphasized: true,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(asLandlord ? 'Requested by' : 'Host'),
                const SizedBox(height: AppSpacing.sm),
                _CounterpartyTile(
                  name: counterpartyName,
                  role: asLandlord ? 'Tenant' : 'Listing owner',
                  onTap: () =>
                      context.push(AppRoutes.userProfile(counterpartyId)),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(asLandlord ? 'Note from tenant' : 'Your note'),
                const SizedBox(height: AppSpacing.sm),
                _NoteCard(note: note),
                const SizedBox(height: AppSpacing.lg),
                _ActionButtons(
                  status: r.status,
                  asLandlord: asLandlord,
                  busy: busy,
                  onConfirm: onConfirm,
                  onDecline: onDecline,
                  onAccept: onAccept,
                  onRemove: onRemove,
                  onReschedule: () => onReschedule(asLandlord),
                ),
              ],
            ),
          ),
        ),
        if (busy)
          Positioned.fill(
            child: ColoredBox(
              color: scheme.scrim.withValues(alpha: 0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

/// Human-readable summary of what the current status means for this role.
String _statusSummary(
  bool asLandlord,
  ViewingStatus status,
) => switch (status) {
  ViewingStatus.pending =>
    asLandlord ? 'Awaiting your response.' : 'Waiting for the host to respond.',
  ViewingStatus.confirmed => 'This viewing is confirmed.',
  ViewingStatus.rescheduled =>
    asLandlord ? 'You proposed a new time.' : 'The host proposed a new time.',
  ViewingStatus.declined => 'This request was declined.',
};

/// Tappable listing summary that opens the full listing detail.
class _ListingTile extends ConsumerWidget {
  const _ListingTile({required this.request});

  final ViewingRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final listing = ref
        .watch(listingByIdProvider(request.listingId))
        .valueOrNull;
    final photo = (listing?.photos.isNotEmpty ?? false)
        ? listing!.photos.first
        : null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.listingDetail(request.listingId)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: photo == null
                      ? ColoredBox(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.home_work_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : AppNetworkImage(url: photo, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.listingTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'View listing',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase-ish section label.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }
}

/// A labelled icon + value row used in the schedule section.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = emphasized ? scheme.primary : scheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tappable row showing the counterparty with a link to their profile.
class _CounterpartyTile extends StatelessWidget {
  const _CounterpartyTile({
    required this.name,
    required this.role,
    required this.onTap,
  });

  final String name;
  final String role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primary.withValues(alpha: 0.14),
                child: Text(
                  initial,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      role,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tenant's note, or a muted placeholder when none was provided.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasNote = note != null && note!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Text(
        hasNote ? note! : 'No note provided.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: hasNote ? scheme.onSurface : scheme.onSurfaceVariant,
          fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }
}

/// Role- and status-aware action buttons for the request.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    required this.asLandlord,
    required this.busy,
    required this.onConfirm,
    required this.onDecline,
    required this.onAccept,
    required this.onRemove,
    required this.onReschedule,
  });

  final ViewingStatus status;
  final bool asLandlord;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  final VoidCallback onRemove;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buttons = <Widget>[];

    void primary(IconData icon, String label, VoidCallback onTap) {
      buttons.add(
        FilledButton.icon(
          onPressed: busy ? null : onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    void secondary(IconData icon, String label, VoidCallback onTap) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: busy ? null : onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    void danger(IconData icon, String label, VoidCallback onTap) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: busy ? null : onTap,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
          ),
        ),
      );
    }

    if (asLandlord) {
      switch (status) {
        case ViewingStatus.pending:
          primary(Icons.check_circle_outline_rounded, 'Confirm', onConfirm);
          secondary(
            Icons.edit_calendar_outlined,
            'Propose new time',
            onReschedule,
          );
          danger(Icons.close_rounded, 'Decline', onDecline);
        case ViewingStatus.rescheduled:
          primary(
            Icons.edit_calendar_outlined,
            'Change proposed time',
            onReschedule,
          );
          danger(Icons.close_rounded, 'Decline', onDecline);
        case ViewingStatus.confirmed:
          danger(Icons.event_busy_outlined, 'Cancel viewing', onDecline);
        case ViewingStatus.declined:
          danger(Icons.delete_outline_rounded, 'Remove', onRemove);
      }
    } else {
      switch (status) {
        case ViewingStatus.pending:
          secondary(Icons.edit_calendar_outlined, 'Reschedule', onReschedule);
          danger(Icons.close_rounded, 'Cancel request', onRemove);
        case ViewingStatus.rescheduled:
          primary(
            Icons.check_circle_outline_rounded,
            'Accept new time',
            onAccept,
          );
          secondary(Icons.edit_calendar_outlined, 'Reschedule', onReschedule);
          danger(Icons.close_rounded, 'Decline', onRemove);
        case ViewingStatus.confirmed:
          danger(Icons.event_busy_outlined, 'Cancel viewing', onRemove);
        case ViewingStatus.declined:
          primary(Icons.refresh_rounded, 'Request again', onReschedule);
          danger(Icons.delete_outline_rounded, 'Remove', onRemove);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          buttons[i],
        ],
      ],
    );
  }
}
