# Aadi logo & brand assets

Upload your logo and brand image files into these folders. They are wired into
`pubspec.yaml` under `flutter > assets`, so anything placed here is bundled.

## Where to put things

| Folder | What goes here |
|--------|----------------|
| `assets/logos/` | Primary logo, secondary logo, horizontal/vertical lockups, monochrome/white variants (SVG or PNG) |
| `assets/images/` | Illustrations, onboarding art, placeholders |
| `assets/icons/`  | In-app custom icons |

## Recommended logo files

Drop these exact names so the app can reference them consistently:

- `assets/logos/aadi_logo.png` — primary full-color logo (transparent PNG)
- `assets/logos/aadi_logo_white.png` — white/monochrome for dark or colored backgrounds
- `assets/logos/aadi_mark.png` — standalone "A" app mark / icon (square, transparent)
- `assets/logos/aadi_wordmark.png` — wordmark only

> PNGs should be transparent and at least 512×512 (mark) / 1024px wide (lockups).
> SVGs are also supported if you later add the `flutter_svg` package.

## App launcher icon (home-screen icon)

The launcher icon is separate from in-app images. To set it, add a
1024×1024 `assets/logos/aadi_mark.png`, then we can wire the
`flutter_launcher_icons` package to generate Android/iOS icons automatically.
Tell me when the file is in place and I'll configure it.
