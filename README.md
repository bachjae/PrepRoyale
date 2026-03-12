# Prep Royale

AI-powered SAT/ACT test prep app with real-time head-to-head battles, study mode, leaderboards, and friends — available on **Android**, **iOS**, and **Web**.

---

## Platforms

| Platform | Status | Build |
|---|---|---|
| Android | Production-ready | `flutter build apk --release` |
| iOS | Configured — build via GitHub Actions or Codemagic | `flutter build ios --release` (macOS only) |
| Web | Production-ready | `flutter build web --release` |

All three platforms share the same Firebase backend — battles, friends, leaderboard, and study progress are fully cross-platform.

---

## Project Structure

```
Prep Royale/
│
├── 📱 android/                  # Android platform
│   ├── app/build.gradle         # Package: com.preproyale.app, SDK 36
│   └── app/src/main/            # Kotlin entry point, AndroidManifest
│
├── 🍎 ios/                      # iOS platform
│   ├── Runner/
│   │   ├── AppDelegate.swift    # Firebase init + plugin registration
│   │   ├── Info.plist           # Bundle ID, URL schemes, permissions
│   │   └── GoogleService-Info.plist  # (gitignored — stored as GH Secret)
│   ├── Runner.xcodeproj/        # Xcode project (bundle: com.preproyale.app)
│   └── Podfile                  # CocoaPods for Firebase native SDKs
│
├── 🌐 web/                      # Web platform (Flutter Web)
│   ├── index.html               # App shell + FCM service worker registration
│   ├── manifest.json            # PWA manifest
│   └── firebase-messaging-sw.js # Background push notifications
│
├── lib/                         # Flutter/Dart source
│   ├── config/
│   │   ├── firebase_config.dart # Firebase options for all 3 platforms
│   │   ├── router.dart          # GoRouter navigation (25+ routes)
│   │   └── theme.dart           # Material 3 theme (Sky blue palette)
│   ├── models/                  # Firestore-serializable data models
│   ├── providers/               # Riverpod state management
│   ├── screens/                 # Feature screens (auth, battle, study, profile…)
│   ├── services/                # Firebase, cloud functions, notifications
│   └── widgets/                 # Reusable UI components
│
├── functions/                   # Firebase Cloud Functions (TypeScript)
│   └── src/index.ts             # 37 HTTP endpoints (matchmaking, battles, friends…)
│
├── .github/workflows/
│   └── ios.yml                  # GitHub Actions: iOS build on macOS runner
│
├── firestore.rules              # Firestore security rules
├── database.rules.json          # Realtime Database security rules
└── firebase.json                # Firebase project config
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| **UI / Mobile** | Flutter 3, Dart ≥3.2 |
| **State** | Riverpod 2 (StreamProvider, StateNotifier) |
| **Navigation** | GoRouter 14 |
| **Auth** | Firebase Auth + Google Sign-In |
| **Persistent data** | Firestore |
| **Live battle state** | Firebase Realtime Database |
| **Backend logic** | Firebase Cloud Functions (TypeScript, Node 18) |
| **AI questions** | Vertex AI Gemini 2.0 Flash |
| **Push notifications** | FCM (Android + iOS + Web) |
| **Storage** | Firebase Storage (profile pictures) |

---

## Android

**Package:** `com.preproyale.app`
**Min SDK:** 21 · **Target SDK:** 36

### Build

```bash
# Install dependencies (Windows/OneDrive workaround — flutter clean causes file-lock errors)
cd android && ./gradlew.bat --stop && cd .. && rm -rf build/
flutter pub get

# Run on device/emulator
flutter run

# Release APK
flutter build apk --release
```

### Configuration

- `android/app/google-services.json` — Firebase config (gitignored; add manually)
- `android/key.properties` — Signing config (gitignored; required for release builds)

---

## iOS

**Bundle ID:** `com.preproyale.app`
**Minimum iOS:** 13.0

> **Windows users:** iOS builds require macOS + Xcode. Use the GitHub Actions workflow below.

### GitHub Actions Build (free)

Every push to `master` automatically builds an unsigned IPA on a macOS runner.

**One-time setup — add this GitHub Secret:**

| Secret name | Value |
|---|---|
| `GOOGLE_SERVICE_INFO_PLIST` | Base64-encoded `GoogleService-Info.plist` |

Generate the base64 value:
```bash
base64 -i ios/Runner/GoogleService-Info.plist | pbcopy   # macOS (copies to clipboard)
base64 ios/Runner/GoogleService-Info.plist               # Linux/WSL
```

Then go to: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

The workflow produces a downloadable `PrepRoyale-unsigned.ipa` artifact (kept 14 days).

### For App Store / TestFlight

Uncomment the `build-ios-signed` job in [.github/workflows/ios.yml](.github/workflows/ios.yml) and add the Apple Developer secrets described in the workflow comments. Requires a $99/yr Apple Developer account.

### Local build (macOS only)

```bash
cd ios && pod install
flutter build ios --release
```

---

## Web

Deployed as a Flutter Web PWA. Works in any modern browser.

### Run locally

```bash
flutter run -d chrome
```

### Production build

```bash
flutter build web --release
# Output: build/web/ — deploy to Firebase Hosting, Vercel, or any static host
```

### Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

> Add `"hosting"` config to `firebase.json` with `"public": "build/web"` first.

### Push Notifications (Web)

Background notifications use a service worker (`web/firebase-messaging-sw.js`). The browser will ask permission on first visit. Requires HTTPS in production (localhost is exempt).

---

## Backend — Firebase Cloud Functions

Located in `functions/src/index.ts` (~2800 lines, 37 endpoints).

All user-facing functions use `wrapAsCallable` (manual Bearer token auth). The client calls them via `lib/services/cloud_fn.dart`.

```bash
cd functions
npm install
npm run build
firebase deploy --only functions     # run from repo root
```

**Firebase project:** `sat-act-battle-royale`

---

## Environment Setup

### Prerequisites

- Flutter SDK (stable channel)
- Node.js 18+ (for Cloud Functions)
- Firebase CLI: `npm install -g firebase-tools`

### First-time setup

```bash
flutter pub get
firebase login
firebase use sat-act-battle-royale
```

### Run local Firebase emulators

```bash
firebase emulators:start
# Set useEmulators = true in lib/config/firebase_config.dart
```

---

## Pre-Launch Checklist

**Deploy required:**
- [ ] `firebase deploy --only functions,firestore:rules,database`
- [ ] Set `ADMIN_SECRET` env var in Firebase Functions config
- [ ] Set admin custom claim on your Firebase Auth account
- [ ] Call `purgeKnownBrokenQuestions` once (removes 18 flagged Math questions)
- [ ] Scan and delete Writing/English questions containing "underlined" references

**App Store / Play Store:**
- [ ] Privacy Policy and Terms of Service (host externally, link in app)
- [ ] iOS: Apple Developer account + distribution certificate for TestFlight

---

## License

Private — all rights reserved.
