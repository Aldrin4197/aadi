import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Visual intent of a toast, controlling the leading icon accent.
enum ToastKind { neutral, success, error }

/// Shows a lightweight, auto-dismissing toast anchored near the bottom of the
/// screen. Replaces `SnackBar` for transient feedback across the app.
///
/// Toasts stack no more than one at a time: showing a new one replaces any
/// visible toast. Tapping a toast dismisses it early.
void showAppToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.neutral,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _ToastController.instance.show(overlay, message, kind);
}

/// Tracks the single active toast so a new one replaces the previous.
class _ToastController {
  _ToastController._();
  static final instance = _ToastController._();

  OverlayEntry? _entry;

  void show(OverlayState overlay, String message, ToastKind kind) {
    _entry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastView(
        message: message,
        kind: kind,
        onDismissed: () {
          if (identical(_entry, entry)) _entry = null;
          entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    required this.kind,
    required this.onDismissed,
  });

  final String message;
  final ToastKind kind;
  final VoidCallback onDismissed;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  static const _visible = Duration(seconds: 3);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(_visible, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final accent = switch (widget.kind) {
      ToastKind.neutral => null,
      ToastKind.success => scheme.primary,
      ToastKind.error => scheme.error,
    };
    final icon = switch (widget.kind) {
      ToastKind.neutral => null,
      ToastKind.success => Icons.check_circle_rounded,
      ToastKind.error => Icons.error_rounded,
    };

    return Positioned.fill(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(curved),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 560),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.inverseSurface,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: accent),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Flexible(
                            child: Text(
                              widget.message,
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onInverseSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
