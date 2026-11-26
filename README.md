# BoardEase

BoardEase is a Flutter boarding-house management app for a single property
owner and their tenants. The owner manages rooms, reservation requests,
payments, tenants, and maintenance; tenants browse available rooms, reserve a
room, submit proof of payment, and report repairs.

- **Platform:** Android first (minSdk 23), Material 3
- **Backend:** Firebase Authentication + Cloud Firestore
- **Images:** Cloudinary unsigned uploads
- **Addresses:** PSGC API (Philippine Standard Geographic Code)

---

## Features

### Owner

- Email/password sign-in with email verification and password reset
- Dashboard with occupancy, monthly collections, pending requests, and
  overdue-tenant shortcuts
- Room CRUD with photos, amenities, monthly rate, deposit, capacity, and
  PSGC-based address selection
- Reservation review: approve (room becomes occupied and is assigned to the
  tenant inside a Firestore transaction) or decline
- Payment verification and rejection with proof-of-payment preview
- Overdue tenant list for the current month
- Tenant directory and tenant detail (rental, payments, requests)
- Maintenance request triage with status updates
- Account screen with sign-out

### Tenant

- Registration (tenant role only), email verification, password reset
- Continue with Google (new Google accounts are created as tenants)
- Editable profile with gender, birthday, and a Cloudinary profile photo
- Browse available rooms with search, price/amenity filters, and photo gallery
- Reserve a room with a move-in date
- Active rental summary with rent due and payment history
- Submit proof of payment for a month (Cloudinary image URL)
- Report maintenance issues with an optional photo
- Account screen with sign-out

### Cross-cutting

- Role-based routing (`OwnerShell` / `TenantShell`) with route guards
- Live Firestore snapshots for rooms, reservations, payments, and maintenance
- 20-item "Load more" pagination on every long list
- Cached network images (`cached_network_image`) with placeholders and error
  fallbacks
- Lottie success animation for completed actions, with an icon fallback
- Consistent loading, empty, and error states with retry actions
- Friendly SnackBar errors; no passwords or tokens are logged
- 15-minute inactivity sign-out
- 30-second lockout after 5 failed sign-in attempts

---

## Tech stack

| Area | Package |
| --- | --- |
| UI | `material_ui` (Material 3) |
| State | `provider` |
| Auth / data | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Google sign-in | `google_sign_in` |
| Media | `image_picker`, `flutter_image_compress`, `cached_network_image` |
| HTTP | `http` |
| Secure storage | `flutter_secure_storage` |
| Animation | `lottie` |
| Formatting | `intl` |

---

## Project structure

```text
lib/
  app.dart                 App widget, providers, theme, routing
  main.dart                Firebase init and startup error fallback
  core/                    Constants, theme, validators, helpers, stats
  models/                  User, Room, Reservation, Payment, Maintenance
  providers/               Auth, session, rooms, reservations, payments,
                           maintenance, tenants, tenant-scoped providers
  services/                Firebase, Cloudinary, PSGC, session, lockout
  screens/
    auth/                  Splash, login, register, verification, reset
    owner/                 Dashboard, rooms, requests, tenants, payments
    tenant/                Browse, rental, payments, repairs
    shared/                Account, role home
  widgets/                 Shared cards, forms, states, dialogs
assets/animations/         Lottie success animation
firestore.rules            Deny-by-default security rules
test/                      Unit and widget tests
```

---

## Getting started

### Prerequisites

- Flutter 3.50+ / Dart 3.14+
- Android SDK with minSdk 23
- A Firebase project and a Cloudinary account

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Firebase

1. Create a Firebase project and add an Android app with the package id used
   by this project (`android/app/build.gradle.kts`).
2. Enable **Email/Password** and **Google** under Authentication → Sign-in
   method.
3. Create a Cloud Firestore database.
4. For Google Sign-In on Android, add your debug/release SHA-1 fingerprints in
   Firebase project settings and re-download `google-services.json`. The file
   must include a web OAuth client (`client_type: 3`). If it does not, add a
   web app in Firebase and download it again, or pass the web client ID with
   `--dart-define=GOOGLE_SERVER_CLIENT_ID=...apps.googleusercontent.com`.
5. Download `google-services.json` into `android/app/`. This file is
   git-ignored and must never be committed.
6. Generate `lib/firebase_options.dart` with the FlutterFire CLI. The file is
   committed for this project; **do not edit it by hand**.
7. Deploy the security rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

   Or paste `firestore.rules` into the Firebase console rules editor.

### 3. Provision the owner account

Tenant registration only creates tenant accounts. Create the owner manually:

