import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../shared/widgets/aadi_logo.dart';

/// Landing screen shown right after the splash: asks the user to log in to
/// an existing account or create a new one.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: AadiLogo(
                  variant: AadiLogoVariant.wordmark,
                  height: AadiLogo.compactHeight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.tagline,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.push(AppRoutes.auth, extra: false),
                child: const Text('Log in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.services),
                child: const Text('Create account'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
