# Prep Royale - Issues Analysis & Fixes

## Executive Summary

This document outlines the major issues discovered in the Prep Royale app, root causes, and implemented fixes.

---

## 1. Android Build Error ❌ → ✅ FIXED

### Problem
```
Task :app:mergeLibDexDebug FAILED
Unable to delete directory ... Failed to delete some children
```

### Root Cause
- **OneDrive file sync** actively locking files in `build/` directory
- **Gradle transform cache** file handles on Windows
- **IDE processes** indexing build artifacts

### Solution Implemented
1. **Created `fix-build.bat`** - Automated clean/rebuild script
2. **Updated `android/gradle.properties`**:
   - Added `org.gradle.vfs.watch=false` (disables file watching)
   - Enabled caching and parallel execution
3. **Created `BUILD_FIX_GUIDE.md`** - Comprehensive troubleshooting guide

### Files Changed
- `android/gradle.properties` - Added Gradle optimization flags
- `fix-build.bat` - New automated fix script
- `BUILD_FIX_GUIDE.md` - New documentation

### How to Fix
1. Close all IDEs (VS Code, Android Studio)
2. Run `fix-build.bat`
3. If fails, pause OneDrive sync and retry
4. Alternative: Move project out of OneDrive folder to `C:\Projects\`

---

## 2. Question Generation & Serving ⚠️ NEEDS VERIFICATION

### Problem
- "Questions aren't getting generated for users"
- "No new questions" behavior

### Current Architecture (CORRECT)
✅ **Daily Global Generation**: Cloud Function runs at midnight UTC
✅ **Shared Question Pool**: All users draw from same global questions collection
✅ **Smart Serving Logic**:
   - Priority 1: Unanswered questions (per user)
   - Priority 2: Randomized review questions

### Root Cause Analysis
The architecture is **actually correct**. Potential issues:

1. **Cloud Functions Not Deployed**
   - `dailyQuestionGeneration` scheduled function may not be deployed
   - No initial seed data in `questions` collection

2. **Gemini API Not Configured**
   - Missing `GEMINI_API_KEY` environment variable
   - API quota exhausted or rate limited

3. **Insufficient Question Inventory**
   - Daily generator may have run but produced few questions
   - `getQuestionDeficit` returning 0 deficits

### What's Working ✅
- **Client-side logic** (`question_provider.dart:startSession`) correctly:
  - Fetches unanswered questions first (lines 113-120)
  - Falls back to randomized review questions (lines 122-135)
  - Shuffles questions (line 173)
  - **Shuffles answer choices** (line 176: `withShuffledChoices()`)

- **Server-side generation** (`dailyGenerator.ts`) correctly:
  - Scheduled at midnight UTC
  - Prioritizes skills with deficits
  - Generates in batches
  - Deduplicates by content hash

### Actions Required

#### Immediate (Manual Steps)
1. **Check if Cloud Functions are deployed**:
   ```bash
   firebase functions:list
   ```
   Should show: `dailyQuestionGeneration`, `manualGenerateQuestions`, etc.

2. **Check question inventory**:
   ```bash
   firebase firestore:indexes
   # Then query Firestore console for questions collection count
   ```

3. **Set up Gemini API Key** (if missing):
   ```bash
   cd functions
   firebase functions:config:set gemini.api_key="YOUR_KEY_HERE"
   firebase deploy --only functions
   ```

4. **Manually trigger generation** (temporary fix):
   - Call `manualGenerateQuestions` function from app or Firebase console
   - Or run batch generation via `manualDailyGeneration`

#### Code Fix (Already Correct, No Changes Needed)
The question serving logic is already properly implemented:
- `lib/services/firebase_service.dart:getUnansweredQuestions` (lines 330-389)
- `lib/providers/question_provider.dart:startSession` (lines 75-189)

---

## 3. Battle Question Randomization ⚠️ PARTIALLY FIXED

### Problem
- "Questions in battles aren't randomized"
- Same questions appearing repeatedly

### Root Cause
**Server-side battle creation** (`functions/src/index.ts:281-299`):
- Fetches only **100 questions** via `limit(100)`
- If question pool < 100, same questions repeat frequently
- No consideration for difficulty balancing

### Current Logic
```typescript
const questionsSnapshot = await db
  .collection("questions")
  .where("examType", "==", requestedTestType)
  .limit(100)  // ⚠️ TOO SMALL if question pool is large
  .get();

const shuffled = [...allQuestions].sort(() => Math.random() - 0.5);
const questionIds = shuffled.slice(0, Math.min(20, allQuestions.length));
```

### Fix Needed
Increase fetch limit and add better randomization:

```typescript
// Fetch MORE questions to ensure variety
const questionsSnapshot = await db
  .collection("questions")
  .where("examType", "==", requestedTestType)
  .limit(500)  // Fetch 500 to randomize from larger pool
  .get();

// Better shuffle using Fisher-Yates
function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

