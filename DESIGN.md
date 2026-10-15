# Aadi Design System

Aadi is a **search-first rental marketplace**. The design language is a modern,
minimalist marketplace aesthetic on **Material 3**: neutral off-white surfaces, a
confident **teal** brand primary, and a warm **orange** accent used purposefully
for engagement, ratings, and highlights.

---

## Theme Configuration

- **Material 3** enabled (`useMaterial3: true`).
- Light & dark themes via `AppTheme.light()` / `AppTheme.dark()`.
- Type system: **Quicksand** via `google_fonts`.
- The `AadiColors` `ThemeExtension` is registered on both themes; read brand
  surfaces and outlines with `context.aadiColors`.

---

## Brand Colors

**Teal leads; orange is the single accent.** Keep the palette restricted to
teal, orange, and off-white neutrals — avoid introducing additional hues.

- **Primary — teal `#1FA6A0`**: brand base, primary CTAs, selected states,
  trust/verification, map markers, focus rings.
- **Accent — orange `#F59E42`**: engagement & highlights — favorites/saved,
  ratings, "Top rated"/promo badges, secondary CTAs, availability.

### Teal (primary)

| Token    | Hex       |
|----------|-----------|
| teal     | `#1FA6A0` |
| tealDark | `#0B3A38` |
| teal80   | `#8FD9D5` |
| teal90   | `#C4ECEA` |
| teal95   | `#E3F6F4` |

### Orange (accent)

| Token      | Hex       |
|------------|-----------|
| orange     | `#F59E42` |
| orangeDeep | `#D9822B` |
| orange90   | `#FCE6CE` |
| orange95   | `#FDF3E9` |

### Neutrals

| Token      | Hex       |
|------------|-----------|
| neutral0   | `#FFFFFF` |
| neutral10  | `#F7F8FA` |
| neutral20  | `#EDF0F4` |
| neutral30  | `#DDE2E9` |
| neutral60  | `#7D8794` |
| neutral80  | `#4A525E` |
| neutral100 | `#252A31` |

### Aliases (AppColors)

| Alias     | Maps to    |
|-----------|------------|
| primary   | teal       |
| secondary | orange     |
| accent    | orange     |
| surface   | neutral10  |
| textDark  | neutral100 |
| success   | teal       |
| danger    | orangeDeep |

### AadiColors (ThemeExtension)

Semantic brand surfaces and outlines, accessed via `context.aadiColors`.

| Token            | Light               | Dark      | Purpose                 |
|------------------|---------------------|-----------|-------------------------|
| surfacePrimary   | neutral0 `#FFFFFF`  | `#14201F` | Main content surface    |
| surfaceSecondary | neutral10 `#F7F8FA` | `#0F1B1A` | Secondary / field fills |
| surfaceTertiary  | teal95 `#E3F6F4`    | `#16302E` | Teal-tinted surface     |
| surfaceAccent    | orange95 `#FDF3E9`  | `#33240F` | Orange-tinted surface   |
| surfaceSuccess   | teal95 `#E3F6F4`    | `#16302E` | Success background      |
| surfaceDanger    | orange90 `#FCE6CE`  | `#3A2410` | Danger background       |
| outlineSubtle    | neutral20 `#EDF0F4` | `#283432` | Weak borders            |
| outlineDefault   | neutral30 `#DDE2E9` | `#35413F` | Standard borders        |
| outlineStrong    | orange `#F59E42`    | orange    | Strong emphasis border  |
| success          | teal `#1FA6A0`      | teal80    | Positive status         |
| warning          | orange `#F59E42`    | orange    | Cautionary status       |
| danger           | orangeDeep `#D9822B`| orange    | Error status            |
| verified         | teal `#1FA6A0`      | teal80    | Trust / verification    |

### ColorScheme — light

| Role               | Color                |
|--------------------|----------------------|
| primary            | teal `#1FA6A0`       |
| onPrimary          | neutral0 `#FFFFFF`   |
| primaryContainer   | teal90 `#C4ECEA`     |
| secondary          | orange `#F59E42`     |
| onSecondary        | neutral100 `#252A31` |
| secondaryContainer | orange95 `#FDF3E9`   |
| tertiary           | orange `#F59E42`     |
| error              | orangeDeep `#D9822B` |
| errorContainer     | orange90 `#FCE6CE`   |
| surface            | neutral0 `#FFFFFF`   |
| onSurface          | neutral100 `#252A31` |
| onSurfaceVariant   | neutral60 `#7D8794`  |
| outline            | neutral30 `#DDE2E9`  |

Scaffold background: neutral10 `#F7F8FA`.

### ColorScheme — dark

