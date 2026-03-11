# Prep Royale - Deployment & Testing Guide

## Prerequisites

### Required Tools
- ✅ Node.js 18+ (for Cloud Functions)
- ✅ Flutter 3.41.2+ (currently using 3.41.2)
- ✅ Firebase CLI (`npm install -g firebase-tools`)
- ✅ Android SDK (API 36 for targetSdk)

### Firebase Project Setup
- Project ID: `sat-act-battle-royale`
- Firestore Database (production mode)
- Realtime Database
- Firebase Authentication (Email/Password + Google Sign-In)
- Firebase Storage
- Cloud Functions (Node 18 runtime)
- Firebase Cloud Messaging (FCM)

---

## Step 1: Fix Android Build (MUST DO FIRST)

### Quick Fix
```cmd
# Close all IDEs first!
fix-build.bat
```

### If That Fails
1. **Pause OneDrive sync** on the project folder (2 hours)
2. **Close all programs** accessing the folder
3. Run PowerShell as Admin:
   ```powershell
   cd "C:\Users\tsuom\OneDrive\Desktop\SAT-ACT Battle Royale"
   Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
   Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
   Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
   ```
4. Run `fix-build.bat` again

### Verify Build Works
```cmd
flutter build apk --debug
```

**Expected**: APK created at `build\app\outputs\flutter-apk\app-debug.apk`

---

## Step 2: Deploy Cloud Functions (CRITICAL FOR QUESTIONS)

### Build Functions
```cmd
cd functions
npm install
npm run build
```

### Check for Errors
- TypeScript compilation errors? Fix before deploying
- Missing dependencies? Run `npm install` again

### Deploy to Firebase
```cmd
firebase deploy --only functions
```

**IMPORTANT**: This deploys:
- `dailyQuestionGeneration` - Runs at midnight UTC
- `manualGenerateQuestions` - Manual question generation
- `joinMatchmaking` - Battle matchmaking
- `submitBattleAnswer` - Battle answer validation
- `createFriendBattle` - Friends battles
- Friend system functions
- Notification functions

### Verify Deployment
```cmd
firebase functions:list
```

**Expected Output**:
```
✔  functions: Loaded functions definitions from source
┌─────────────────────────────────────┬───────────────────┐
│ Function Name                       │ Type              │
├─────────────────────────────────────┼───────────────────┤
│ dailyQuestionGeneration             │ scheduled         │
│ manualGenerateQuestions             │ callable          │
│ joinMatchmaking                     │ callable          │
│ submitBattleAnswer                  │ callable          │
│ createFriendBattle                  │ callable          │
│ ... (more functions)                │                   │
└─────────────────────────────────────┴───────────────────┘
```

---

## Step 3: Set Up Gemini API (FOR QUESTION GENERATION)

### Get API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key for Gemini API

### Set Environment Variable
```cmd
cd functions
firebase functions:config:set gemini.api_key="YOUR_GEMINI_API_KEY_HERE"
```

### Redeploy Functions
```cmd
firebase deploy --only functions
```

---

## Step 4: Deploy Firestore & Database Rules

### Deploy Rules
```cmd
firebase deploy --only firestore:rules,database
```

**This deploys**:
- `firestore.rules` - Security rules for Firestore
- `database.rules.json` - Security rules for Realtime Database

### Verify Rules
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to `Firestore Database` > `Rules`
3. Check that rules were updated (timestamp should be recent)
4. Navigate to `Realtime Database` > `Rules`
5. Verify rules are active

---

## Step 5: Generate Initial Questions

### Option A: Manual Generation (Recommended for Testing)
Use the Flutter app:
1. Sign in as admin (any authenticated user for now)
2. Navigate to Settings or use Firebase console
3. Call `manualGenerateQuestions` function with:
   ```json
   {
     "examType": "SAT",
     "section": "Math",
     "skill": "LinearEquations",
     "count": 20
   }
   ```

### Option B: Trigger Daily Generator
From Firebase Console:
1. Go to `Functions` > `dailyQuestionGeneration`
2. Click "Run Now" or wait for scheduled run (midnight UTC)

### Option C: Firebase CLI
```cmd
firebase functions:log --only dailyQuestionGeneration
```

