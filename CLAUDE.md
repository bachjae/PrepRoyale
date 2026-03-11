# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Flutter (Mobile App)
```bash
flutter pub get                        # Install dependencies
flutter run                            # Run on connected device/emulator
flutter build apk --release            # Build Android APK
flutter test                           # Run all tests
flutter test test/widget_test.dart     # Run single test file
dart analyze                           # Run static analysis
dart format .                          # Format all Dart code
dart run build_runner build            # Regenerate Riverpod/JSON code (after model changes)
```

### Android Build Fix (Windows/OneDrive — REQUIRED when build fails)
`flutter clean` will fail with file-lock errors. Always use this sequence instead:
```bash
cd android && ./gradlew.bat --stop && cd .. && rm -rf build/
flutter run
```

### Cloud Functions
```bash
cd functions
npm install
npm run build                          # Compile TypeScript
firebase deploy --only functions       # Deploy functions (run from repo root)
```
If deploy fails with `Cannot find module .../gaxios/...`: `rm -rf functions/node_modules && npm install`.

**Requirements:** Node.js 18

### Firebase
```bash
firebase deploy --only firestore:rules,database   # Deploy security rules
firebase deploy --only firestore:indexes          # Deploy indexes
firebase emulators:start                          # Run local emulators
```

---

## Architecture

### Stack
- **Flutter** (Dart SDK >=3.2.0) — Riverpod state management, go_router navigation
- **Firebase**: Auth, Firestore (persistent), Realtime Database (live battles/matchmaking), Cloud Functions (TypeScript)
- **AI**: Vertex AI Gemini 2.0 Flash for question generation — server-side only, in Cloud Functions
- **Monetization**: `google_mobile_ads` package (AdMob)

### Project Layout
- `lib/` — Flutter source
  - `config/` — Firebase options, GoRouter, AppTheme
  - `models/` — Firestore-serializable data models
  - `providers/` — Riverpod providers and `StateNotifier`/`Notifier` controllers
  - `services/` — Firebase wrappers (`firebase_service.dart`, `cloud_fn.dart`, `ad_service.dart`)
  - `screens/` — Feature folders: `auth/`, `home/`, `study/`, `battle/`, `profile/`, `leaderboard/`, `onboarding/`, `settings/`
  - `widgets/common/` — Reusable widgets; `formatted_text.dart` renders superscripts and pipe-table ASCII art as Flutter `Table` widgets
- `functions/src/` — Cloud Functions
  - `index.ts` — All function exports (~2400 lines)
  - `batch/dailyGenerator.ts` — Scheduled question generation
  - `config/questionConfig.ts` — Canonical SAT/ACT skill and section definitions
  - `utils/geminiHelper.ts` — Vertex AI prompt building, response parsing, validation
  - `utils/validation.ts` — SHA-256 dedup, Firestore batch writes
  - `utils/notificationHelper.ts` — FCM send helpers
- `firestore.rules`, `database.rules.json` — Security rules
- `functions/flagged_questions.json` — 18 known broken Math questions (wrong answer keys)

### App Package & Firebase Project
- App package: `com.preproyale.app`
- Firebase project: `sat-act-battle-royale`
- Kotlin widget file requires `import com.preproyale.app.R` (namespace ≠ package name)

---

## Key Architectural Patterns

### Cloud Function Endpoints
All user-facing functions use `wrapAsCallable` (defined at `index.ts:46`) which is `onRequest` + manual Bearer token verification. This bypasses Firebase App Check but enforces auth in code. The client calls them via `cloud_fn.dart`'s `callFn()`.

**Do not** use `functions.https.onCall` for new user-facing functions — use `wrapAsCallable` to match the client pattern.

### State Management
- `StreamProvider` for real-time Firebase listeners
- `StateNotifierProvider`/`NotifierProvider` for controllers with write operations
- Controllers in `providers/` encapsulate all writes; screens only call controller methods

### Data Split: Firestore vs Realtime Database
- **Firestore**: users, questions, achievements, leaderboard, battleResults, friendships (persistent)
- **RTDB**: `/battles/{id}` (live state), `/matchmaking/{userId}` (queue), `/userBattles/{userId}`, `/pendingBattleInvites/{userId}` (in-flight signals)

### Answer Validation
`submitBattleAnswer` (Cloud Function) compares by **choice text** (`answerText` field from client), not index. The client shuffles answer order before display, so index comparison is unreliable. Legacy fallback index comparison exists for old clients.

### XP / Level
- Formula: level N requires `100 * N * N` total XP
- Study-mode XP: written client-side via `firebase_service.dart:addXp()` using a Firestore transaction
- Battle XP: written server-side via `updateBattleStats()` in `index.ts`

### Question Generation
- Skills defined in `questionConfig.ts` with target counts per skill
- Passage sections (`Reading`, `Writing`, `English`, `Science`) require `passage` field ≥600 chars; validated in `geminiHelper.ts:validateQuestion()`
- Difficulty distribution: `{easy: 0.0, medium: 0.3, hard: 0.7}`
- Manual trigger: Firebase Console → Functions → `manualDailyGeneration` → Test (local scripts fail 403)

---

## Known Vulnerabilities & Bugs (Audit 2026-03)

Items marked ✅ are **code-fixed** but require `firebase deploy` to take effect in production.

### Critical — Security

