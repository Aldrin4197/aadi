import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/enums.dart';

final selectedServiceProvider = StateProvider<AadiService?>((ref) => null);

class ServiceSelectionScreen extends ConsumerWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a service')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'What are you looking for today?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Aadi brings trusted rentals and opportunities together.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          for (final service in AadiService.values) ...[
            _ServiceCard(
              service: service,
              onTap: () => _select(context, ref, service),
            ),
            if (service != AadiService.values.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, AadiService service) {
    ref.read(selectedServiceProvider.notifier).state = service;
    context.push(AppRoutes.auth);
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final AadiService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (service) {
      AadiService.spaces => (Icons.home_work_rounded, AppColors.primary),
      AadiService.haul => (Icons.local_shipping_rounded, AppColors.accent),
      AadiService.raketeer => (Icons.handyman_rounded, AppColors.secondary),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(service.description),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
