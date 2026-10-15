import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Network image that renders reliably across platforms.
///
/// On web, CanvasKit decodes fetched bytes, so cross-origin URLs without CORS
/// headers fail to display. We fall back to an HTML `<img>` element, which the
/// browser can render without CORS. On mobile we keep [CachedNetworkImage]'s
/// disk caching.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.error,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? error;

  @override
  Widget build(BuildContext context) {
    final placeholderBuilder = placeholder ?? _fallback;
    final errorBuilder = error ?? placeholder ?? _fallback;

    if (kIsWeb) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholderBuilder(context),
        errorBuilder: (context, _, _) => errorBuilder(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, _) => placeholderBuilder(context),
      errorWidget: (context, _, _) => errorBuilder(context),
    );
  }

  Widget _fallback(BuildContext context) =>
      ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest);
}