| Role             | Color              |
|------------------|--------------------|
| primary          | teal80 `#8FD9D5`   |
| onPrimary        | tealDark `#0B3A38` |
| secondary        | orange `#F59E42`   |
| surface          | `#0F1B1A`          |
| onSurface        | `#EAF2F1`          |
| onSurfaceVariant | `#B4C0BE`          |
| outline          | `#35413F`          |

Scaffold background: `#0B1413`.

---

## Typography

**Font:** Quicksand (via `google_fonts`), applied with
`AppTypography.textTheme(brightness)`.

| Style          | Size | Weight | Letter Spacing | Height |
|----------------|------|--------|----------------|--------|
| displayLarge   | 44px | 700    | -1.4px         | —      |
| displayMedium  | 36px | 700    | -1.0px         | —      |
| displaySmall   | 30px | 700    | -0.6px         | —      |
| headlineMedium | 24px | 700    | -0.4px         | —      |
| headlineSmall  | 20px | 600    | —              | —      |
| titleLarge     | 18px | 600    | —              | —      |
| titleMedium    | 16px | 600    | —              | —      |
| titleSmall     | 14px | 600    | —              | —      |
| bodyLarge      | 16px | 400    | —              | 1.4    |
| bodyMedium     | 14px | 400    | —              | 1.35   |
| bodySmall      | 12px | 400    | —              | 1.3    |
| labelLarge     | 14px | 700    | —              | —      |
| labelMedium    | 12px | 600    | —              | —      |
| labelSmall     | 11px | 600    | —              | —      |

**Prices** use `AppTypography.price(context)` — 20px / 700, `-0.4` tracking, and
`FontFeature.tabularFigures()` so digits stay column-aligned across cards.

---

## Spacing

An 8-point "comfy" rhythm (`AppSpacing`).

| Token | Value |
|-------|-------|
| xxs   | 2px   |
| xs    | 4px   |
| sm    | 8px   |
| md    | 16px  |
| lg    | 24px  |
| xl    | 32px  |
| xxl   | 48px  |
| xxxl  | 64px  |

**Usage:** `AppSpacing.md` (default padding), `AppSpacing.sm` (element gaps),
`AppSpacing.lg` (section margins).

---

## Radius

Corner-radius scale (`AppRadius`).

| Token      | Radius | Use Case                      |
|------------|--------|-------------------------------|
| extraSmall | 8px    | Small discrete elements       |
| small      | 12px   | Inputs, fields                |
| medium     | 16px   | Moderate containers, sheets   |
| large      | 20px   | Cards (default), bottom sheets|
| extraLarge | 28px   | Large feature surfaces        |
| pill       | 999px  | Buttons, chips, badges        |

Aliases: `sm` → small, `md` → medium, `lg` → large.

---

## Elevation

Subtle tonal shadows (`AppElevation`) — prefer tonal elevation over heavy
shadows. Shadow tint is `neutral100`.

| Token   | Blur | Offset | Use Case                  |
|---------|------|--------|---------------------------|
| none    | —    | —      | Flat surfaces (cards)     |
| low     | 8px  | 0,2    | Subtle raise              |
| medium  | 16px | 0,4    | Standard raised surface   |
| high    | 28px | 0,10   | Prominent / menus         |
| overlay | 40px | 0,16   | Floating sheets & dialogs |

---

## Accent Usage (orange)

Orange is the **single brand accent**. Use it deliberately so it reads as intent,
not decoration:

- **Favorites / saved** — filled heart, saved-search actions.
- **Ratings** — star icons on cards, detail, and reviews.
- **Highlight badges** — solid-orange "Top rated" / promo pills with `neutral100`
  text.
- **Secondary CTAs** — e.g. "Save search" as a warm tonal button beside the teal
  primary action.
- **Availability** — the "available" chip tint.

**Accessibility:** orange has low contrast on white, so never use it for body
text on light surfaces. Use it as a **fill** (orange background with `neutral100`
text ≈ 6.7:1) or as **icons paired with a text label** — never rely on the hue
alone to convey status.

---

## Component Library

Reusable Aadi widgets (`lib/shared/widgets/`, `lib/features/`).

### Rental components

| Component             | File                                          | Description                                                                                              |
|-----------------------|-----------------------------------------------|----------------------------------------------------------------------------------------------------------|
| ListingCard           | `shared/widgets/listing_card.dart`            | Image-led card: reserved 16:10 image, favorite control, `Verified` (teal) + `Top rated` (orange) badges, rating, price with billing unit |
| ResponsiveListingView | `shared/widgets/responsive_listing_view.dart` | Adaptive list/grid of listings with favorite toggles                                                     |
| Trust widgets         | `shared/widgets/trust.dart`                   | `TrustChip`, `PropertyTrustChip`, verified/rating chips (teal)                                            |
| App state views       | `shared/widgets/app_state_views.dart`         | `ListingListSkeleton`, `EmptyStateView`, `ErrorRetryView`                                                 |

