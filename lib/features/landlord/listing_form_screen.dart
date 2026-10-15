import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/map_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/listing.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/app_network_image.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/map_widgets.dart';
import '../auth/auth_controller.dart';
import '../tenant/listing_detail_screen.dart' show listingByIdProvider;
import '../tenant/location_search_sheet.dart' show showLocationSearchSheet;
import 'location_picker_screen.dart';
import 'my_listings_screen.dart' show myListingsProvider;
import '../provider/provider_listings_screen.dart' show providerListingsProvider;

/// Create/edit wizard entry. Resolves the listing for edit, else a blank form
/// scoped to [category] (Spaces/Haul/Raketeer).
class ListingFormScreen extends ConsumerWidget {
  const ListingFormScreen({
    super.key,
    this.listingId,
    this.category = AadiService.spaces,
  });

  final String? listingId;
  final AadiService category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = listingId;
    if (id == null) return _ListingForm(category: category);

    return ref
        .watch(listingByIdProvider(id))
        .when(
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Edit listing')),
            body: const ListingListSkeleton(),
          ),
          error: (_, __) => Scaffold(
            appBar: AppBar(title: const Text('Edit listing')),
            body: ErrorRetryView(
              message: 'We couldn\'t open this listing. Please try again.',
              onRetry: () => ref.invalidate(listingByIdProvider(id)),
            ),
          ),
          data: (listing) => _ListingForm(existing: listing),
        );
  }
}

class _ListingForm extends ConsumerStatefulWidget {
  const _ListingForm({this.existing, this.category = AadiService.spaces});

  final Listing? existing;
  final AadiService category;

