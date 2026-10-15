import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/viewing_request.dart';
import '../../shared/widgets/app_toast.dart';
import '../auth/auth_controller.dart';
import 'viewings_controller.dart';

/// Compact date + time formatter shared across the viewing screens, e.g.
/// "Tue, Aug 5 · 2:30 PM".
final viewingDateFormat = DateFormat('EEE, MMM d · h:mm a');

/// Prompts for a date and then a time, returning the combined [DateTime] or
/// `null` if the tenant backs out of either step.
Future<DateTime?> pickViewingDateTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  final base = initial ?? now.add(const Duration(days: 1));
  final firstDate = DateTime(now.year, now.month, now.day);
  final date = await showDatePicker(
    context: context,
    initialDate: base.isBefore(firstDate) ? firstDate : base,
    firstDate: firstDate,
    lastDate: now.add(const Duration(days: 90)),
    helpText: 'Select a viewing date',
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(base),
    helpText: 'Select a viewing time',
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Opens the bottom sheet that lets a tenant propose a viewing time.
Future<void> showScheduleViewingSheet(BuildContext context, Listing listing) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ScheduleViewingSheet(listing: listing),
  );
}

class _ScheduleViewingSheet extends ConsumerStatefulWidget {
  const _ScheduleViewingSheet({required this.listing});

  final Listing listing;

  @override
  ConsumerState<_ScheduleViewingSheet> createState() =>
      _ScheduleViewingSheetState();
}

class _ScheduleViewingSheetState extends ConsumerState<_ScheduleViewingSheet> {
  final _noteController = TextEditingController();
  DateTime? _when;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await pickViewingDateTime(context, initial: _when);
    if (picked != null) setState(() => _when = picked);
  }

  Future<void> _submit() async {
    final when = _when;
    final user = ref.read(authControllerProvider).user;
    if (when == null || user == null || _submitting) return;

    setState(() => _submitting = true);
    final note = _noteController.text.trim();
    final request = ViewingRequest(
      id: 'vr_${DateTime.now().millisecondsSinceEpoch}',
      listingId: widget.listing.id,
      listingTitle: widget.listing.title,
      tenantId: user.id,
      tenantName: user.name,
      ownerId: widget.listing.ownerId,
      ownerName: widget.listing.ownerName,
      requestedAt: when,
      status: ViewingStatus.pending,
      note: note.isEmpty ? null : note,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(viewingsProvider.notifier).submit(request);
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppToast(
        context,
        'Viewing requested. We\'ll let you know when '
        '${widget.listing.ownerName} responds.',
        kind: ToastKind.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppToast(
        context,
        'Couldn\'t send your request. Please try again.',
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final when = _when;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule a viewing', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Propose a time to see "${widget.listing.title}". '
              '${widget.listing.ownerName} will confirm or suggest another '
              'time.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date & time selector.
            InkWell(
              onTap: _submitting ? null : _pick,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      color: when == null
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferred date & time',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            when == null
                                ? 'Tap to choose'
                                : viewingDateFormat.format(when),
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Optional note.
            TextField(
              controller: _noteController,
              enabled: !_submitting,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                hintText: 'e.g. I can also come earlier if that helps.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (when == null || _submitting) ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Sending…' : 'Request viewing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
