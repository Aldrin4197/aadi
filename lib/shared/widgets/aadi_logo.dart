import 'package:flutter/material.dart';

/// Which Aadi brand asset to render.
enum AadiLogoVariant {
  /// Stacked mark + wordmark with the "your next space is here" tagline.
  full('assets/logos/Aadi_Color_w_tagname.png', 0.82),

  /// Stacked mark + "aadi" wordmark, no tagline.
  wordmark('assets/logos/Aadi_Color.png', 0.9),

  /// The house/"a" mark only.
  icon('assets/logos/Aadi_icon.png', 1.0);

  const AadiLogoVariant(this.asset, this.aspectRatio);

  final String asset;

  /// width / height, used to reserve layout space before the image decodes.
  final double aspectRatio;
}

/// Renders an Aadi logo with reserved dimensions and an accessible label.
class AadiLogo extends StatelessWidget {
  const AadiLogo({
    super.key,
    this.variant = AadiLogoVariant.wordmark,
    this.height = 96,
  });

  /// Large brand splash height (onboarding).
  static const double heroHeight = 300;

  /// Compact brand height for auth headers.
  static const double compactHeight = 120;

  final AadiLogoVariant variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Aadi',
      image: true,
      child: SizedBox(
        height: height,
        width: height * variant.aspectRatio,
        child: Image.asset(
          variant.asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              'aadi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
