# Aadi — Mobile App Project Plan & Recommendations

> **Tagline:** *Your next space is here.*
> A property rental marketplace connecting landlords (space owners) with tenants (renters).
> Works like Facebook Marketplace with location-based discovery.

_Last updated: 2026-07-30_

---

## 1. Product Overview

Aadi is a two-sided rental marketplace:

- **Landlords** list available spaces (bedspace, boarding house, apartment, house, commercial).
- **Tenants** browse, filter, and discover rentals by location, price, type, and needs.

All app data flows through a single **backend API**, which also powers a separate **admin dashboard**. The mobile app never talks to the database directly.

---

## 2. Roles & Access Control

| Role | Capabilities |
|------|--------------|
| **Tenant** | Set/auto-detect location, browse & filter listings, view details, save favorites & searches, contact landlord, message, leave reviews, report/block |
| **Landlord** | Create/edit/delete listings, upload photos, manage availability/status, view inquiries, message, leave reviews, submit verification |

Role is chosen at signup, stored on the user record, and drives a role-based navigation shell.

---

## 3. Confirmed Tech Stack

| Concern | Choice | Notes |
|---------|--------|-------|
| State management | **Riverpod** (`flutter_riverpod` + `riverpod_annotation`) | Scalable, testable, role-based flows |
| Routing | **go_router** | Declarative + role-based redirect guards |
| Networking | **dio** behind repository interfaces | Mock implementation first |
| Models | **freezed** + **json_serializable** | Immutable models, safe JSON |
| Maps | **flutter_map** (OpenStreetMap) | No API key required |
| Location | **geolocator** + **geocoding** | GPS + address ⇄ coords |
| Local DB / cache | **drift** (SQLite) + `sqlite3_flutter_libs` | Offline-first, reactive queries |
| Connectivity | **connectivity_plus** | Online/offline detection + sync trigger |
| Secure storage | **flutter_secure_storage** + **shared_preferences** | Tokens + prefs |
| Images | **image_picker** + **cached_network_image** + **flutter_image_compress** | Upload + efficient display + bandwidth savings |

---

## 4. Architecture

### High-level

```
Aadi Flutter App  --(REST/JSON)-->  Backend API  -->  Database
                                          |
                                          +-->  Admin Dashboard
App --(Location)--> Device GPS / Geocoding
App --(Images)--> Media Storage
```

### Offline-first data flow (single source of truth)

The UI reads from the **local SQLite database**, not directly from the network. The network refreshes the cache in the background.

```
UI (Riverpod) --watch stream--> SQLite (local cache)
Repository --> SQLite
Repository --fetch when stale--> Backend API --upsert--> SQLite
SQLite --reactive stream--> UI
```

Repositories follow **cache-then-network**:
1. Emit cached data immediately (instant UI, works offline).
2. If cache is stale (TTL) or forced, fetch from remote.
3. Upsert results into SQLite → stream auto-updates the UI.

### Repository seams

All data access sits behind **repository interfaces** in `domain/`, with implementations in `data/` that combine a **local (drift)** source and a **remote** source. The remote source is **mock now**, **real API later** — swapping only touches `data/remote/`.

```dart
abstract class AuthRepository { ... }
abstract class ListingRepository { ... }
abstract class FavoritesRepository { ... }
abstract class MessagingRepository { ... }
abstract class LocationRepository { ... }
abstract class ReviewRepository { ... }
abstract class VerificationRepository { ... }
```

---

## 5. Domain Models

```dart
enum UserRole { tenant, landlord }
enum ListingType { bedspace, boardingHouse, apartment, house, commercial }
enum ListingStatus { draft, active, reserved, rented, archived }
enum VerificationStatus { none, pending, verified, rejected }
enum ReviewDirection { tenantToLandlord, landlordToTenant }
enum ReviewStatus { active, flagged, removed }

class User {
  final String id;
  final String email;
  final UserRole role;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final List<Badge> badges;
  final double ratingAverage;   // 0..5
  final int ratingCount;
  final int trustScore;         // 0..100, server-computed ("New to Aadi" until enough signals)
}

class Badge {
  final BadgeType type;         // emailVerified, phoneVerified, idVerified,
                                // landlordVerified, reliableTenant, responsive
  final VerificationStatus status;
  final DateTime? grantedAt;
}

class Listing {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final ListingType type;
  final double price;
  final String currency;
  final GeoPoint location;      // lat, lng, address, city
  final List<String> photos;
  final List<String> amenities;
  final ListingStatus status;
  final VerificationStatus propertyVerification;
  final double ratingAverage;
  final int ratingCount;
  final DateTime createdAt;
}

class ListingQuery {
  final double lat, lng, radiusKm;
  final ListingType? type;
  final double? minPrice, maxPrice;
  final bool availableOnly;
}

class Review {
  final String id;
  final String authorId;        // reviewer
  final String subjectId;       // user being reviewed
  final String? listingId;      // if reviewing a property
  final ReviewDirection direction;
  final int stars;              // 1..5
  final Map<String, int>? subRatings; // accuracy/communication/value/location
  final String body;
  final DateTime createdAt;
  final ReviewStatus status;
}

class VerificationRequest {
  final String id;
  final BadgeType type;
  final List<String> documentUrls;
  final VerificationStatus status;
}

class Conversation { final String id; final String listingId; final List<String> participantIds; final Message? lastMessage; }
class Message { final String id; final String senderId; final String body; final DateTime sentAt; }
class AuthSession { final String accessToken; final String refreshToken; final User user; }
```

