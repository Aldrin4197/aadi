import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// A compact, filled search input used across management lists (listings,
/// viewing requests). Filled and borderless so it sits calmly inside a list.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = controller.text.isNotEmpty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.large),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
    );
  }
}