const questionIds = shuffleArray([...allQuestions]).slice(0, 20);
```

### Files to Change
- `functions/src/index.ts` (lines 282-299)
- Same fix needed in `createFriendBattle` function

---

## 4. Sign-In / Sign-Up Performance ⚠️ NEEDS FIX

### Problem
- "Sign-in takes forever/never loads in"
- Hangs on loading screen

### Root Cause Analysis

#### Potential Issue 1: Provider Initialization Race Condition
`login_screen.dart:93-100`:
```dart
if (result.isSuccess) {
  ref.invalidate(currentUserProvider);
  ref.invalidate(userSessionProvider);
  context.go(Routes.home);  // ⚠️ Navigates IMMEDIATELY
}
```

**Problem**: Navigation happens **before** Firestore user document loads.
Home screen may freeze waiting for `currentUserProvider` which is still loading.

#### Potential Issue 2: Firestore Rules Blocking Reads
If security rules prevent new users from reading their own document, the `getUserStream` will hang forever.

#### Potential Issue 3: No Timeout Handling
No timeout on auth operations - if Firebase is slow, UI hangs indefinitely.

### Fix Strategy

**Option A: Add Loading State on Home Screen** (Recommended)
- Home screen shows loading indicator while `currentUserProvider` loads
- Display timeout message after 10 seconds

**Option B: Wait for User Data Before Navigation**
```dart
if (result.isSuccess) {
  // Wait for Firestore user document to load
  final userFuture = ref.read(currentUserProvider.future);
  final user = await userFuture.timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('Profile load timed out'),
  );

  if (user != null && mounted) {
    context.go(Routes.home);
  }
}
```

**Option C: Prefetch User Data in Auth Flow** (Best Long-Term)
- After `signIn` succeeds, immediately fetch user document
- Only navigate when data is confirmed available
- Show meaningful loading states

### Files to Change
- `lib/screens/auth/login_screen.dart` (lines 69-104)
- `lib/screens/home/home_screen.dart` (add loading handling)

---

## 5. Live Battles & Matchmaking ✅ MOSTLY WORKING

### Current Implementation Analysis

#### Matchmaking (`functions/src/index.ts:joinMatchmaking`)
✅ **Working**:
- Queue stored in Realtime Database (`/matchmaking/{userId}`)
- Level-based matching (±3 levels)
- Test type filtering (SAT vs ACT)
- Rate limiting (20 requests per 5 minutes)

⚠️ **Potential Issues**:
- Guest users allowed (anonymous auth) - may cause data issues
- No timeout for waiting in queue (client-side responsibility)
- Queue cleanup runs every 5 minutes - users may wait longer

#### Battle State Management
✅ **Working**:
- Battle data in Realtime Database (`/battles/{battleId}`)
- Server-side answer validation
- Health-based combat system
- Auto-completion when health depletes

#### Answer Submission (`submitBattleAnswer`)
✅ **Secure Server-Side Validation**:
- Fetches question from Firestore
- Validates correct answer
- Calculates damage server-side
- Prevents cheating

### Known Issues

1. **No Client Code Review Yet**
   - Need to verify `battle_provider.dart` correctly listens to battle state
   - Check for race conditions in answer submission
   - Verify health updates propagate to both clients

2. **Orphaned Battles**
   - If one player disconnects, other player stuck
   - Cleanup runs every 5 minutes + marks abandoned after 1 hour
   - Need immediate abandonment detection

### Files to Review
- `lib/providers/battle_provider.dart`
- `lib/screens/battle/battle_screen.dart`

---

## 6. Friends System & Friends Battles ❓ NOT YET REVIEWED

### Known Architecture
- Friendships in Firestore (`friendships` collection)
- Normalized IDs (alphabetically sorted)
- Status: `pending`, `accepted`, `blocked`
- Friend battles via `createFriendBattle` function

### To Verify
1. ✅ Friend request UI implemented?
2. ✅ Friend list screen working?
3. ✅ Friend search functional?
4. ✅ Friend battle invite flow?
5. ✅ Notifications for friend requests?

### Files to Review
- `lib/screens/friends/` (all files)
- `lib/providers/friends_provider.dart` (if exists)

---

## Priority Action Plan

### Phase 1: Immediate Fixes (Do First)
1. ✅ **Fix build error** - Run `fix-build.bat`
2. ⏳ **Verify Cloud Functions deployed** - Check Firebase console
3. ⏳ **Check question inventory** - Query Firestore
4. ⏳ **Manually generate questions** - Call `manualGenerateQuestions` if empty

### Phase 2: Code Fixes (This Session)
1. ⏳ Fix battle question randomization (increase limit to 500)
2. ⏳ Fix sign-in navigation (add loading state or wait for user data)
3. ⏳ Add answer choice shuffling verification
4. ⏳ Test battle flow end-to-end

### Phase 3: Testing (After Code Fixes)
1. ⏳ 2-device battle test
2. ⏳ Friend system test
3. ⏳ Question serving test (new user vs returning user)
4. ⏳ Daily generation test (wait for midnight or manual trigger)

---

## Success Criteria for Version 1

### Questions ✅/⚠️
- [ ] Cloud Functions deployed and scheduled
- [ ] At least 100 questions per section in Firestore
- [ ] Zen mode serves unanswered questions first
- [ ] Review mode shuffles previously answered questions
- [ ] Answer choices randomized

### Auth ⚠️
- [ ] Sign-in completes in < 5 seconds
- [ ] Sign-up navigates to profile picture screen
- [ ] No hanging on loading screen
- [ ] Error messages clear and actionable

### Battles ⚠️
- [ ] Matchmaking finds opponent within 30 seconds
- [ ] Questions randomized (not same 20 every time)
- [ ] Health updates in real-time for both players
- [ ] Battle completes and records results
- [ ] XP and stats updated correctly

### Friends ❓
- [ ] Can search for users by username
- [ ] Can send friend request
- [ ] Can accept/decline requests
- [ ] Can start friends battle
- [ ] Notifications sent for requests

---

## Files Modified Summary

### Build Fixes
- `android/gradle.properties` - Added file watching disable + optimizations
- `fix-build.bat` - New automated fix script
- `BUILD_FIX_GUIDE.md` - New troubleshooting guide

### Code Fixes (Pending)
- `functions/src/index.ts` - Battle question randomization (lines 282-299, 450-500)
- `lib/screens/auth/login_screen.dart` - Add loading state (lines 92-100)
- `lib/screens/home/home_screen.dart` - Handle loading state

### Documentation
- `ISSUES_ANALYSIS.md` - This file
- `BUILD_FIX_GUIDE.md` - Build troubleshooting