---

## 6. API Contract (mock + real parity)

```
# Auth
POST   /auth/register        { email, password, role } -> AuthSession
POST   /auth/login           { email, password }       -> AuthSession
POST   /auth/refresh         { refreshToken }           -> tokens
GET    /me                                              -> User

# Listings
GET    /listings?lat=&lng=&radiusKm=&type=&minPrice=&maxPrice=&availableOnly=
POST   /listings             (landlord)                 -> Listing
GET    /listings/:id                                    -> Listing
PATCH  /listings/:id         (landlord)                 -> Listing
DELETE /listings/:id         (landlord)

# Favorites & saved searches
GET    /me/favorites   POST/DELETE /me/favorites/:id
GET    /me/saved-searches   POST /me/saved-searches   DELETE /me/saved-searches/:id

# Messaging
GET    /conversations
GET    /conversations/:id/messages
POST   /conversations/:id/messages

# Verification (reviewed in admin dashboard)
POST   /me/verifications     { type, documentUrls[] }   -> VerificationRequest
GET    /me/verifications                                -> VerificationRequest[]
POST   /me/phone/verify      { code }                   (OTP)

# Reviews
GET    /users/:id/reviews
GET    /listings/:id/reviews
POST   /reviews              { subjectId, listingId?, direction, stars, subRatings?, body }
PATCH  /reviews/:id          (within edit window)
POST   /reviews/:id/report   { reason }

# Moderation
POST   /reports              { targetType, targetId, reason }   # listings & users
POST   /blocks/:userId       DELETE /blocks/:userId
```

Aggregates (`ratingAverage`, `ratingCount`, `trustScore`, `badges`) are embedded in `User`/`Listing` responses.

---

## 7. Trust & Reputation System

Two-sided trust so tenants trust landlords **and** landlords trust tenants.

### Verification badges (admin-granted facts)

| Badge | Applies to | Meaning |
|-------|-----------|---------|
| Email verified | Both | Confirmed email |
| Phone verified | Both | Confirmed phone (OTP) |
| ID verified | Both | Government ID checked (admin-approved) |
| Landlord verified | Landlord | Ownership/authority docs approved |
| Property verified | Landlord (per-listing) | Listing address/docs validated |
| Reliable tenant | Tenant | Good review history, no disputes |
| Responsive | Both | Fast response rate |

- Badge status: `none | pending | verified | rejected`.
- Suggested **tiers**: Basic → Verified → Premium (clearer than scattered badges).
- Verification submissions route through the **API → admin dashboard** for manual approval.

### Ratings & reviews

- Bidirectional, 1–5 stars + text, after a completed interaction.
- Optional sub-ratings for landlords: accuracy, communication, value, location.
- One review per interaction, editable within a window, reportable (admin moderation).

### Trust score

Server-computed 0–100 blending verification level, average rating, review volume, response rate, account age, dispute count. Shows **"New to Aadi"** until enough signals exist. App only displays it.

---

## 8. Caching & Offline Behavior

### Cache policy (tunable TTLs)

| Data | Policy | TTL |
|------|--------|-----|
| Listings (feed) | Cache + background refresh, keyed by query area | ~10 min |
| Listing detail | Cache on view | ~30 min |
| User profiles / badges / ratings | Cache | ~1 hr |
| Reviews | Cache per subject/listing | ~30 min |
| Favorites | Cache + optimistic writes | synced |
| Messages / conversations | Cache; append new | live-ish |
| Current user (`/me`) | Cache | session |
| Map tiles | flutter_map on-disk tile cache | provider-handled |