### Verify Questions Created
1. Open [Firestore Console](https://console.firebase.google.com/)
2. Go to `Firestore Database` > `questions` collection
3. **Expected**: Documents with fields:
   - `examType`: "SAT" or "ACT"
   - `section`: "Math", "Reading", "Writing", etc.
   - `skill`: Specific skill name
   - `difficulty`: 1-5
   - `choices`: Array of 4 strings
   - `correctAnswer`: 0-3
   - `explanation`: String
   - `contentHash`: String (for deduplication)

### Minimum Questions Needed
For basic testing:
- **SAT Math**: 20 questions (any skills)
- **SAT Reading**: 20 questions
- **SAT Writing**: 20 questions
- **ACT Math**: 20 questions
- **ACT English**: 20 questions
- **ACT Reading**: 20 questions
- **ACT Science**: 20 questions

**Total Minimum**: ~140 questions for full test coverage

---

## Step 6: Test the App

### Run on Device/Emulator
```cmd
flutter run
```

### If Build Fails
See [BUILD_FIX_GUIDE.md](BUILD_FIX_GUIDE.md)

---

## Step 7: Critical Tests

### Test 1: Sign-Up & Sign-In ✅
**Steps**:
1. Open app
2. Click "Sign Up"
3. Enter email, password, username
4. Click "Create Account"
5. **Expected**: Navigate to profile picture selection
6. Select avatar and save
7. **Expected**: Navigate to home screen within 5 seconds

**If Hangs**:
- Check Firestore rules allow user document read
- Check Firebase console logs for errors
- Verify user document was created in `users` collection

### Test 2: Zen Mode (Study) ✅
**Steps**:
1. From home, click "Zen Mode"
2. Select SAT or ACT
3. Select a section (e.g., Math)
4. Click "Start Session"
5. **Expected**: Question loads within 3 seconds
6. Answer question
7. **Expected**: Shows if correct/incorrect with explanation
8. Click "Next Question"
9. **Expected**: New question loads (different from first)
10. Answer 5 more questions
11. **Expected**: All questions are different

**If No Questions**:
- Check Firestore `questions` collection has documents
- Check `examType` and `section` fields match selection
- Run manual question generation (Step 5)

**If Same Questions Repeat**:
- This is OK for review mode if you've answered all questions
- Check `user/{userId}/answers` subcollection
- Expected behavior: Unanswered questions first, then randomized review

### Test 3: Battle Mode (Matchmaking) ⚠️ REQUIRES 2 DEVICES
**Steps (Device 1)**:
1. Sign in as User A
2. Click "Battle Mode"
3. Select test type (SAT or ACT)
4. Click "Find Opponent"
5. **Expected**: Shows "Searching for opponent..." screen

**Steps (Device 2)**:
1. Sign in as User B (different account)
2. Click "Battle Mode"
3. Select **same test type** as User A
4. Click "Find Opponent"
5. **Expected**: Match found within 5 seconds

**Both Devices**:
6. **Expected**: Battle screen loads with first question
7. User A answers question
8. **Expected**: User A's health updates, opponent takes damage
9. User B answers question
10. **Expected**: User B's health updates, User A takes damage
11. Continue until 20 questions or one player's health reaches 0
12. **Expected**: Battle ends, results shown, XP awarded

**If Matchmaking Fails**:
- Check Realtime Database `matchmaking` node has entries
- Check Cloud Function `joinMatchmaking` logs in Firebase console
- Verify both users have similar levels (±3 levels)
- Check `functions/src/index.ts:250-262` for matching logic

**If Questions Don't Load**:
- Check Firestore has at least 20 questions for the test type
- Check `functions/src/index.ts:282-305` (question selection logic)
- Verify Cloud Functions deployed correctly

### Test 4: Friends System ✅
**Steps (User A)**:
1. Go to Friends tab
2. Click "Add Friend"
3. Search for User B's username
4. Send friend request

**Steps (User B)**:
5. Go to Friends tab
6. **Expected**: See friend request notification
7. Accept request

**Both Users**:
8. **Expected**: See each other in friends list

**User A**:
9. Click on User B in friends list
10. Click "Challenge to Battle"
11. **Expected**: Battle created

**User B**:
12. **Expected**: Receive notification (if FCM set up)
13. Navigate to battle
14. **Expected**: Battle starts

**If Friend Search Fails**:
- Check `users` collection has `usernameLower` field
- Check Cloud Function `searchUsers` deployed
- Verify username is lowercase searchable

### Test 5: Answer Randomization ✅
**Steps**:
1. Start a Zen Mode session
2. Note the first question and correct answer position (A, B, C, or D)
3. Answer and move to next question
4. Quit and restart app
5. Start a new session with same section
6. **Expected**: Same questions may appear BUT correct answer is in **different position**

**Verification**:
- Check `lib/models/question_model.dart` for `withShuffledChoices()` method
- Check `lib/providers/question_provider.dart:176` calls `withShuffledChoices()`

---

## Step 8: Monitor Production

### Check Cloud Functions Logs
```cmd
cd functions
npm run logs
```

Or in Firebase Console:
1. Go to `Functions` > Select function
2. Click `Logs` tab

### Check Question Generation
```cmd
firebase firestore:data:get questions --limit 10
```

Or query Firestore Console:
1. Go to `Firestore Database`
2. Open `questions` collection
3. Check document count and fields

### Check for Errors
```cmd
firebase functions:log --only dailyQuestionGeneration
firebase functions:log --only joinMatchmaking
firebase functions:log --only submitBattleAnswer
```

---

## Common Issues & Fixes

### Issue: "No questions available"
**Fix**:
1. Check Firestore `questions` collection is not empty
2. Manually generate questions (Step 5)
3. Verify `examType` field matches "SAT" or "ACT" exactly
4. Check Firestore indexes are created

### Issue: Sign-in hangs forever
**Fix**:
1. Check home screen shows loading indicator (should see spinner)
2. Check Firestore rules allow user document read
3. Add timeout handling (see `ISSUES_ANALYSIS.md`)
4. Check Firebase console for auth errors

### Issue: Matchmaking never finds opponent
**Fix**:
1. Use two devices with accounts at similar levels
2. Select **same test type** (SAT or ACT)
3. Check Realtime Database has `/matchmaking` node
4. Check Cloud Function `joinMatchmaking` is deployed
5. Check function logs for errors

### Issue: Battle questions same every time
**Fix**:
1. Verify fix in `functions/src/index.ts:286` (limit increased to 500)
2. Redeploy functions: `firebase deploy --only functions`
3. Generate more questions (at least 100+ per test type)
4. Check Fisher-Yates shuffle is implemented (lines 299-304)

### Issue: Android build fails
**Fix**:
- See [BUILD_FIX_GUIDE.md](BUILD_FIX_GUIDE.md)
- Run `fix-build.bat`
- Pause OneDrive sync

---

## Production Checklist

Before launching to users:

### Security
- [ ] Cloud Functions deployed with latest security fixes
- [ ] Firestore rules deployed (read-only questions, protected user fields)
- [ ] Realtime Database rules deployed (battle access restricted)
- [ ] Rate limiting active (matchmaking, friend requests)

### Data
- [ ] At least 100 questions per section generated
- [ ] Questions have proper `examType`, `section`, `skill` fields
- [ ] Questions deduplicated (no duplicate `contentHash`)

### Features
- [ ] Sign-up/sign-in working and fast (< 5 seconds)
- [ ] Zen mode serves questions correctly
- [ ] Battle mode functional (tested with 2 devices)
- [ ] Friends system working (search, add, accept, battle)
- [ ] Notifications configured (FCM for Android)

### Legal
- [ ] Privacy Policy added to app
- [ ] Terms of Service added to app
- [ ] Legal links in login/signup screens
- [ ] Delete account function working

### Testing
- [ ] Tested on physical Android device (not just emulator)
- [ ] Tested with slow internet connection
- [ ] Tested guest mode
- [ ] Tested account creation, deletion, password reset
- [ ] Tested all battle scenarios (win, lose, disconnect)

---

## Next Steps After Deployment

1. **Monitor Logs**: Check Firebase console daily for errors
2. **Question Inventory**: Ensure daily generator runs successfully
3. **User Feedback**: Add in-app feedback mechanism
4. **Analytics**: Set up Firebase Analytics to track engagement
5. **Crashlytics**: Enable Firebase Crashlytics for error tracking

---

## Support

If deployment fails or tests don't pass:
1. Check [ISSUES_ANALYSIS.md](ISSUES_ANALYSIS.md) for known issues
2. Check [BUILD_FIX_GUIDE.md](BUILD_FIX_GUIDE.md) for build errors
3. Review Firebase console logs for specific errors
4. Verify all prerequisites installed correctly
