import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/listing_query.dart';
import '../../domain/models/saved_search.dart';
import '../../shared/widgets/app_toast.dart';
import 'saved_searches_controller.dart';

final _money = NumberFormat('#,##0', 'en_US');

/// Human-readable summary of a query's filters, used for chips and labels.
String describeListingQuery(ListingQuery q) {
  final parts = <String>[q.type?.label ?? 'All types'];
  if (q.minPrice != null && q.maxPrice != null) {
    parts.add('₱${_money.format(q.minPrice)}–₱${_money.format(q.maxPrice)}');
  } else if (q.maxPrice != null) {
    parts.add('≤ ₱${_money.format(q.maxPrice)}');
  } else if (q.minPrice != null) {
    parts.add('≥ ₱${_money.format(q.minPrice)}');
  }
  parts.add('${q.radiusKm.round()} km');
  if (!q.availableOnly) parts.add('incl. unavailable');
  return parts.join(' · ');
}

/// True when the query differs from the baseline on price, radius, or
/// availability. Type is excluded because the category strip surfaces it.
bool queryHasAdvancedFilters(ListingQuery q) {
  return q.minPrice != null ||
      q.maxPrice != null ||
      q.radiusKm != AppConstants.exploreRadiusKm ||
      !q.availableOnly;
}

/// Opens the filter sheet and resolves to the edited query, or null if the
/// tenant dismissed it without applying.
Future<ListingQuery?> showFilterSheet(
  BuildContext context,
  ListingQuery current,
) {
  return showModalBottomSheet<ListingQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FilterSheet(current: current),
  );
}

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key, required this.current});

  final ListingQuery current;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  static const _priceMax = AppConstants.priceFilterMax;
  static const _radiusMin = AppConstants.radiusFilterMin;
  static const _radiusMax = AppConstants.radiusFilterMax;

  late ListingType? _type;
  late RangeValues _price;
  late double _radius;
  late bool _availableOnly;

  @override
  void initState() {
    super.initState();
    _resetFrom(widget.current);
  }

  void _resetFrom(ListingQuery q) {
    _type = q.type;
    _availableOnly = q.availableOnly;
    _radius = q.radiusKm.clamp(_radiusMin, _radiusMax);
    final start = (q.minPrice ?? 0).clamp(0.0, _priceMax);
    final end = (q.maxPrice ?? _priceMax).clamp(0.0, _priceMax);
    _price = RangeValues(start, end < start ? _priceMax : end);
  }

  ListingQuery _buildQuery() {
    final min = _price.start <= 0 ? null : _price.start;
    final max = _price.end >= _priceMax ? null : _price.end;
    return widget.current.copyWith(
      type: _type,
      clearType: _type == null,
      radiusKm: _radius,
      availableOnly: _availableOnly,
      minPrice: min,
      clearMinPrice: min == null,
      maxPrice: max,
      clearMaxPrice: max == null,
    );
  }

  void _reset() {
    setState(() {
      _resetFrom(
        ListingQuery(
          lat: widget.current.lat,
          lng: widget.current.lng,
          radiusKm: AppConstants.exploreRadiusKm,
        ),
      );
    });
  }

  Future<void> _save() async {
    final query = _buildQuery();
    final label = await _promptName(context, describeListingQuery(query));
    if (label == null || !mounted) return;

    await ref
        .read(savedSearchesProvider.notifier)
        .save(
          SavedSearch(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            label: label,
            query: query,
            createdAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    showAppToast(context, 'Search saved.', kind: ToastKind.success);
    Navigator.of(context).pop(query);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text('Filters', style: textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(widget.current.category == null
                        ? 'Type'
                        : '${widget.current.category!.name} type'),
                    const SizedBox(height: AppSpacing.sm),
                    _TypeChips(
                      category: widget.current.category,
                      selected: _type,
                      onSelect: (t) => setState(() => _type = t),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        _label('Price range'),
                        const Spacer(),
                        Text(_priceRangeLabel(), style: textTheme.bodyMedium),
                      ],
                    ),
                    RangeSlider(
                      values: _price,
                      min: 0,
                      max: _priceMax,
                      divisions: 100,
                      labels: RangeLabels(
                        '₱${_money.format(_price.start)}',
                        _price.end >= _priceMax
                            ? '₱${_money.format(_priceMax)}+'
                            : '₱${_money.format(_price.end)}',
                      ),
                      onChanged: (v) => setState(() => _price = v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _label('Search radius'),
                        const Spacer(),
                        Text(
                          '${_radius.round()} km',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Slider(
                      value: _radius,
                      min: _radiusMin,
                      max: _radiusMax,
                      divisions: (_radiusMax - _radiusMin).round(),
                      label: '${_radius.round()} km',
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available only'),
                      subtitle: const Text('Hide reserved and rented spaces'),
                      value: _availableOnly,
                      onChanged: (v) => setState(() => _availableOnly = v),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange90,
                        foregroundColor: AppColors.textDark,
                      ),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Save search'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_buildQuery()),
                      child: const Text('Show results'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);

  String _priceRangeLabel() {
    final start = '₱${_money.format(_price.start)}';
    final end = _price.end >= _priceMax
        ? '₱${_money.format(_priceMax)}+'
        : '₱${_money.format(_price.end)}';
    return '$start – $end';
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.category, required this.selected, required this.onSelect});

  final AadiService? category;
  final ListingType? selected;
  final ValueChanged<ListingType?> onSelect;

  @override
  Widget build(BuildContext context) {
    final types = category == null
        ? ListingType.values
        : ListingType.values.where((t) => t.category == category);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) => onSelect(null),
        ),
        for (final type in types)
          ChoiceChip(
            label: Text(type.label),
            selected: selected == type,
            onSelected: (_) => onSelect(type),
          ),
      ],
    );
  }
}

Future<String?> _promptName(BuildContext context, String suggestion) {
  final controller = TextEditingController(text: suggestion);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Name this search'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'e.g. Apartments near work',
        ),
        onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            Navigator.of(dialogContext).pop(value.isEmpty ? suggestion : value);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
