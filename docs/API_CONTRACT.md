# Aadi — Backend API & Data Model Contract

This document specifies the REST API and MySQL data model the Flutter app (`aadi`)
expects from its backend. It is written for a **Laravel 11 + MySQL 8** provider.

The app is currently **mock-first**: every repository has an in-memory / on-device
implementation behind an interface. Wiring the real backend means writing one
`Api*Repository` per interface and flipping a single flag (see
[§10 Connecting the app](#10-connecting-the-flutter-app)). This contract mirrors
those interfaces 1:1 so the swap is mechanical.

> Source of truth for shapes: `lib/domain/models/*`, `lib/domain/enums.dart`,
> `lib/domain/repositories/*`.

---

## 1. Conventions

| Topic | Rule |
| --- | --- |
| Base URL | `https://api.aadi.app` (prod), `https://api.staging.aadi.app`, `https://api.dev.aadi.app`. Set via `AppEnv.apiBaseUrl`. |
| Transport | HTTPS + JSON. `Content-Type: application/json`, `Accept: application/json`. |
| Auth | `Authorization: Bearer <accessToken>` on every authenticated request (Laravel Sanctum). |
| **JSON casing** | **camelCase** on the wire (e.g. `listingId`, `ownerName`, `requestedAt`). The existing Dart `toJson`/`fromJson` already use camelCase — keep it. See [§9](#9-laravel-implementation-notes) for how to make Laravel emit camelCase. |
| Dates | ISO‑8601 UTC strings, e.g. `2026-08-13T15:00:00.000Z`. Dart parses with `DateTime.parse`. |
| IDs | Strings. The app treats every id as `String` (`id`, `ownerId`, `listingId`, …). ULID/UUID recommended. |
| Money | `price` is a number (major units, e.g. `12000`). `currency` is a display symbol; app defaults to `₱`. Store ISO `PHP` and map to `₱` in the API resource, or store `₱` directly. |
| Enums | Send the **exact** string values in [§3](#3-enum-reference). The client parses several via `Enum.values.byName(...)`, so casing must match (`boardingHouse`, not `boarding_house`). |
| Empty vs null | Optional fields may be `null` or omitted. Lists default to `[]`. |
| Errors | See [§8](#8-errors). Always include a user-safe `message`. |

---

## 2. Authentication model

- **One account per user.** Everyone is a tenant by default. "Landlord" is a
  **capability** unlocked via `landlordStatus`, not a separate account/role.
- Login/register return an `AuthSession`: `{ accessToken, refreshToken, user }`.
- The client stores the token and sends it as `Bearer`. On `401` it should
  route to login.
- `refreshToken` — Sanctum personal-access tokens don't natively rotate. Either
  (a) return the same token string for both fields, or (b) use Laravel Passport
  for true refresh tokens. The client only requires both fields be present.

### AuthSession JSON

```json
{
  "accessToken": "1|abcdef...",
  "refreshToken": "1|abcdef...",
  "user": { "...": "AppUser (see §4.1)" }
}
```

---

## 3. Enum reference

Send these **exact** strings. `<Enum>.values.byName()` is used client-side, so
they are case-sensitive and must match identifier spelling.

| Enum | Allowed values |
| --- | --- |
| `landlordStatus` | `none`, `pending`, `approved`, `rejected` |
| `ListingType` (`type`) | `bedspace`, `boardingHouse`, `apartment`, `house`, `commercial` |
| `ListingStatus` (`status`) | `draft`, `active`, `reserved`, `rented`, `archived` |
| `VerificationStatus` (`propertyVerification`, badge `status`) | `none`, `pending`, `verified`, `rejected` |
| `ViewingStatus` (viewing `status`) | `pending`, `confirmed`, `declined`, `rescheduled` |
| `BadgeType` (badge `type`) | `emailVerified`, `phoneVerified`, `idVerified`, `landlordVerified`, `propertyVerified`, `reliableTenant`, `responsive` |

> Note `boardingHouse` and the `*Verified` badge types are camelCase — store the
> raw string in the DB enum column exactly as shown, or map in the API Resource.

---

## 4. Data models (JSON shapes)

### 4.1 AppUser  (`lib/domain/models/app_user.dart`)

```json
{
  "id": "u_landlord_1",
  "email": "maria@aadi.app",
  "name": "Maria Santos",
  "landlordStatus": "approved",
  "phone": "+63 917 000 1111",
  "avatarUrl": null,
  "badges": [ { "...": "TrustBadge (§4.2)" } ],
  "ratingAverage": 4.7,
  "ratingCount": 23,
  "trustScore": 88
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | PK |
| `email` | string | unique |
| `name` | string | display name |
| `landlordStatus` | enum | see §3; default `none` |
| `phone` | string? | nullable |
| `avatarUrl` | string? | nullable |
| `badges` | TrustBadge[] | may be `[]` |
| `ratingAverage` | number | 0..5, server-computed |
| `ratingCount` | int | 0 → app shows "New to Aadi" |
| `trustScore` | int | 0..100, server-computed |

- `password` is **never** returned.
- Public profile (`GET /users/{id}`) returns the same shape minus `email`/`phone`
  if you want to keep contact info private (the app tolerates `null`).

### 4.2 TrustBadge  (`lib/domain/models/trust_badge.dart`)

```json
{ "type": "landlordVerified", "status": "verified", "grantedAt": "2025-02-01T00:00:00.000Z" }
```

| Field | Type | Notes |
| --- | --- | --- |
| `type` | enum `BadgeType` | §3 |
| `status` | enum `VerificationStatus` | §3 |
| `grantedAt` | date? | nullable until granted |

### 4.3 GeoPoint  (`lib/domain/models/geo_point.dart`)

```json
{ "lat": 14.6042, "lng": 120.9822, "address": "Sampaloc", "city": "Manila" }
```

Embedded inside `Listing.location`. `address` and `city` are nullable.

### 4.4 Listing  (`lib/domain/models/listing.dart`)

```json
{
  "id": "l_1",
  "ownerId": "u_landlord_1",
  "ownerName": "Maria Santos",
  "title": "Cozy Bedspace near University Belt",
  "description": "Affordable bedspace for students...",
  "type": "bedspace",
  "price": 3500,
  "currency": "₱",
  "location": { "lat": 14.6042, "lng": 120.9822, "address": "Sampaloc", "city": "Manila" },
  "photos": ["https://.../1.jpg"],
  "amenities": ["Wi-Fi", "Shared kitchen", "Laundry", "CCTV"],
  "status": "active",
  "propertyVerification": "verified",
  "ratingAverage": 4.6,
  "ratingCount": 12,
  "createdAt": "2026-06-20T00:00:00.000Z"
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | PK |
| `ownerId` | string | FK → users |
| `ownerName` | string | denormalized snapshot for cards |
| `title` | string | |
| `description` | string | long text |
| `type` | enum `ListingType` | §3 |
| `price` | number | major units |
| `currency` | string | default `₱` |
| `location` | GeoPoint | embedded (`lat`,`lng`,`address`,`city`) |
| `photos` | string[] | URLs; first is the cover; may be `[]` |
| `amenities` | string[] | free-form; may be `[]` |
| `status` | enum `ListingStatus` | §3; default `active` |
| `propertyVerification` | enum `VerificationStatus` | §3; default `none` |
| `ratingAverage` | number | server-computed |
| `ratingCount` | int | server-computed |
| `createdAt` | date | |

### 4.5 ListingQuery  (search params — `lib/domain/models/listing_query.dart`)

Sent as the **query string** of `GET /listings`.

| Param | Type | Required | Notes |
| --- | --- | --- | --- |
| `lat` | number | yes | search center |
| `lng` | number | yes | search center |
| `radiusKm` | number | yes | e.g. `10` |
| `type` | enum? | no | omit for "all" |
| `minPrice` | number? | no | |
| `maxPrice` | number? | no | |
| `availableOnly` | bool | no | default `true` → only `status = active` |

Server must return listings within `radiusKm` of (`lat`,`lng`), **sorted by
distance ascending** (Haversine — see [§9](#9-laravel-implementation-notes)),
applying the price/type/availability filters.

### 4.6 ViewingRequest  (`lib/domain/models/viewing_request.dart`)

```json
{
  "id": "vr_1723545600000",
  "listingId": "l_1",
  "listingTitle": "Cozy Bedspace near University Belt",
  "tenantId": "u_9f3",
  "tenantName": "landlord",
  "ownerId": "u_landlord_1",
  "ownerName": "Maria Santos",
  "requestedAt": "2026-08-13T15:00:00.000Z",
  "proposedAt": null,
  "status": "pending",
  "note": "Can I view this Saturday afternoon?",
  "createdAt": "2026-08-06T09:12:00.000Z"
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | PK |
| `listingId` | string | FK → listings |
| `listingTitle` | string | snapshot at request time |
| `tenantId` / `tenantName` | string | requester (FK + snapshot) |
| `ownerId` / `ownerName` | string | listing owner (FK + snapshot) |
| `requestedAt` | date | tenant's proposed time |
| `proposedAt` | date? | landlord's counter-proposal (set when `status = rescheduled`) |
| `status` | enum `ViewingStatus` | §3 |
| `note` | string? | optional message |
| `createdAt` | date | |

Status transitions (enforce server-side, authorize by role):

| Action | Actor | From → To | Sets |
| --- | --- | --- | --- |
| create | tenant | — → `pending` | `requestedAt`, `note?` |
| confirm | owner | `pending`/`rescheduled` → `confirmed` | — |
| decline | owner | `pending`/`rescheduled`/`confirmed` → `declined` | — |
| propose new time | owner | `pending` → `rescheduled` | `proposedAt` |
| reschedule | tenant | `rescheduled`/`pending` → `pending` | new `requestedAt`, clears `proposedAt` |
| accept proposed | tenant | `rescheduled` → `confirmed` | `requestedAt = proposedAt` |
| cancel/remove | either | any → deleted | `DELETE` |

### 4.7 SavedSearch  (`lib/domain/models/saved_search.dart`)

```json
{
  "id": "ss_1723545600000",
  "label": "Manila apartments under 15k",
  "query": {
    "lat": 14.5995, "lng": 120.9842, "radiusKm": 10,
    "type": "apartment", "minPrice": null, "maxPrice": 15000, "availableOnly": true
  },
  "createdAt": "2026-08-06T09:12:00.000Z"
}
```

`query` is a nested ListingQuery object (§4.5).

### 4.8 ListingAnalytics  (`lib/features/landlord/listing_analytics.dart`)

```json
{ "views": 312, "interested": 28, "viewingRequests": 4, "inquiries": 36, "conversionRate": 0.0128 }
```

| Field | Type | Notes |
| --- | --- | --- |
| `views` | int | listing detail views |
| `interested` | int | favorites/saves count |
| `viewingRequests` | int | count of viewing requests for the listing |
| `inquiries` | int | messages/inquiries (once messaging exists) |
| `conversionRate` | number | `viewingRequests / views`, 0..1 (may be derived client-side; return it too for convenience) |

---

## 5. Endpoints — mapped from repository interfaces

Each row is an existing app repository method → the HTTP call the corresponding
`Api*Repository` will make.

### 5.1 Auth — `AuthRepository`

| Method | HTTP | Body / Params | Returns |
| --- | --- | --- | --- |
| `register(email,password,name)` | `POST /auth/register` | `{ email, password, name }` | `AuthSession` |
| `login(email,password)` | `POST /auth/login` | `{ email, password }` | `AuthSession` |
| `logout()` | `POST /auth/logout` | — | `204` |
| `applyForLandlord()` | `POST /me/landlord-application` | — | `AppUser` (status → `pending`) |
| `approveLandlord()` | `POST /me/landlord-application/approve` | — | `AppUser` (status → `approved`) |
| `refreshUser()` | `GET /me` | — | `AppUser` |

> `approveLandlord` is an **admin** action in production (approval happens in the
> admin dashboard; the client observes it via `GET /me`). It exists here only so
> the pending→approved flow is demoable — gate it behind an admin policy or a
> feature flag, or drop the endpoint and rely on `GET /me` polling.

### 5.2 Listings — `ListingRepository`

| Method | HTTP | Params / Body | Returns |
| --- | --- | --- | --- |
| `search(query)` | `GET /listings` | query string = ListingQuery (§4.5) | `Listing[]` (distance-sorted) |
| `getById(id)` | `GET /listings/{id}` | — | `Listing` |
| `listingsByOwner(ownerId)` | `GET /users/{ownerId}/listings` | — | `Listing[]` |
| `create(listing)` | `POST /listings` | Listing (writable fields) | `Listing` |
| `update(listing)` | `PUT /listings/{id}` | Listing (writable fields) | `Listing` |
| `delete(id)` | `DELETE /listings/{id}` | — | `204` |

**Writable fields on create/update** (from `Listing.copyWith`): `title`,
`description`, `type`, `price`, `location` (`lat`,`lng`,`address`,`city`),
`photos`, `amenities`, `status`. Server owns `id`, `ownerId`, `ownerName`,
`currency`, `propertyVerification`, `ratingAverage`, `ratingCount`, `createdAt`.

### 5.3 Users — `UserRepository`

| Method | HTTP | Returns |
| --- | --- | --- |
| `getById(id)` | `GET /users/{id}` | `AppUser` (public profile) or `404`/`null` |

### 5.4 Viewing requests — `ViewingRepository`

The app fetches **one list** and filters client-side into "my requests as tenant"
vs "incoming as owner". The endpoint returns all requests where the caller is the
tenant **or** the owner.

| Method | HTTP | Body | Returns |
| --- | --- | --- | --- |
| `list()` | `GET /me/viewings` | — | `ViewingRequest[]` (newest-first) |
| `create(request)` | `POST /me/viewings` | ViewingRequest | `ViewingRequest` (or `201`) |
| `update(request)` | `PUT /me/viewings/{id}` | ViewingRequest | `ViewingRequest` |
| `delete(id)` | `DELETE /me/viewings/{id}` | — | `204` |

> `update` carries the full object; the server should authorize the transition by
> role (owner vs tenant) per §4.6 rather than trusting the client's `status`.

### 5.5 Favorites — `FavoritesRepository`

| Method | HTTP | Returns |
| --- | --- | --- |
| `list()` | `GET /me/favorites` | `string[]` of listing ids |
| `add(listingId)` | `PUT /me/favorites/{listingId}` | `204` |
| `remove(listingId)` | `DELETE /me/favorites/{listingId}` | `204` |

### 5.6 Saved searches — `SavedSearchRepository`

| Method | HTTP | Body | Returns |
| --- | --- | --- | --- |
| `list()` | `GET /me/saved-searches` | — | `SavedSearch[]` (newest-first) |
| `save(search)` | `POST /me/saved-searches` | SavedSearch | `SavedSearch` |
| `delete(id)` | `DELETE /me/saved-searches/{id}` | — | `204` |

### 5.7 Listing analytics — `listingAnalyticsProvider`

| HTTP | Returns |
| --- | --- |
| `GET /listings/{id}/analytics` | `ListingAnalytics` (§4.8) — owner-only |

### 5.8 Location / geocoding — `LocationRepository`

GPS + place search run **client-side**: GPS via `geolocator`, forward/reverse
geocoding via key-free OpenStreetMap **Nominatim**. **No backend endpoint is
required.** Optionally add `GET /geocode?q=` as a server-side proxy if you want to
control Nominatim rate limits / add caching; otherwise leave as-is.

---

## 6. MySQL schema (Laravel migrations)

Enum columns store the exact strings from §3. `lat`/`lng` use `decimal(10,7)`.
JSON columns (`photos`, `amenities`, `query`) map directly to the app's
`List<String>` / nested object; normalize later if you need to query them.

```php
// users
Schema::create('users', function (Blueprint $t) {
    $t->ulid('id')->primary();
    $t->string('email')->unique();
    $t->string('name');
    $t->string('password');
    $t->string('phone')->nullable();
    $t->string('avatar_url')->nullable();
    $t->enum('landlord_status', ['none','pending','approved','rejected'])->default('none');
    $t->decimal('rating_average', 3, 2)->default(0);
    $t->unsignedInteger('rating_count')->default(0);
    $t->unsignedTinyInteger('trust_score')->default(0);
    $t->rememberToken();
    $t->timestamps();
});

// trust_badges  (a user's verification badges)
Schema::create('trust_badges', function (Blueprint $t) {
    $t->id();
    $t->foreignUlid('user_id')->constrained()->cascadeOnDelete();
    $t->enum('type', ['emailVerified','phoneVerified','idVerified','landlordVerified','propertyVerified','reliableTenant','responsive']);
    $t->enum('status', ['none','pending','verified','rejected'])->default('pending');
    $t->timestamp('granted_at')->nullable();
    $t->timestamps();
    $t->unique(['user_id','type']);
});

// listings
Schema::create('listings', function (Blueprint $t) {
    $t->ulid('id')->primary();
    $t->foreignUlid('owner_id')->constrained('users')->cascadeOnDelete();
    $t->string('owner_name');                 // snapshot for cards
    $t->string('title');
    $t->text('description');
    $t->enum('type', ['bedspace','boardingHouse','apartment','house','commercial']);
    $t->decimal('price', 10, 2);
    $t->string('currency', 8)->default('₱');   // or store 'PHP' and map in the Resource
    $t->decimal('lat', 10, 7);
    $t->decimal('lng', 10, 7);
    $t->string('address')->nullable();
    $t->string('city')->nullable();
    $t->json('photos')->nullable();            // ["https://...", ...]
    $t->json('amenities')->nullable();         // ["Wi-Fi", ...]
    $t->enum('status', ['draft','active','reserved','rented','archived'])->default('active');
    $t->enum('property_verification', ['none','pending','verified','rejected'])->default('none');
    $t->decimal('rating_average', 3, 2)->default(0);
    $t->unsignedInteger('rating_count')->default(0);
    $t->timestamps();
    $t->index(['lat','lng']);
    $t->index(['status','type']);
});

// viewing_requests
Schema::create('viewing_requests', function (Blueprint $t) {
    $t->ulid('id')->primary();
    $t->foreignUlid('listing_id')->constrained('listings')->cascadeOnDelete();
    $t->string('listing_title');              // snapshot
    $t->foreignUlid('tenant_id')->constrained('users')->cascadeOnDelete();
    $t->string('tenant_name');                // snapshot
    $t->foreignUlid('owner_id')->constrained('users')->cascadeOnDelete();
    $t->string('owner_name');                 // snapshot
    $t->dateTime('requested_at');
    $t->dateTime('proposed_at')->nullable();
    $t->enum('status', ['pending','confirmed','declined','rescheduled'])->default('pending');
    $t->text('note')->nullable();
    $t->timestamps();
    $t->index(['tenant_id','status']);
    $t->index(['owner_id','status']);
});

// favorites  (tenant ⇄ listing)
Schema::create('favorites', function (Blueprint $t) {
    $t->id();
    $t->foreignUlid('user_id')->constrained()->cascadeOnDelete();
    $t->foreignUlid('listing_id')->constrained('listings')->cascadeOnDelete();
    $t->timestamps();
    $t->unique(['user_id','listing_id']);
});

// saved_searches
Schema::create('saved_searches', function (Blueprint $t) {
    $t->ulid('id')->primary();
    $t->foreignUlid('user_id')->constrained()->cascadeOnDelete();
    $t->string('label');
    $t->json('query');                        // ListingQuery JSON (§4.5)
    $t->timestamps();
});
```

> **Normalized alternative:** if you prefer relational photos/amenities over JSON,
> add `listing_photos (listing_id, url, position)` and either
> `listing_amenities (listing_id, amenity)` or an `amenities` + `amenity_listing`
> pivot. The API Resource then re-assembles them into the `photos` / `amenities`
> arrays so the JSON contract is unchanged.

Analytics can be **derived** (counts from `favorites`, `viewing_requests`, plus a
`listing_views` table you increment on `GET /listings/{id}`) rather than stored.

---

## 7. Route list (`routes/api.php`)

```php
Route::post('auth/register', [AuthController::class, 'register']);
Route::post('auth/login',    [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::get('me',           [MeController::class, 'show']);
    Route::post('me/landlord-application',         [LandlordController::class, 'apply']);
    Route::post('me/landlord-application/approve', [LandlordController::class, 'approve']); // admin/demo

    Route::get   ('listings',            [ListingController::class, 'index']);   // search
    Route::get   ('listings/{listing}',  [ListingController::class, 'show']);
    Route::post  ('listings',            [ListingController::class, 'store']);
    Route::put   ('listings/{listing}',  [ListingController::class, 'update']);
    Route::delete('listings/{listing}',  [ListingController::class, 'destroy']);
    Route::get   ('listings/{listing}/analytics', [ListingController::class, 'analytics']);

    Route::get('users/{user}',           [UserController::class, 'show']);
    Route::get('users/{user}/listings',  [UserController::class, 'listings']);

    Route::get   ('me/viewings',          [ViewingController::class, 'index']);
    Route::post  ('me/viewings',          [ViewingController::class, 'store']);
    Route::put   ('me/viewings/{viewing}',[ViewingController::class, 'update']);
    Route::delete('me/viewings/{viewing}',[ViewingController::class, 'destroy']);

    Route::get   ('me/favorites',              [FavoriteController::class, 'index']);
    Route::put   ('me/favorites/{listing}',    [FavoriteController::class, 'store']);
    Route::delete('me/favorites/{listing}',    [FavoriteController::class, 'destroy']);

    Route::get   ('me/saved-searches',            [SavedSearchController::class, 'index']);
    Route::post  ('me/saved-searches',            [SavedSearchController::class, 'store']);
    Route::delete('me/saved-searches/{search}',   [SavedSearchController::class, 'destroy']);
});
```

---

## 8. Errors

Return a JSON body with a **user-safe `message`** on every error (the client maps
it to `AppException.message` and shows it directly).

```json
{ "message": "That email is already registered." }
```

Validation errors may additionally include Laravel's `errors` map:

```json
{ "message": "The given data was invalid.", "errors": { "email": ["The email field is required."] } }
```

| Status | Meaning | Client behavior |
| --- | --- | --- |
| `200` / `201` | success | parse body |
| `204` | success, no body | treat as void |
| `401` | unauthenticated | clear session → login |
| `403` | not allowed (e.g. non-owner editing a listing) | show `message` |
| `404` | not found | `getById` throws `AppException('… not found.')` |
| `422` | validation failed | show first `message` |
| `5xx` | server error | show generic retry |

---

## 9. Laravel implementation notes

**camelCase JSON.** DB columns stay `snake_case`; emit camelCase from API
Resources. Simplest reliable approach — build the array explicitly:

```php
class ListingResource extends JsonResource {
    public function toArray($request): array {
        return [
            'id' => $this->id,
            'ownerId' => $this->owner_id,
            'ownerName' => $this->owner_name,
            'title' => $this->title,
            'description' => $this->description,
            'type' => $this->type,                    // already 'boardingHouse' etc.
            'price' => (float) $this->price,
            'currency' => $this->currency,
            'location' => [
                'lat' => (float) $this->lat,
                'lng' => (float) $this->lng,
                'address' => $this->address,
                'city' => $this->city,
            ],
            'photos' => $this->photos ?? [],
            'amenities' => $this->amenities ?? [],
            'status' => $this->status,
            'propertyVerification' => $this->property_verification,
            'ratingAverage' => (float) $this->rating_average,
            'ratingCount' => $this->rating_count,
            'createdAt' => $this->created_at->toIso8601String(),
        ];
    }
}
```

**Enum casts.** Use PHP backed enums whose values match §3 exactly and cast on the
model (`protected $casts = ['type' => ListingType::class, ...]`).

**Distance search + sort** (`GET /listings`). Haversine in SQL, sorted ascending,
matching the mock's behavior:

```php
$q = ListingQuery::validated($request); // lat,lng,radiusKm,type?,minPrice?,maxPrice?,availableOnly

$listings = Listing::query()
    ->when($q['availableOnly'] ?? true, fn ($b) => $b->where('status', 'active'))
    ->when($q['type'] ?? null, fn ($b, $t) => $b->where('type', $t))
    ->when($q['minPrice'] ?? null, fn ($b, $p) => $b->where('price', '>=', $p))
    ->when($q['maxPrice'] ?? null, fn ($b, $p) => $b->where('price', '<=', $p))
    ->selectRaw(
        '*, (6371 * acos(cos(radians(?)) * cos(radians(lat)) * cos(radians(lng) - radians(?)) + sin(radians(?)) * sin(radians(lat)))) AS distance_km',
        [$q['lat'], $q['lng'], $q['lat']]
    )
    ->havingRaw('distance_km <= ?', [$q['radiusKm']])
    ->orderBy('distance_km')
    ->get();

return ListingResource::collection($listings);
```

**Pagination.** The client repository expects a JSON **array of listings**. If you
use `ResourceCollection` pagination (`{ "data": [...], "meta": {...} }`), the
`ApiListingRepository` reads `response['data']`. Pick one and keep it consistent;
document it here if you paginate.

**Auth.** Laravel Sanctum. `register`/`login` create a token
(`$user->createToken('mobile')->plainTextToken`) and return it as both
`accessToken` and `refreshToken` inside `AuthSession`. `logout` deletes the
current token.

**Authorization.**
- Listing `update`/`destroy`: only `owner_id === auth()->id()`.
- Viewing transitions: authorize by whether the caller is the tenant or owner
  (see §4.6). Don't trust the client-sent `status`.
- Analytics + `users/{id}/listings` for management: owner-only where applicable.

**Snapshots.** `owner_name`, `listing_title`, `tenant_name`, `owner_name` on
viewing requests are denormalized snapshots — set them server-side from the
related records at write time; don't accept them from the client blindly.

---

## 10. Connecting the Flutter app

The app already isolates the swap to `lib/shared/providers.dart`. Backend wiring:

1. **Config** — set the base URL and disable mocks in
   `lib/core/env/app_env.dart` (`AppEnv.current`, `useMockData: false`,
   `apiBaseUrl: 'https://api.aadi.app'`).
2. **HTTP client** — the project already depends on `dio`. Add a provider that
   builds a `Dio` with `baseUrl`, JSON headers, and a `Bearer` token interceptor
   (read the stored `accessToken`; on `401`, clear session).
3. **Implement repositories** — add `Api*Repository` classes implementing the
   interfaces in `lib/domain/repositories/`, calling the endpoints in §5 and
   parsing the JSON in §4. Models without a `fromJson` yet (`AppUser`, `Listing`,
   `GeoPoint`, `TrustBadge`) need a parser — mirror the camelCase shapes above and
   use `Enum.values.byName(...)` for enum fields (`boardingHouse` etc.).
4. **Flip the providers** — in `lib/shared/providers.dart`, return the new
   `Api*Repository` in each `*RepositoryProvider` when `env.useMockData` is false
   (the `TODO(remote):` lines mark exactly where).
5. **Token storage** — persist `accessToken`/`refreshToken` (e.g.
   `flutter_secure_storage` or the existing `shared_preferences`) and inject into
   the Dio interceptor.
6. **Errors** — map non-2xx responses to `AppException(message)` using the body's
   `message` field so existing loading/error UI states keep working unchanged.

No UI or controller changes are required — every screen already consumes these
repositories through Riverpod providers.

---

## 11. Quick coverage checklist

- [ ] `POST /auth/register`, `POST /auth/login`, `POST /auth/logout`
- [ ] `GET /me`, `POST /me/landlord-application`, `POST /me/landlord-application/approve` (admin/demo)
- [ ] `GET /listings` (distance-sorted search), `GET /listings/{id}`
- [ ] `POST /listings`, `PUT /listings/{id}`, `DELETE /listings/{id}`
- [ ] `GET /listings/{id}/analytics`
- [ ] `GET /users/{id}`, `GET /users/{id}/listings`
- [ ] `GET/POST/PUT/DELETE /me/viewings`
- [ ] `GET /me/favorites`, `PUT/DELETE /me/favorites/{listingId}`
- [ ] `GET/POST/DELETE /me/saved-searches`
- [ ] camelCase JSON, exact enum strings (§3), ISO‑8601 dates, `Bearer` auth, `message` on errors