**1. ✅ Unauthenticated admin HTTP endpoints — FIXED**
`seedWidgetTips`, `seedAchievements`, `migrateFriendCodes`, `seedTestQuestions` now require an `X-Admin-Secret` header matching the `ADMIN_SECRET` environment variable. Set via:
```bash
# In Firebase project: Functions → Configuration → Environment variables
# Variable name: ADMIN_SECRET  Value: <random 64-char string>
```

**2. ✅ RTDB battle documents writable by participants — FIXED**
`database.rules.json` now has `".write": false` on `/battles/{battleId}`. All battle state mutations route through Cloud Functions (Admin SDK).

**3. ✅ `manualGenerateQuestions` open to all authenticated users — FIXED**
Admin claim check is now active. Also applied to `manualDailyGeneration` and `purgeEasyQuestions`. Set admin claim via:
```bash
node -e "require('firebase-admin').initializeApp(); require('firebase-admin').auth().setCustomUserClaims('<UID>', {admin:true})"
```

**4. ✅ Matchmaking race condition — FIXED**
`joinMatchmaking` now uses an RTDB `transaction()` to atomically claim the matched opponent's queue entry. If the transaction aborts (race lost), the caller falls back to joining the queue.

### High — Security

**5. ✅ Client-side XP writes unrestricted — MITIGATED**
Firestore rules now cap XP delta per write to ≤100 and level delta to ≤1. Full server-side XP (moving `addXp()` to a Cloud Function) is a recommended future improvement.

**6. ✅ RTDB matchmaking queue publicly readable — FIXED**
`database.rules.json` now requires `auth != null` to read matchmaking entries.

### Medium — Question Content

**7. ✅ "Underlined text" references in Writing/English prompts — FIXED**
`geminiHelper.ts:buildPrompt()` now injects a `writingEnglishGuard` block for `Writing` and `English` sections, explicitly forbidding "underlined" phrasing and showing correct alternatives.
**Action still needed:** Run a Firestore query to delete existing questions containing "underlined" in `questionText` or `choices`. Use the pattern: `db.collection("questions").where("section","in",["Writing","English"]).get()` then filter on `/underlined/i`.

**8. ✅ `GraphAndTableInterpretation` missing visual guards — FIXED**
`VISUAL_SKILLS` set added in `geminiHelper.ts`. This skill now receives full visual element instructions and a note that graph/table data must be embedded in the passage.

**9. ✅ ACT Science numbered figure labels — FIXED**
`scienceExtraGuard` block added to `visualInstructions` for `section === "Science"`, forbidding "Figure 1", "Table 2", etc.

**10. ✅ 18 known broken Math questions — FUNCTION ADDED**
`purgeKnownBrokenQuestions` (admin-only `onCall`) added to `index.ts`. Call it once after deploying to remove the 18 flagged questions. IDs sourced from `functions/flagged_questions.json`.

### Low — Remaining

**11. User emails in public Firestore documents**
`users/{userId}` is publicly readable. If `email` is stored in the document body it is exposed. Do not display it in UI; ideally remove from Firestore and keep only in Firebase Auth.

**12. Battle answer timing — hardcoded server-side**
`submitBattleAnswer` has `const timeSpent = 15` — all correct answers deal 12 damage regardless of actual speed. The 30-second client timer enforces timeouts by sending answer = -1, but the speed-tier damage tiers (15/12/10) are not enforced server-side.

---

## Notifications System

FCM push-only (Android). `notification_service.dart` handles tokens, permissions, and tap routing. `notificationHelper.ts` sends and logs. User preferences stored in `users/{userId}.notificationPreferences`. See original CLAUDE.md Notifications section for adding new types (5-step process involving both `notificationHelper.ts` and `user_model.dart`).

---

## Security Rules Summary (post-fix)

| Collection | Client Read | Client Write |
|---|---|---|
| `users/{userId}` | Public (all) | Owner only; `battleStats`, `friendCode` blocked; XP capped ≤100/write |
| `questions` | Public | Never |
| `friendships` | Participants only | Never (Functions only) |
| `battleResults` | Participants only | Never |
| `leaderboards` | Authenticated | Never |
| `achievements` | Authenticated | Never |
| RTDB `/battles` | Participants only | **Never** (fixed) |
| RTDB `/matchmaking` | Authenticated only (fixed) | Owner only |

---

## Pre-Launch Checklist

**Code-fixed — deploy required:**
- [x] Secure admin HTTP endpoints — set `ADMIN_SECRET` env var, then deploy functions
- [x] RTDB battle write rules — deploy database rules
- [x] Admin gate on generation functions — deploy functions
- [x] Matchmaking race condition — deploy functions
- [x] XP write cap in Firestore rules — deploy firestore rules
- [x] Matchmaking read requires auth — deploy database rules

**Deploy command:**
```bash
firebase deploy --only functions,firestore:rules,database
```

**Still required before launch:**
- [ ] Set `ADMIN_SECRET` environment variable in Firebase Functions configuration
- [ ] Set admin custom claim on your Firebase Auth account
- [ ] Call `purgeKnownBrokenQuestions` once (after deploy) to delete 18 broken Math questions
- [ ] Run Firestore scan to delete Writing/English questions with "underlined" references
- [ ] Create Privacy Policy and Terms of Service (host externally, link in auth screens and settings)
- [ ] Replace AdMob test App ID with production ID

**Recommended:**
- [ ] Move study-mode XP (`addXp`) to a Cloud Function for full server-side validation
- [ ] Add Crashlytics for error tracking
- [ ] Add back button confirmation for active battles
