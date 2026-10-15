import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/models/listing_query.dart';
import 'filter_sheet.dart';
import 'saved_searches_controller.dart';

/// Opens the saved-searches sheet and resolves to the chosen query, or null.
Future<ListingQuery?> showSavedSearchesSheet(BuildContext context) {
  return showModalBottomSheet<ListingQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const SavedSearchesSheet(),
  );
}

class SavedSearchesSheet extends ConsumerWidget {
  const SavedSearchesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final searchesAsync = ref.watch(savedSearchesProvider);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text('Saved searches', style: textTheme.titleLarge),
            ),
            Flexible(
              child: searchesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'We couldn\'t load your saved searches.',
                    style: textTheme.bodyMedium,
                  ),
                ),
                data: (searches) {
                  if (searches.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_border_rounded,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No saved searches yet',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Set filters, then tap "Save search" to keep them '
                            'here for quick access.',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    itemCount: searches.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final search = searches[i];
                      return ListTile(
                        leading: const Icon(Icons.bookmark_rounded),
                        title: Text(search.label),
                        subtitle: Text(
                          describeListingQuery(search.query),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete saved search',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => ref
                              .read(savedSearchesProvider.notifier)
                              .remove(search.id),
                        ),
                        onTap: () => Navigator.of(context).pop(search.query),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
