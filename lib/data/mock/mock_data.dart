import '../../domain/enums.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/provider_application.dart';
import '../../domain/models/trust_badge.dart';

/// Seed data used by the mock repositories during early development.
class MockData {
  MockData._();

  static final AppUser landlordMaria = AppUser(
    id: 'u_landlord_1',
    email: 'maria@aadi.app',
    name: 'Maria Santos',
    phone: '+63 917 000 1111',
    ratingAverage: 4.7,
    ratingCount: 23,
    trustScore: 88,
    providerApplications: [
      ProviderApplication(
        kind: ProviderKind.landlord,
        status: VerificationStatus.verified,
        submittedAt: DateTime(2025, 1, 20),
        decidedAt: DateTime(2025, 2, 1),
      ),
    ],
    badges: [
      TrustBadge(type: BadgeType.emailVerified, status: VerificationStatus.verified, grantedAt: DateTime(2025, 1, 5)),
      TrustBadge(type: BadgeType.phoneVerified, status: VerificationStatus.verified, grantedAt: DateTime(2025, 1, 6)),
      TrustBadge(type: BadgeType.landlordVerified, status: VerificationStatus.verified, grantedAt: DateTime(2025, 2, 1)),
    ],
  );

  static final AppUser landlordJose = AppUser(
    id: 'u_landlord_2',
    email: 'jose@aadi.app',
    name: 'Jose Dela Cruz',
    phone: '+63 917 000 2222',
    ratingAverage: 4.2,
    ratingCount: 8,
    trustScore: 71,
    providerApplications: [
      ProviderApplication(
        kind: ProviderKind.landlord,
        status: VerificationStatus.verified,
        submittedAt: DateTime(2025, 3, 1),
        decidedAt: DateTime(2025, 3, 10),
      ),
    ],
    badges: [
      TrustBadge(type: BadgeType.emailVerified, status: VerificationStatus.verified, grantedAt: DateTime(2025, 3, 10)),
      TrustBadge(type: BadgeType.idVerified, status: VerificationStatus.pending),
    ],
  );

  static final AppUser vehicleOwnerCarlo = AppUser(
    id: 'u_haul_1',
    email: 'carlo@aadi.app',
    name: 'Carlo Reyes',
    phone: '+63 917 000 3333',
    ratingAverage: 4.5,
    ratingCount: 14,
    trustScore: 80,
    providerApplications: [
      ProviderApplication(
        kind: ProviderKind.vehicleOwner,
        status: VerificationStatus.verified,
        submittedAt: DateTime(2026, 4, 1),
        decidedAt: DateTime(2026, 4, 5),
      ),
    ],
    badges: [
      TrustBadge(type: BadgeType.emailVerified, status: VerificationStatus.verified, grantedAt: DateTime(2026, 4, 1)),
      TrustBadge(type: BadgeType.phoneVerified, status: VerificationStatus.verified, grantedAt: DateTime(2026, 4, 2)),
    ],
  );

  static final AppUser raketeerLiza = AppUser(
    id: 'u_raketeer_1',
    email: 'liza@aadi.app',
    name: 'Liza Fernandez',
    phone: '+63 917 000 4444',
    ratingAverage: 4.9,
    ratingCount: 31,
    trustScore: 91,
    providerApplications: [
      ProviderApplication(
        kind: ProviderKind.raketeer,
        status: VerificationStatus.verified,
        submittedAt: DateTime(2026, 3, 15),
        decidedAt: DateTime(2026, 3, 18),
      ),
    ],
    badges: [
      TrustBadge(type: BadgeType.emailVerified, status: VerificationStatus.verified, grantedAt: DateTime(2026, 3, 15)),
      TrustBadge(type: BadgeType.idVerified, status: VerificationStatus.verified, grantedAt: DateTime(2026, 3, 17)),
    ],
  );

  /// All seeded users, used by [MockUserRepository] to resolve public profiles.
  static List<AppUser> users() =>
      [landlordMaria, landlordJose, vehicleOwnerCarlo, raketeerLiza];

