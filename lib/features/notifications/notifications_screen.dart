import 'package:flutter/material.dart';

import '../../shared/widgets/app_state_views.dart';

/// Notifications inbox. Real booking, message, and viewing alerts arrive with
/// the connected API; for now this shows an empty, reassuring state.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const EmptyStateView(
        icon: Icons.notifications_none_rounded,
        title: 'You\'re all caught up',
        message:
            'Booking updates, viewing responses, and messages will show up '
            'here.',
      ),
    );
  }
}
