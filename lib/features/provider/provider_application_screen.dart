import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/env/app_env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../shared/widgets/app_toast.dart';
import '../auth/auth_controller.dart';

/// Generalized "become a provider" flow, shared by Landlord (Aadi Spaces),
/// Vehicle Owner (Aadi Haul), and Raketeer (Aadi Raketeer). A plain user
/// submits basic info plus supporting documents; an admin reviews and
/// verifies before the matching provider tools unlock.
class ProviderApplicationScreen extends ConsumerStatefulWidget {
  const ProviderApplicationScreen({super.key, required this.kind});

  final ProviderKind kind;

  @override
  ConsumerState<ProviderApplicationScreen> createState() =>
      _ProviderApplicationScreenState();
}

class _ProviderApplicationScreenState
    extends ConsumerState<ProviderApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _documents = [];
  bool _agreed = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickDocuments() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() => _documents.addAll(picked));
  }

  void _removeDocument(int index) {
    setState(() => _documents.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_documents.isEmpty) {
      showAppToast(
        context,
        'Attach at least one ID or document photo.',
        kind: ToastKind.error,
      );
      return;
    }
    if (!_agreed) {
      showAppToast(
        context,
        'Please confirm the verification terms to continue.',
        kind: ToastKind.error,
      );
      return;
    }

    final auth = ref.read(authControllerProvider);
    final ok = await auth.applyForProvider(
      kind: widget.kind,
      documentPaths: _documents.map((x) => x.path).toList(),
      note: _areaController.text.trim().isEmpty
          ? null
          : _areaController.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      showAppToast(
        context,
        'Application submitted for review.',
        kind: ToastKind.success,
      );
      context.pop();
    } else {
      final message = ref.read(authControllerProvider).error ?? 'Failed.';
      showAppToast(context, message, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final auth = ref.watch(authControllerProvider);
    final status = auth.user?.statusFor(kind) ?? VerificationStatus.none;

    return Scaffold(
      appBar: AppBar(title: Text('Become a ${kind.title}')),
      body: SafeArea(
        child: switch (status) {
          VerificationStatus.pending => _StatusView(kind: kind, status: status),
          VerificationStatus.verified => _StatusView(kind: kind, status: status),
          _ => _buildForm(context),
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final kind = widget.kind;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(kind.pitch, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tell us a bit about you and attach a document so we can verify '
              'your account.',
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _displayNameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: kind == ProviderKind.raketeer
                    ? 'Display name'
                    : 'Display / business name',
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter a name customers will see'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Contact phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => (v == null || v.trim().length < 7)
                  ? 'Enter a reachable phone number'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _areaController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: kind == ProviderKind.raketeer
                    ? 'Primary skill / service'
                    : 'Primary area / city',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'This helps us route the right jobs to you'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Verification documents', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'A government ID and, if applicable, proof of ownership or '
              'business permit.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < _documents.length; i++)
                  _DocumentThumb(
                    file: _documents[i],
                    onRemove: () => _removeDocument(i),
                  ),
                _AddDocumentTile(onTap: _pickDocuments),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I confirm these documents are accurate and agree to Aadi\'s '
                'verification policies.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit application'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusView extends ConsumerWidget {
  const _StatusView({required this.kind, required this.status});

  final ProviderKind kind;
  final VerificationStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isVerified = status == VerificationStatus.verified;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
              size: 56,
              color: isVerified ? AppColors.secondary : AppColors.accent,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isVerified
                  ? 'You\'re a verified ${kind.title}'
                  : 'Application under review',
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isVerified
                  ? 'Your ${kind.title.toLowerCase()} tools are unlocked.'
                  : 'We\'ll notify you once an admin reviews your documents.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (!isVerified && AppEnv.current.flavor == AppFlavor.dev) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider).debugApproveProvider(kind);
                  showAppToast(
                    context,
                    'Simulated approval applied.',
                    kind: ToastKind.success,
                  );
                },
                icon: const Icon(Icons.science_outlined),
                label: const Text('Simulate approval (dev)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddDocumentTile extends StatelessWidget {
  const _AddDocumentTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }
}

class _DocumentThumb extends StatelessWidget {
  const _DocumentThumb({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 88,
            height: 88,
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const ColoredBox(color: Color(0x11000000));
                }
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