### Freshness & efficiency
- Each cached row stores `fetchedAt`; TTL decides refresh.
- **Pull-to-refresh** and explicit actions bypass TTL.
- **Write-through + optimistic updates** for listings, favorites, reviews, messages.
- **Request de-duplication + debounced** feed refreshes to protect the API.

### Offline
- Browse previously loaded data with no connection.
- **Outbox queue** (SQLite) holds pending writes made offline; a sync worker flushes on reconnect (`connectivity_plus`).
- UI shows an "offline / cached results" indicator when serving stale data.

---

## 9. Brand Theming (from brief)

| Token | Value |
|-------|-------|
| Primary (deep blue) | `#1E3A5F` |
| Secondary (teal) | `#1FA6A0` |
| Accent (warm orange) | `#F59E42` |
| Surface (off-white) | `#F7F8FA` |
| Text (dark gray) | `#252A31` |

Material 3, rounded corners, clean sans-serif. Personality: **trustworthy, welcoming, modern, dependable**. Tagline surfaced on onboarding.

---

## 10. Folder Structure

```
lib/
  core/            # theme, router, constants, Result/Failure types, DI overrides, env config
  domain/          # models (freezed) + repository interfaces
  data/
    local/
      database/    # drift database + tables (listings, users, reviews, favorites,
                   #   conversations, messages, outbox, cache_meta)
      daos/        # ListingDao, UserDao, ReviewDao, OutboxDao...
      cache_policy.dart
    remote/        # dio api client + api data sources (stubbed for now)
    mock/          # mock remote data source (current phase)
    repositories/  # combine local (drift) + remote, expose streams
    dtos/          # json_serializable DTOs + mappers (DTO <-> row <-> model)
  features/
    onboarding/
    auth/
    location/
    tenant/        # explore (map+list), filters, listing_detail, favorites, saved_searches
    landlord/      # my_listings, listing_editor, inquiries
    messaging/
    trust/
      verification/
      reviews/
      widgets/     # badge row, stars, trust chip, review tile, review composer
    profile/
  shared/          # reusable widgets, extensions
  main.dart
assets/mock/       # listings.json, users.json, conversations.json, reviews.json
docs/              # this plan
```

---

## 11. Recommendations Summary

### MVP (include now)
- Saved searches + push notifications (stubbed until backend).
- Report/block on listings **and** users (feeds admin moderation).
- Listing status lifecycle (`draft → active → reserved → rented → archived`).
- Client-side image compression before upload.

### Early / phase 2
- Analytics/events (mock sink first).
- Feature flags / remote config (toggle features, tune cache TTLs).
- Deep links / share listing.
- Localization scaffolding (English now; Tagalog/English later).

### Technical hardening (during scaffold)
- Encrypted cache for PII (tokens already in secure storage).
- Centralized `Result<T>` / `Failure` error model.
- Environment flavors: dev / staging / prod.
- Repository unit tests + a few widget tests early.

### Trust refinements
- "New to Aadi" state instead of a 0/100 score for newcomers.
- Verification tiers: Basic → Verified → Premium.

### Consciously deferred (avoid over-building)
- In-app payments / deposits (compliance surface).
- Real-time chat infra / websockets (mock/polling first).
- Map clustering/heatmaps (add with density).
- AI recommendations (revisit with real usage data).

---

## 12. Milestones (mock-driven, each shippable)

1. **Scaffold** — deps, brand theme, routing, role shells, drift database, mock repository seams, env config.
2. **Auth + role selection** (mock `AuthRepository`).
3. **Caching foundation** — repositories become cache-then-network; feed streams from SQLite.
4. **Location** — GPS permission flow + manual city search.
5. **Tenant Explore** — flutter_map + list feed from cache, distance sorting.
6. **Filters + saved searches** — type/price/radius/availability.
7. **Listing detail** — gallery, map pin, contact CTA, share.
8. **Landlord listings** — list + create/edit wizard (status lifecycle, image compression).
9. **Favorites**.
10. **Trust & verification** — badges, rating display, trust chip, report/block.
11. **Reviews** — bidirectional list + compose + report.
12. **Messaging** (mock/polling).
13. **Real API swap** — implement `data/remote/` against backend + admin dashboard; flip DI override.

Push notifications and analytics wired as stubs throughout, activated when the backend lands.

### What stays trivial to swap later
Only `data/remote/*` and one DI override change when the real backend + admin dashboard are ready. UI, providers, domain models, and the SQLite cache layer stay untouched.