1. Add the owner in Firebase Authentication (email/password).
2. Create a matching Firestore document:

   ```json
   {
     "name": "Owner Name",
     "email": "owner@example.com",
     "phone": "09171234567",
     "role": "owner",
     "createdAt": "<server timestamp>"
   }
   ```

   Path: `users/{uid}`.

3. Verify the owner's email if verification is enforced by your auth settings.

The client never writes `role = "owner"`; the rules only allow self-created
documents with `role == "tenant"`.

### 4. Cloudinary

Create an **unsigned** upload preset and set the cloud name and preset in
`lib/core/constants.dart`. Only the cloud name and unsigned preset are stored —
never an API secret or API key.

Uploads are limited to images, 5 MB, resized to a max dimension of 1080 px at
70% quality before upload.

### 5. PSGC addresses

Address pickers call `https://psgc.gitlab.io/api` for regions, provinces,
cities/municipalities, and barangays. Metro Manila is added as a synthetic
region because it has no province level in the PSGC API. An internet connection
is required for address selection.

---

## Data model

| Collection | Key fields |
| --- | --- |
| `users/{uid}` | `name`, `email`, `phone`, `role`, `createdAt`, optional `gender`, `birthday`, `photoUrl` |
| `rooms/{id}` | `ownerId`, `name`, `description`, `monthlyRate`, `deposit`, `capacity`, `amenities`, `photos`, `status`, `tenantId`, PSGC address fields, `createdAt` |
| `reservations/{id}` | `roomId`, `tenantId`, `moveInDate`, `status`, `createdAt` |
| `payments/{id}` | `roomId`, `tenantId`, `amount`, `month` (`yyyy-MM`), `proofUrl`, `status`, `createdAt` |
| `maintenance/{id}` | `roomId`, `tenantId`, `title`, `description`, `photoUrl`, `status`, `createdAt` |

Status values:

- Room: `available`, `reserved`, `occupied`
- Reservation: `pending`, `approved`, `declined`, `cancelled`
- Payment: `pending`, `verified`, `rejected`
- Maintenance: `pending`, `in_progress`, `resolved`

The app uses client-side filtering for search and status tabs over live
snapshots. Lists are paged in the UI in groups of 20 (`AppConstants.pageSize`)
so aggregates such as monthly collections and overdue counts stay accurate.
No composite Firestore indexes are currently required.

---

## Security

`firestore.rules` is deny-by-default:

- Signed-in users can read rooms; only the owning owner can create, update, or
  delete them.
- Tenants can create reservations only for available rooms and only for
  themselves.
- Owners can approve or decline reservations only for their own rooms; the
  approval runs in a transaction so two tenants cannot book the same room.
- Payments and maintenance requests can be created only by the tenant assigned
  to that room.
- Owners can change only the `status` field on payments and maintenance.
- Users can update only their own `name`, `email`, and `phone`; the role cannot
  change client-side.
- Account deletion and document deletion are denied.

Other safeguards:

- Passwords and tokens are never logged.
- Session lockout state is kept in `flutter_secure_storage`.
- Inactivity sign-out after 15 minutes.
- 30-second sign-in lockout after 5 failed attempts.
- Uploaded proof and maintenance photos must be HTTPS Cloudinary URLs.

---

## Running and testing

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Build a debug APK:

```bash
flutter build apk --debug
```

The test suite covers validators/helpers, owner statistics, tenant rental
resolution, maintenance status rules, and the splash widget. It currently has
22 passing tests.

---

## Troubleshooting

- **App shows the startup error screen:** Firebase failed to initialize. Check
  `google-services.json`, `lib/firebase_options.dart`, and the package id.
- **Address lists are empty:** the PSGC API needs an internet connection; retry
  from the error view.
- **Image upload fails:** confirm the Cloudinary preset is unsigned and allows
  the `Board_Ease` upload preset name used in `constants.dart`.
- **Owner sees no data:** confirm the owner's `users/{uid}` document exists and
  has `role == "owner"`.
- **Tenant cannot reserve:** the room must still be `available`, and the tenant
  must have a verified email.
- **Google sign-in fails with a configuration error:** confirm Google is
  enabled in Firebase Authentication, the app's SHA-1 is registered, and
  `google-services.json` contains a web OAuth client. See the Firebase setup
  step above.

---

## Notes

- `google-services.json`, `GoogleService-Info.plist`, `.env` files, and signing
  keys are git-ignored.
- No secrets are hardcoded in the repository.
- `lib/firebase_options.dart` is generated configuration and should not be
  edited manually.