  static List<Listing> listings() => [
        Listing(
          id: 'l_1',
          ownerId: landlordMaria.id,
          ownerName: landlordMaria.name,
          title: 'Cozy Bedspace near University Belt',
          description:
              'Affordable bedspace for students. Includes bed, cabinet, shared kitchen and Wi-Fi. Walking distance to campuses.',
          type: ListingType.bedspace,
          price: 3500,
          location: const GeoPoint(lat: 14.6042, lng: 120.9822, address: 'Sampaloc', city: 'Manila'),
          amenities: const ['Wi-Fi', 'Shared kitchen', 'Laundry', 'CCTV'],
          propertyVerification: VerificationStatus.verified,
          ratingAverage: 4.6,
          ratingCount: 12,
          createdAt: DateTime(2026, 6, 20),
        ),
        Listing(
          id: 'l_2',
          ownerId: landlordMaria.id,
          ownerName: landlordMaria.name,
          title: '1-Bedroom Apartment with Balcony',
          description:
              'Bright and airy 1BR apartment, semi-furnished, near transport hubs and malls. Ideal for young professionals.',
          type: ListingType.apartment,
          price: 12000,
          location: const GeoPoint(lat: 14.5896, lng: 120.9803, address: 'Ermita', city: 'Manila'),
          amenities: const ['Balcony', 'Parking', 'Air conditioning', '24/7 Security'],
          propertyVerification: VerificationStatus.verified,
          ratingAverage: 4.8,
          ratingCount: 9,
          createdAt: DateTime(2026, 7, 2),
        ),
        Listing(
          id: 'l_3',
          ownerId: landlordJose.id,
          ownerName: landlordJose.name,
          title: 'Boarding House Room for Rent',
          description:
              'Clean private room in a quiet boarding house. Curfew applies. Utilities shared. Great for working students.',
          type: ListingType.boardingHouse,
          price: 5000,
          location: const GeoPoint(lat: 14.6120, lng: 120.9940, address: 'Santa Cruz', city: 'Manila'),
          amenities: const ['Wi-Fi', 'Water included', 'Common area'],
          propertyVerification: VerificationStatus.none,
          ratingAverage: 4.1,
          ratingCount: 5,
          createdAt: DateTime(2026, 7, 10),
        ),
        Listing(
          id: 'l_4',
          ownerId: landlordJose.id,
          ownerName: landlordJose.name,
          title: 'Commercial Space along Main Road',
          description:
              'Ground-floor commercial unit suitable for a café, store, or office. High foot traffic and visible frontage.',
          type: ListingType.commercial,
          price: 28000,
          location: const GeoPoint(lat: 14.5820, lng: 120.9770, address: 'Malate', city: 'Manila'),
          amenities: const ['Storefront', 'Parking', 'Restroom'],
          propertyVerification: VerificationStatus.pending,
          ratingAverage: 0,
          ratingCount: 0,
          createdAt: DateTime(2026, 7, 25),
        ),
        // Aadi Haul (UV / vehicle rentals)
        Listing(
          id: 'l_5',
          ownerId: vehicleOwnerCarlo.id,
          ownerName: vehicleOwnerCarlo.name,
          title: 'Multicab for Rent (Self-Drive or with Driver)',
          description:
              'Well-maintained multicab, ideal for hauling goods or group transport around the city.',
          type: ListingType.multicab,
          price: 1800,
          location: const GeoPoint(lat: 14.5960, lng: 120.9830, address: 'Ermita', city: 'Manila'),
          amenities: const ['Fuel-efficient', 'Driver available', 'Insured'],
          propertyVerification: VerificationStatus.verified,
          ratingAverage: 4.5,
          ratingCount: 14,
          createdAt: DateTime(2026, 7, 15),
        ),
        Listing(
          id: 'l_6',
          ownerId: vehicleOwnerCarlo.id,
          ownerName: vehicleOwnerCarlo.name,
          title: '12-Seater Van for Trips and Transfers',
          description:
              'Air-conditioned van for out-of-town trips, airport transfers, or company outings.',
          type: ListingType.van,
          price: 4500,
          location: const GeoPoint(lat: 14.6010, lng: 120.9880, address: 'Quiapo', city: 'Manila'),
          amenities: const ['Air conditioning', 'Driver included', '12 seats'],
          propertyVerification: VerificationStatus.verified,
          ratingAverage: 4.7,
          ratingCount: 8,
          createdAt: DateTime(2026, 7, 22),
        ),
        // Aadi Raketeer (skilled / freelance services)
        Listing(
          id: 'l_7',
          ownerId: raketeerLiza.id,
          ownerName: raketeerLiza.name,
          title: 'Deep Home Cleaning Service',
          description:
              'Thorough home cleaning for condos and houses. Bring my own supplies and equipment.',
          type: ListingType.homeCleaning,
          price: 1200,
          location: const GeoPoint(lat: 14.5890, lng: 120.9760, address: 'Malate', city: 'Manila'),
          amenities: const ['Own supplies', 'Flexible schedule'],
          propertyVerification: VerificationStatus.verified,
          ratingAverage: 4.9,
          ratingCount: 22,
          createdAt: DateTime(2026, 7, 18),
        ),
        Listing(
          id: 'l_8',
          ownerId: raketeerLiza.id,
          ownerName: raketeerLiza.name,
          title: 'Appliance Repair & Maintenance',
          description:
              'Certified technician for aircon, refrigerator, and washing machine repair.',
          type: ListingType.repairService,
          price: 800,
          location: const GeoPoint(lat: 14.6080, lng: 120.9900, address: 'Santa Cruz', city: 'Manila'),
          amenities: const ['Same-day service', 'Warranty on labor'],
          propertyVerification: VerificationStatus.verified,
          ratingAverage: 4.8,
          ratingCount: 17,
          createdAt: DateTime(2026, 7, 28),
        ),
      ];
}
