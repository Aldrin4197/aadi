// Core domain enumerations for Aadi.

enum AadiService { spaces, haul, raketeer }

/// The kind of provider a plain user can apply to become. Every account
/// starts as a plain user; verification unlocks the matching provider tools.
enum ProviderKind { landlord, vehicleOwner, raketeer }

enum ListingType {
  // Aadi Spaces
  bedspace,
  boardingHouse,
  apartment,
  house,
  commercial,
  // Aadi Haul (UV / vehicle rentals)
  multicab,
  van,
  jeepney,
  truck,
  // Aadi Raketeer (skilled / freelance services)
  homeCleaning,
  repairService,
  tutoringService,
  eventsStaffing,
}

enum ListingStatus {
  draft,
  active,
  reserved,
  rented,
  archived,
}

enum VerificationStatus { none, pending, verified, rejected }

enum BadgeType {
  emailVerified,
  phoneVerified,
  idVerified,
  landlordVerified,
  propertyVerified,
  reliableTenant,
  responsive,
}

enum ReviewDirection { tenantToLandlord, landlordToTenant }

enum ReviewStatus { active, flagged, removed }

/// A viewing (in-person visit) request's lifecycle for Aadi Spaces.
enum ViewingStatus { pending, confirmed, rescheduled, declined }

extension AadiServiceX on AadiService {
  String get name => switch (this) {
        AadiService.spaces => 'Aadi Spaces',
        AadiService.haul => 'Aadi Haul',
        AadiService.raketeer => 'Aadi Raketeer',
      };

  String get description => switch (this) {
        AadiService.spaces => 'Find or list places to live, work, and grow.',
        AadiService.haul => 'Rent public utility vehicles for your journey.',
        AadiService.raketeer => 'Find skilled workers or freelance work.',
      };
}

extension ProviderKindX on ProviderKind {
  String get title => switch (this) {
        ProviderKind.landlord => 'Landlord',
        ProviderKind.vehicleOwner => 'Vehicle Owner',
        ProviderKind.raketeer => 'Raketeer',
      };

  /// The service this provider role belongs to.
  AadiService get service => switch (this) {
        ProviderKind.landlord => AadiService.spaces,
        ProviderKind.vehicleOwner => AadiService.haul,
        ProviderKind.raketeer => AadiService.raketeer,
      };

  String get pitch => switch (this) {
        ProviderKind.landlord =>
          'List your spaces and reach the right tenants.',
        ProviderKind.vehicleOwner =>
          'List your vehicle and reach the right renters.',
        ProviderKind.raketeer =>
          'Publish your skills and get hired for jobs that fit you.',
      };
}

extension ListingTypeX on ListingType {
  String get label => switch (this) {
        ListingType.bedspace => 'Bedspace',
        ListingType.boardingHouse => 'Boarding House',
        ListingType.apartment => 'Apartment',
        ListingType.house => 'House',
        ListingType.commercial => 'Commercial',
        ListingType.multicab => 'Multicab',
        ListingType.van => 'Van',
        ListingType.jeepney => 'Jeepney',
        ListingType.truck => 'Truck',
        ListingType.homeCleaning => 'Home Cleaning',
        ListingType.repairService => 'Repair & Maintenance',
        ListingType.tutoringService => 'Tutoring',
        ListingType.eventsStaffing => 'Events Staffing',
      };

  /// Which Aadi service this offering type belongs to.
  AadiService get category => switch (this) {
        ListingType.bedspace ||
        ListingType.boardingHouse ||
        ListingType.apartment ||
        ListingType.house ||
        ListingType.commercial =>
          AadiService.spaces,
        ListingType.multicab ||
        ListingType.van ||
        ListingType.jeepney ||
        ListingType.truck =>
          AadiService.haul,
        ListingType.homeCleaning ||
        ListingType.repairService ||
        ListingType.tutoringService ||
        ListingType.eventsStaffing =>
          AadiService.raketeer,
      };

  /// The unit the price is quoted per, e.g. "mo" for a room, "day" for a
  /// vehicle, "job" for a service.
  String get defaultPriceUnit => switch (category) {
        AadiService.spaces => 'mo',
        AadiService.haul => 'day',
        AadiService.raketeer => 'job',
      };
}

extension ListingStatusX on ListingStatus {
  String get label => switch (this) {
        ListingStatus.draft => 'Draft',
        ListingStatus.active => 'Active',
        ListingStatus.reserved => 'Reserved',
        ListingStatus.rented => 'Rented',
        ListingStatus.archived => 'Archived',
      };
}

extension ViewingStatusX on ViewingStatus {
  String get label => switch (this) {
        ViewingStatus.pending => 'Pending',
        ViewingStatus.confirmed => 'Confirmed',
        ViewingStatus.rescheduled => 'Rescheduled',
        ViewingStatus.declined => 'Declined',
      };
}

extension BadgeTypeX on BadgeType {
  String get label => switch (this) {
        BadgeType.emailVerified => 'Email verified',
        BadgeType.phoneVerified => 'Phone verified',
        BadgeType.idVerified => 'ID verified',
        BadgeType.landlordVerified => 'Landlord verified',
        BadgeType.propertyVerified => 'Property verified',
        BadgeType.reliableTenant => 'Reliable tenant',
        BadgeType.responsive => 'Responsive',
      };

  String get shortLabel => switch (this) {
        BadgeType.emailVerified => 'Email',
        BadgeType.phoneVerified => 'Phone',
        BadgeType.idVerified => 'ID',
        BadgeType.landlordVerified => 'Landlord',
        BadgeType.propertyVerified => 'Property',
        BadgeType.reliableTenant => 'Reliable',
        BadgeType.responsive => 'Responsive',
      };
}