### Sheets & flows

| Sheet           | File                                         | Purpose                                                                                     |
|-----------------|----------------------------------------------|---------------------------------------------------------------------------------------------|
| Filter sheet    | `features/tenant/filter_sheet.dart`          | Property type, price range, radius, availability; teal "Show results" primary + orange "Save search" secondary |
| Saved searches  | `features/tenant/saved_searches_sheet.dart`  | Reopen or manage saved queries                                                              |
| Location search | `features/tenant/*` (location search sheet)  | Nominatim place search with recenter                                                        |
| Contact sheet   | `features/tenant/listing_detail_screen.dart` | Owner contact (in-app messaging lands in R11)                                                |

### Card & chip states

Cards are elevation 0 with a 1px `outlineSubtle` border and `large` (20px)
radius. Chips are pill-shaped; the selected chip uses `primaryContainer` (teal).

---

## Material 3 Component Overrides

| Component       | Key Overrides                                                                            |
|-----------------|------------------------------------------------------------------------------------------|
| AppBar          | bg blends with scaffold, elevation none, `titleLarge`, not centered                      |
| Card            | bg surfacePrimary, elevation 0, `large` (20px) radius, 1px border                        |
| Chip            | pill shape, 1px `outlineDefault`, selected = `primaryContainer`                          |
| FilledButton    | pill (StadiumBorder), 16/24 padding, `labelLarge`                                        |
| ElevatedButton  | pill, elevation 0, 16/24 padding                                                         |
| OutlinedButton  | pill, 1px `outlineDefault`                                                               |
| FAB             | `large` radius, bg primary (teal), elevation 2                                           |
| InputDecoration | filled `surfaceSecondary`, `small` (12px) radius, focused teal 2px, error orangeDeep 2px |
| Divider         | `outlineSubtle`, 1px                                                                     |

---

## Listing Detail — Content Order

Gallery → identity & rating → price & availability → key facts → amenities →
description → owner (trust) → reviews → policies → sticky contact action.

The sticky bottom bar keeps the price and the primary **Contact owner** (teal)
action visible; the favorite toggle (orange when saved) sits in the app bar.

---

## Maps

Map tiles use **Mapbox raster styles** via `flutter_map`, configured centrally in
`lib/core/config/map_config.dart`:

- Light theme → `mapbox/light-v11`; dark theme → `mapbox/dark-v11` (selected by
  `Theme.of(context).brightness`).
- Minimal, low-clutter base (no bold colored roads) that still surfaces major
  landmark labels — close to a clean Google-Maps look.
- Property markers use the teal brand color.
- Place search / geocoding uses Nominatim (OpenStreetMap) — independent of the
  tile style.

---

## Required States

Substantial screens implement **loading, populated, empty, and recoverable
error** states, plus offline / stale / disabled / in-progress where relevant.
Guard against duplicate submissions on async actions.

---

## Screen Layout

- **Auth screens (login/registration) are vertically centered.** Short,
  single-purpose mobile screens (login, register, and similar focused forms)
  center their content on the screen rather than anchoring it to the top.
- Wrap the content in `LayoutBuilder` → `SingleChildScrollView` →
  `ConstrainedBox(minHeight: constraints.maxHeight)` → `Center`, so the form
  centers when it fits and scrolls when the keyboard is open or the viewport is
  short.
- Constrain the form width (`maxWidth: 440`) and use `MainAxisSize.min` so the
  layout stays comfortable on large phones, tablets, and web.

---

## Key Files

| File | Content |
|------|---------|
| `lib/core/theme/app_colors.dart`     | Color primitives, `AppColors`, `AadiColors` extension |
| `lib/core/theme/app_typography.dart` | Quicksand type scale & `price()`                      |
| `lib/core/theme/app_spacing.dart`    | Spacing scale                                         |
| `lib/core/theme/app_radius.dart`     | Corner-radius tokens                                  |
| `lib/core/theme/app_elevation.dart`  | Tonal shadow levels                                   |
| `lib/core/theme/app_theme.dart`      | `AppTheme.light()/dark()`, component overrides        |
| `lib/core/config/map_config.dart`    | Mapbox tile styles & attribution                      |
| `lib/shared/widgets/*.dart`          | ListingCard, trust, state views, responsive view      |
| `lib/main.dart`                      | App entry & theme wiring                              |