  @override
  ConsumerState<_ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends ConsumerState<_ListingForm> {
  static const _stepTitles = ['Basics', 'Location', 'Details', 'Review'];
  static const _amenityOptions = [
    'Wi-Fi',
    'Air conditioning',
    'Parking',
    'Shared kitchen',
    'Private bathroom',
    'Laundry',
    'CCTV',
    '24/7 Security',
    'Water included',
    'Electricity included',
    'Furnished',
    'Pet friendly',
  ];

  final _pageController = PageController();
  final _basicsKey = GlobalKey<FormState>();
  final _locationKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _city;
  final _photoUrl = TextEditingController();
  final _customAmenity = TextEditingController();

  late ListingType _type;
  late ListingStatus _status;
  late final Set<String> _amenities;
  late final List<String> _photos;
  late double _lat;
  late double _lng;

  int _step = 0;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _price = TextEditingController(
      text: e != null ? e.price.toStringAsFixed(0) : '',
    );
    _description = TextEditingController(text: e?.description ?? '');
    _address = TextEditingController(text: e?.location.address ?? '');
    _city = TextEditingController(text: e?.location.city ?? '');
    _type = e?.type ?? ListingType.values.firstWhere(
      (t) => t.category == widget.category,
    );
    _status = e?.status ?? ListingStatus.active;
    _amenities = {...?e?.amenities};
    _photos = [...?e?.photos];
    _lat = e?.location.lat ?? AppConstants.fallbackLat;
    _lng = e?.location.lng ?? AppConstants.fallbackLng;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _title.dispose();
    _price.dispose();
    _description.dispose();
    _address.dispose();
    _city.dispose();
    _photoUrl.dispose();
    _customAmenity.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_step == 0 && !(_basicsKey.currentState?.validate() ?? false)) return;
    if (_step == 1 && !(_locationKey.currentState?.validate() ?? false)) return;
    if (_step < _stepTitles.length - 1) _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) {
      context.pop();
      return;
    }
    _goTo(_step - 1);
  }

  void _addPhoto() {
    final url = _photoUrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _photos.add(url);
      _photoUrl.clear();
    });
  }

  void _addCustomAmenity() {
    final value = _customAmenity.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _amenities.add(value);
      _customAmenity.clear();
    });
  }

  // The picker shows the live coordinates; keep them for submit only.
  void _setLocation(LatLng point) {
    _lat = point.latitude;
    _lng = point.longitude;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final repo = ref.read(listingRepositoryProvider);
    final user = ref.read(authControllerProvider).user;
    final base = widget.existing;
    final now = DateTime.now();

    final listing = Listing(
      id: base?.id ?? 'l_${now.millisecondsSinceEpoch}',
      ownerId: base?.ownerId ?? user?.id ?? 'unknown',
      ownerName: base?.ownerName ?? user?.name ?? 'You',
      title: _title.text.trim(),
      description: _description.text.trim(),
      type: _type,
      price: double.tryParse(_price.text.trim()) ?? 0,
      currency: base?.currency ?? '₱',
      location: GeoPoint(
        lat: _lat,
        lng: _lng,
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        city: _city.text.trim(),
      ),
      photos: List.unmodifiable(_photos),
      amenities: _amenities.toList(),
      status: _status,
      propertyVerification:
          base?.propertyVerification ?? VerificationStatus.none,
      ratingAverage: base?.ratingAverage ?? 0,
      ratingCount: base?.ratingCount ?? 0,
      createdAt: base?.createdAt ?? now,
    );

    try {
      if (_isEditing) {
        await repo.update(listing);
      } else {
        await repo.create(listing);
      }
      ref.invalidate(myListingsProvider);
      ref.invalidate(providerListingsProvider(_type.category));
      if (!mounted) return;
      showAppToast(
        context,
        _isEditing ? 'Listing updated.' : 'Listing published.',
        kind: ToastKind.success,
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppToast(
        context,
        'Couldn\'t save. Please try again.',
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit listing' : 'New listing'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _StepHeader(step: _step, titles: _stepTitles),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _BasicsStep(
                  formKey: _basicsKey,
                  title: _title,
                  price: _price,
                  description: _description,
                  category: widget.category,
                  type: _type,
                  onTypeChanged: (t) => setState(() => _type = t),
                ),
                _LocationStep(
                  formKey: _locationKey,
                  city: _city,
                  address: _address,
                  lat: _lat,
                  lng: _lng,
                  onLocationChanged: _setLocation,
                ),
                _DetailsStep(
                  options: _amenityOptions,
                  selected: _amenities,
                  onToggleAmenity: (a, on) => setState(() {
                    on ? _amenities.add(a) : _amenities.remove(a);
                  }),
                  customAmenity: _customAmenity,
                  onAddCustomAmenity: _addCustomAmenity,
                  status: _status,
                  onStatusChanged: (s) => setState(() => _status = s),
                  photos: _photos,
                  photoUrl: _photoUrl,
                  onAddPhoto: _addPhoto,
                  onRemovePhoto: (i) => setState(() => _photos.removeAt(i)),
                ),
                _ReviewStep(
                  title: _title.text,
                  type: _type,
                  price: _price.text,
                  city: _city.text,
                  address: _address.text,
                  status: _status,
                  amenities: _amenities,
                  photoCount: _photos.length,
                  onEditStep: _goTo,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FooterBar(
        step: _step,
        lastStep: _stepTitles.length - 1,
        submitting: _submitting,
        isEditing: _isEditing,
        onBack: _submitting ? null : _back,
        onNext: _next,
        onSubmit: _submit,
      ),
    );
  }
}

/// Linear progress + current step label.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.titles});

  final int step;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titles[step], style: textTheme.titleMedium),
              Text(
                'Step ${step + 1} of ${titles.length}',
                style: textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (step + 1) / titles.length,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicsStep extends StatelessWidget {
  const _BasicsStep({
    required this.formKey,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.type,
    required this.onTypeChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController title;
  final TextEditingController price;
  final TextEditingController description;
  final AadiService category;
  final ListingType type;
  final ValueChanged<ListingType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Cozy studio near the station',
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Give it a clear title (5+ characters)'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FieldLabel('Property type'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in ListingType.values.where(
                  (t) => t.category == category,
                ))
                  ChoiceChip(
                    label: Text(t.label),
                    selected: t == type,
                    onSelected: (_) => onTypeChanged(t),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Monthly price',
                prefixText: '₱ ',
                suffixText: '/month',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return (n == null || n <= 0) ? 'Enter a monthly price' : null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: description,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the space, inclusions, and house rules.',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Add a short description (10+ characters)'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationStep extends StatefulWidget {
  const _LocationStep({
    required this.formKey,
    required this.city,
    required this.address,
    required this.lat,
    required this.lng,
    required this.onLocationChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController city;
  final TextEditingController address;
  final double lat;
  final double lng;
  final ValueChanged<LatLng> onLocationChanged;

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  late LatLng _pin;

  @override
  void initState() {
    super.initState();
    _pin = LatLng(widget.lat, widget.lng);
  }

  Future<void> _openPicker() async {
    final result = await Navigator.of(context).push<GeoPoint>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerScreen(
          initial: GeoPoint(
            lat: _pin.latitude,
            lng: _pin.longitude,
            city: widget.city.text.trim().isEmpty
                ? null
                : widget.city.text.trim(),
            address: widget.address.text.trim().isEmpty
                ? null
                : widget.address.text.trim(),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    _applyPlace(result);
  }

  /// Looks up whatever city the host typed via Nominatim and applies the pick.
  Future<void> _searchCity() async {
    final result = await showLocationSearchSheet(
      context,
      initialQuery: widget.city.text.trim(),
    );
    if (result == null || !mounted) return;
    _applyPlace(result);
  }

  void _applyPlace(GeoPoint place) {
    setState(() => _pin = LatLng(place.lat, place.lng));
    widget.onLocationChanged(_pin);
    // Reflect the resolved place back into the editable City/Area fields.
    if (place.city != null && place.city!.isNotEmpty) {
      widget.city.text = place.city!;
    }
    if (place.address != null && place.address!.isNotEmpty) {
      widget.address.text = place.address!;
    }
    widget.formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return _StepBody(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: widget.city,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _searchCity(),
              decoration: InputDecoration(
                labelText: 'City',
                helperText: 'Type a city, then search to place it on the map',
                prefixIcon: const Icon(Icons.location_city_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search this city',
                  onPressed: _searchCity,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter the city' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: widget.address,
              decoration: const InputDecoration(
                labelText: 'Area / neighborhood (optional)',
                prefixIcon: Icon(Icons.map_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FieldLabel('Pin the exact location'),
            const SizedBox(height: AppSpacing.sm),
            _LocationPreview(
              pin: _pin,
              brightness: brightness,
              onEdit: _openPicker,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoNote(
              icon: Icons.push_pin_outlined,
              text:
                  'Search your city above or tap the map to drop the exact '
                  'pin. Pinned at ${_pin.latitude.toStringAsFixed(5)}, '
                  '${_pin.longitude.toStringAsFixed(5)}.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Static map preview of the current pin; tapping opens the full picker.
class _LocationPreview extends StatelessWidget {
  const _LocationPreview({
    required this.pin,
    required this.brightness,
    required this.onEdit,
  });

  final LatLng pin;
  final Brightness brightness;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: FlutterMap(
                key: ValueKey('${pin.latitude},${pin.longitude}'),
                options: MapOptions(
                  initialCenter: pin,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.tileUrlTemplate(brightness),
                    tileDimension: MapConfig.tileDimension,
                    zoomOffset: MapConfig.zoomOffset,
                    userAgentPackageName: MapConfig.userAgentPackageName,
                    maxZoom: 20,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pin,
                        width: 40,
                        height: 40,
                        child: const MapPin(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              right: AppSpacing.xs,
              bottom: AppSpacing.xxs,
              child: MapAttributionBox(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.sm,
              child: Center(
                child: Material(
                  elevation: 2,
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Search & adjust on map',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onEdit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.options,
    required this.selected,
    required this.onToggleAmenity,
    required this.customAmenity,
    required this.onAddCustomAmenity,
    required this.status,
    required this.onStatusChanged,
    required this.photos,
    required this.photoUrl,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(String amenity, bool selected) onToggleAmenity;
  final TextEditingController customAmenity;
  final VoidCallback onAddCustomAmenity;
  final ListingStatus status;
  final ValueChanged<ListingStatus> onStatusChanged;
  final List<String> photos;
  final TextEditingController photoUrl;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final extras = selected.where((a) => !options.contains(a)).toList();
    return _StepBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Availability'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in ListingStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: s == status,
                  onSelected: (_) => onStatusChanged(s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FieldLabel('Amenities'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final a in [...options, ...extras])
                FilterChip(
                  label: Text(a),
                  selected: selected.contains(a),
                  onSelected: (on) => onToggleAmenity(a, on),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customAmenity,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAddCustomAmenity(),
                  decoration: const InputDecoration(
                    labelText: 'Add another amenity',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                onPressed: onAddCustomAmenity,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add amenity',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FieldLabel('Photo gallery'),
          const SizedBox(height: AppSpacing.xs),
          _InfoNote(
            icon: Icons.photo_camera_outlined,
            text:
                'Add several photos to showcase the space — the first one is '
                'the cover. Paste image links for now; device uploads arrive '
                'with the connected API.',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: photoUrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAddPhoto(),
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://…',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add photo',
              ),
            ],
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              photos.length == 1
                  ? '1 photo · this is the cover'
                  : '${photos.length} photos · first is the cover',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) => _PhotoThumb(
                  url: photos[i],
                  isCover: i == 0,
                  onRemove: () => onRemovePhoto(i),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.title,
    required this.type,
    required this.price,
    required this.city,
    required this.address,
    required this.status,
    required this.amenities,
    required this.photoCount,
    required this.onEditStep,
  });

  final String title;
  final ListingType type;
  final String price;
  final String city;
  final String address;
  final ListingStatus status;
  final Set<String> amenities;
  final int photoCount;
  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0', 'en_US');
    final priceValue = double.tryParse(price.trim());
    final priceLabel = priceValue == null
        ? '—'
        : '₱${money.format(priceValue)}/month';
    final place = [
      if (address.trim().isNotEmpty) address.trim(),
      if (city.trim().isNotEmpty) city.trim(),
    ].join(', ');

    return _StepBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isEmpty ? 'Untitled listing' : title.trim(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${type.label} · $priceLabel',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ReviewRow(
                    icon: Icons.place_outlined,
                    text: place.isEmpty ? 'No location set' : place,
                  ),
                  _ReviewRow(
                    icon: Icons.event_available_outlined,
                    text: status.label,
                  ),
                  _ReviewRow(
                    icon: Icons.checklist_rounded,
                    text: amenities.isEmpty
                        ? 'No amenities added'
                        : '${amenities.length} amenities',
                  ),
                  _ReviewRow(
                    icon: Icons.photo_library_outlined,
                    text: photoCount == 0
                        ? 'No photos'
                        : '$photoCount photo${photoCount == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => onEditStep(0),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit details'),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: child,
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.step,
    required this.lastStep,
    required this.submitting,
    required this.isEditing,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final int step;
  final int lastStep;
  final bool submitting;
  final bool isEditing;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final onLast = step == lastStep;
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              child: Text(step == 0 ? 'Cancel' : 'Back'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: submitting ? null : (onLast ? onSubmit : onNext),
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      onLast
                          ? (isEditing ? 'Save changes' : 'Publish')
                          : 'Next',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.url,
    required this.onRemove,
    this.isCover = false,
  });

  final String url;
  final VoidCallback onRemove;
  final bool isCover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 120,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: AppNetworkImage(
              url: url,
              width: 120,
              height: 96,
              placeholder: (_) =>
                  Container(color: scheme.surfaceContainerHighest),
              error: (_) => Container(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 2,
            end: 2,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          if (isCover)
            PositionedDirectional(
              bottom: 2,
              start: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.extraSmall),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    'Cover',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
