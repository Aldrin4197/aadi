# Property Rental Listing — Data & API Spec

Source of truth for what the app collects when creating/editing a rental
listing, so the backend API can be designed to match. Derived from the current
Flutter code:

- Model: `lib/domain/models/listing.dart`, `lib/domain/models/geo_point.dart`
- Enums: `lib/domain/enums.dart`
- Create/edit wizard: `lib/features/landlord/listing_form_screen.dart`
- Repository contract: `lib/domain/repositories/listing_repository.dart`

Status legend: **Current** = already in the model/app today. **Proposed** =
not yet built but expected before/at the real-API swap (R12).

---

## 1. Create flow (what the landlord fills in)

The "New listing" wizard has 4 steps:

1. **Basics** — title, property type, monthly price, description
2. **Location** — city (required), area/neighborhood (optional); exact map pin
   is deferred to a later milestone (lat/lng currently default to a city point)
3. **Details** — amenities (presets + custom), availability status, photos
4. **Review** — read-only summary, then Publish

---

## 2. Listing fields

### 2a. Client-provided (sent to the API on create/update)

| Field | Type | Required | Validation (current) | Notes |
|---|---|---|---|---|
| `title` | string | yes | trimmed length ≥ 5 | e.g. "Cozy studio near the station" |
| `description` | string | yes | trimmed length ≥ 10 | space, inclusions, house rules |
| `type` | enum `ListingType` | yes | one of the enum values | default `apartment` |
| `price` | number | yes | parses to number > 0; UI is digits-only | interpreted as **monthly** rate today |
| `currency` | string | yes | — | hardcoded `₱` in UI; send explicitly for future multi-currency |
| `location.city` | string | yes | non-empty | |
| `location.address` | string | no | — | area / neighborhood; `null` when blank |
| `location.lat` | number | yes | — | defaults to `14.5995` (Manila) until pin-drop UI lands |
| `location.lng` | number | yes | — | defaults to `120.9842` (Manila) until pin-drop UI lands |
| `photos` | string[] | no | — | currently a list of image **URLs** (see §5 gap) |
| `amenities` | string[] | no | — | free-form strings; presets in §3 |
| `status` | enum `ListingStatus` | yes | one of the enum values | default `active` |

### 2b. Server-owned (the API sets/returns these — client must NOT trust client input)

| Field | Type | Notes |
|---|---|---|
| `id` | string | server-generated. App uses a temp `l_<epochMillis>` until saved |
| `ownerId` | string | from the authenticated user |
| `ownerName` | string | denormalized from the owner profile for card/detail display |
| `propertyVerification` | enum `VerificationStatus` | admin/verification workflow only; default `none` |
| `ratingAverage` | number | derived from reviews (0 when none) |
| `ratingCount` | integer | derived from reviews (0 when none) |
| `createdAt` | datetime (ISO 8601) | set on create |

---

## 3. Amenity presets (UI chips)

Free-form strings; these 12 are offered as quick-select chips, plus a custom
"add your own" input:

`Wi-Fi`, `Air conditioning`, `Parking`, `Shared kitchen`, `Private bathroom`,
`Laundry`, `CCTV`, `24/7 Security`, `Water included`, `Electricity included`,
`Furnished`, `Pet friendly`

> Recommendation: store amenities as a normalized/enumerated set on the API
> (stable keys + display labels) so filtering and localization stay consistent,
> while still allowing custom extras.

---

## 4. Enumerations

| Enum | Values (wire name → label) |
|---|---|
| `ListingType` | `bedspace`→Bedspace, `boardingHouse`→Boarding House, `apartment`→Apartment, `house`→House, `commercial`→Commercial |
| `ListingStatus` | `draft`, `active`, `reserved`, `rented`, `archived` |
| `VerificationStatus` | `none`, `pending`, `verified`, `rejected` |

`isAvailable` = `status == active`. `isVerified` = `propertyVerification == verified`.

Send/receive enums by their **wire name** (e.g. `"boardingHouse"`), not the label.

---

## 5. Known gaps / decisions needed for the API

These are collected while building the mock so they aren't missed when the real
API is designed (many map to later milestones):

- **Photo upload.** The app currently stores photo **URLs**. The API needs an
  upload endpoint (multipart or presigned URL), image storage/CDN, a **cover
  photo** designation, and stable ordering. Consider max count and size limits.
- **Exact location pin.** `lat`/`lng` default to a city centroid today; the
  map pin-drop UI is a later milestone. Decide precision to store and whether to
  fuzz the public pin for privacy (the detail map already shows "general area").
- **Billing unit.** Price is treated as **monthly** everywhere. If nightly/weekly
  or per-bed pricing is ever needed, add a `billingPeriod`/unit field.
- **Deposit & fees.** Checkout (Phase B) itemizes base rate, fees, taxes,
  **deposit**, and discounts — none of these exist on the listing yet.
- **Availability calendar.** Booking flow selects availability; the listing has
  no availability dates/calendar model yet.
- **Property facts.** No fields yet for rooms, bathrooms, capacity/occupancy,
  floor area, or furnishing level beyond amenity chips.
- **Policies / house rules.** The detail page shows a "Good to know" section
  that is currently static; add structured policy fields if needed.
- **`updatedAt`.** No update timestamp yet; add for cache invalidation (R9 drift).
- **Currency.** Hardcoded `₱`; keep the field on the API for future flexibility.

---

## 6. Suggested endpoints (align mock ↔ real)

Mirrors the current `ListingRepository` contract:

| Op | Method + path | Body / query | Returns |
|---|---|---|---|
| Search | `GET /listings` | query: `lat`, `lng`, `radiusKm`, `type?`, `minPrice?`, `maxPrice?`, `availableOnly` (default true) | `Listing[]`, distance-sorted |
| Detail | `GET /listings/{id}` | — | `Listing` |
| By owner | `GET /listings?ownerId={id}` (or `/users/{id}/listings`) | — | `Listing[]` |
| Create | `POST /listings` | §2a fields | created `Listing` (server fills §2b) |
| Update | `PUT /listings/{id}` | §2a fields | updated `Listing` |
| Delete | `DELETE /listings/{id}` | — | 204 |

The search query already has a `toJson`/`fromJson` contract in
`ListingQuery` (`lib/domain/models/listing_query.dart`) intended to match the
`GET /listings` query string exactly.

### Example create payload (client → API)

```json
{
  "title": "Cozy studio near the station",
  "description": "Bright studio with fast Wi-Fi, walking distance to transit.",
  "type": "apartment",
  "price": 12000,
  "currency": "₱",
  "location": {
    "city": "Manila",
    "address": "Sampaloc",
    "lat": 14.6042,
    "lng": 120.9822
  },
  "photos": [],
  "amenities": ["Wi-Fi", "Private bathroom", "Laundry"],
  "status": "active"
}
```

### Example listing response (API → client)

```json
{
  "id": "l_1024",
  "ownerId": "u_landlord_1",
  "ownerName": "Maria Santos",
  "title": "Cozy studio near the station",
  "description": "Bright studio with fast Wi-Fi, walking distance to transit.",
  "type": "apartment",
  "price": 12000,
  "currency": "₱",
  "location": { "city": "Manila", "address": "Sampaloc", "lat": 14.6042, "lng": 120.9822 },
  "photos": [],
  "amenities": ["Wi-Fi", "Private bathroom", "Laundry"],
  "status": "active",
  "propertyVerification": "none",
  "ratingAverage": 0,
  "ratingCount": 0,
  "createdAt": "2026-08-04T09:00:00Z"
}
```
