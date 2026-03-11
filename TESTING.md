# Prep Royale - Comprehensive Testing Guide

## Testing Philosophy

This guide provides **manual test scripts** for all major features. Each test includes:
- **Prerequisites**: What needs to be set up first
- **Steps**: Exact actions to perform
- **Expected Results**: What should happen
- **Pass/Fail Criteria**: How to know if the test passed
- **Troubleshooting**: What to check if test fails

---

## Test Environment Setup

### Required
- ✅ Android device or emulator (API 21+, recommended API 34+)
- ✅ Firebase project deployed (see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md))
- ✅ Cloud Functions deployed
- ✅ At least 100 questions in Firestore (50+ SAT, 50+ ACT)
- ✅ Two test accounts for battle/friends testing

### Optional
- Second Android device for real-time battle testing
- Network throttling tool for slow connection testing

---

## Test Suite 1: Authentication & Onboarding

### Test 1.1: New User Sign-Up
**Prerequisites**: None

**Steps**:
1. Launch app
2. Click "Sign Up" button
3. Enter:
   - Email: `testuser1@example.com`
   - Password: `Test123456!`
   - Username: `TestUser1`
4. Click "Create Account"
5. Wait for profile picture screen
6. Select any avatar
7. Click "Save"

**Expected Results**:
- Step 4: Loading indicator appears with rotating tips
- Step 5: Navigate to profile picture screen within 3 seconds
- Step 7: Navigate to home screen within 2 seconds
- Home screen shows:
  - Username: "TestUser1"
  - Level: 1
  - XP: 0/100
  - Daily Streak: 0
  - Zen Mode and Battle Mode cards visible

**Pass Criteria**:
✅ Account created successfully
✅ Navigation smooth, no hangs
✅ User data displays correctly on home screen

**Fail Scenarios**:
❌ Hangs on "Create Account" for > 10 seconds
❌ Error: "Username already taken" (try different username)
❌ Error: "Email already in use" (use different email)
❌ Navigates to home but shows loading forever
❌ User data shows null or default values

**Troubleshooting**:
- Check Firestore `users` collection has new document with `userId`
- Verify Firebase Auth shows new user in Authentication panel
- Check `usernameLower` field exists in user document
- Review app logs for Firebase errors

---

### Test 1.2: Existing User Sign-In
**Prerequisites**: Account created in Test 1.1

**Steps**:
1. Close and reopen app
2. App shows login screen (auto-logout after app close)
3. Click "Sign In" tab
4. Enter:
   - Email: `testuser1@example.com`
   - Password: `Test123456!`
5. Click "Sign In"

**Expected Results**:
- Step 5: Loading indicator with tips
- Navigate to home screen within 5 seconds
- Home screen shows same user data as Test 1.1
- Daily streak may have incremented if previous test was yesterday

**Pass Criteria**:
✅ Sign-in completes quickly (< 5 seconds)
✅ User data loaded correctly
✅ No errors or hangs

**Fail Scenarios**:
❌ Error: "User not found" or "Wrong password"
❌ Hangs on loading screen > 10 seconds
❌ Home screen shows default/guest data instead of user data

---

### Test 1.3: Guest Mode
**Prerequisites**: None

**Steps**:
1. Launch app (signed out)
2. Click "Continue as Guest"

**Expected Results**:
- Navigate to home screen immediately
- Shows:
  - Username: "Guest"
  - Level: 1
  - XP: 0
  - "Sign up to save progress" banner visible
- Can access Zen Mode but NOT Battle Mode or Friends

**Pass Criteria**:
✅ Guest mode loads instantly
✅ Zen Mode functional
✅ Battle/Friends disabled with upgrade prompts

---

## Test Suite 2: Question Generation & Serving

### Test 2.1: Question Inventory Check
**Prerequisites**: Cloud Functions deployed, Gemini API configured

**Steps**:
1. Open Firebase Console
2. Go to Firestore Database
3. Open `questions` collection
4. Count documents

**Expected Results**:
- At least 100 total questions
- Questions have fields:
  - `examType`: "SAT" or "ACT"
  - `section`: String (e.g., "Math", "Reading")
  - `skill`: String (e.g., "LinearEquations")
  - `difficulty`: Number 1-5
  - `questionText`: String
  - `choices`: Array of 4 strings
  - `correctAnswer`: Number 0-3
  - `explanation`: String
  - `contentHash`: String

**Pass Criteria**:
✅ >= 100 questions exist
✅ All required fields present
✅ `examType` values are exactly "SAT" or "ACT" (case-sensitive)

**Troubleshooting**:
- If < 100 questions, run manual generation (see DEPLOYMENT_GUIDE.md Step 5)
- Check Cloud Function `dailyQuestionGeneration` logs
- Verify Gemini API key is set: `firebase functions:config:get`

---

### Test 2.2: Zen Mode - Unanswered Questions
**Prerequisites**:
- Signed in as TestUser1
- At least 20 SAT Math questions in Firestore
- TestUser1 has NOT answered any questions yet

**Steps**:
1. From home screen, click "Zen Mode"
2. Select "SAT"
3. Select "Math" section
4. Click "Start Session"
5. Note the question text and correct answer position (A/B/C/D)
6. Answer all 10 questions
7. Exit to home
8. Repeat steps 1-4 (start new SAT Math session)

**Expected Results**:
- Step 4: Questions load within 3 seconds
- Step 5: First question is from SAT Math section
- Step 6: All 10 questions are unique (no duplicates in same session)
- Step 8: New session shows 10 NEW questions (not same as first session)

**Pass Criteria**:
✅ Questions load quickly
✅ All questions match selected section (SAT Math)
✅ No duplicate questions in same session
✅ Second session shows different questions (unanswered ones)

---

### Test 2.3: Zen Mode - Review Mode
**Prerequisites**:
- Signed in as TestUser1
- TestUser1 has answered ALL available SAT Math questions

**Steps**:
1. Start new SAT Math session
2. Note if questions are ones already answered

**Expected Results**:
- Questions load (even though all are answered)
- Questions are randomized (shuffled)
- May see previously answered questions

**Pass Criteria**:
✅ Questions still load (no "No questions available" error)
✅ Questions are shuffled each session
✅ App doesn't crash when no unanswered questions remain

---

### Test 2.4: Answer Choice Randomization
**Prerequisites**: At least 20 SAT Math questions

**Steps**:
1. Start SAT Math session
2. Note Question 1:
   - Question text: "______"
   - Correct answer position: A, B, C, or D
   - What the correct answer says: "______"
3. Answer question (can answer wrong, doesn't matter)
4. Continue to Question 2-5
5. Quit session
6. Start NEW SAT Math session
7. Check if Question 1 appears again:
   - Same question text?
   - **Same correct answer content?**
   - **Different correct answer position?** ⬅️ THIS IS THE KEY TEST

**Expected Results**:
- Step 7: If same question appears, the correct answer CONTENT is the same
- Step 7: But the correct answer POSITION (A/B/C/D) is different

**Example**:
First session:
```
Question: What is 2 + 2?
A) 3
B) 4  ← Correct (answered B)
C) 5
D) 6
```

Second session (same question):
```
Question: What is 2 + 2?
A) 5
B) 6
C) 4  ← Correct (now answer is C)
D) 3
```

**Pass Criteria**:
✅ Correct answer content stays the same
✅ Correct answer position changes between sessions
✅ All 4 choices are present (no missing options)

**Troubleshooting**:
- Check `question_provider.dart:176` calls `withShuffledChoices()`
- Check `QuestionModel.withShuffledChoices()` implementation
- Redeploy app if code missing

---

## Test Suite 3: Stats & Progression

### Test 3.1: XP and Leveling
**Prerequisites**: Signed in as TestUser1

**Steps**:
1. Note current XP and level (e.g., Level 1, 0/100 XP)
2. Start Zen Mode session
3. Answer 10 questions (mix of correct and incorrect)
4. Return to home screen
5. Check new XP and level

**Expected Results**:
- Correct answers: +10 XP each
- Incorrect answers: +5 XP each
- XP bar shows progress
- If XP >= 100, level increases to 2
- Level 2 requires 400 XP total (XP bar shows X/400)

**Pass Criteria**:
✅ XP increases after answering questions
✅ Level up occurs when XP threshold reached
✅ XP calculation follows formula: 100 * N * N (where N = next level)

---

### Test 3.2: Daily Streak
**Prerequisites**: Signed in, answered at least 1 question today

**Steps**:
1. Note current daily streak count
2. Answer 1 question in Zen Mode
3. Return to home
4. Check daily streak

**Expected Results**:
- If first activity today: Streak increments by 1
- If already active today: Streak stays same
- Streak display shows fire emoji and count

**Pass Criteria**:
✅ Streak increments on first daily activity
✅ Streak does NOT increment multiple times per day
✅ Streak persists across app restarts

---

### Test 3.3: Section Accuracy Tracking
**Prerequisites**: Answered at least 5 SAT Math questions

**Steps**:
1. Go to Profile tab
2. Scroll to "Section Accuracy" or stats area
3. Check SAT Math accuracy percentage

**Expected Results**:
- Shows accuracy (e.g., "60%" if 3/5 correct)
- Accuracy updates after each question answered

**Pass Criteria**:
✅ Accuracy displayed correctly
✅ Updates in real-time

---

## Test Suite 4: Battle Mode (Matchmaking)

### Test 4.1: Single Player Queue (No Match)
**Prerequisites**: Signed in, only one user online

**Steps**:
1. From home, click "Battle Mode"
2. Select "SAT"
3. Click "Find Opponent"
4. Wait 30 seconds

**Expected Results**:
- Shows "Searching for opponent..." screen
- Animated waiting indicator
- No match found (since no other users online)
- Can click "Cancel" to exit queue

**Pass Criteria**:
✅ Queue entry successful
✅ UI shows waiting state
✅ Cancel button works

---

### Test 4.2: Two Player Match (REQUIRES 2 DEVICES)
**Prerequisites**:
- Two devices with different accounts (TestUser1, TestUser2)
- Both users at similar levels (±3 levels)
- At least 20 SAT questions in Firestore

**Steps (Device 1 - TestUser1)**:
1. Click "Battle Mode"
2. Select "SAT"
3. Click "Find Opponent"
4. Wait for match

**Steps (Device 2 - TestUser2)**:
5. Click "Battle Mode"
6. Select "SAT" (same as Device 1)
7. Click "Find Opponent"

**Expected Results**:
- Step 7: Both devices match within 5 seconds
- Both navigate to battle screen
- Both see opponent info (username, level, profile picture)
- Both start with 100 HP
- First question loads on both devices

**Pass Criteria**:
✅ Match found quickly (< 5 seconds after Device 2 joins)
✅ Battle initializes correctly on both devices
✅ Question loads on both devices

**Fail Scenarios**:
❌ No match after 30 seconds
❌ Only one device enters battle
❌ Questions don't load
❌ HP bars don't show

**Troubleshooting**:
- Check Realtime Database `/matchmaking` node has entries
- Verify both users selected SAME test type
- Check Cloud Function `joinMatchmaking` logs
- Verify level difference <= 3

---

### Test 4.3: Battle Gameplay
**Prerequisites**: Test 4.2 passed, both devices in battle

**Steps (Both Devices)**:
1. Read Question 1
2. Device 1 answers CORRECTLY within 15 seconds
3. Check health bars on both devices
4. Device 2 answers INCORRECTLY
5. Check health bars again
6. Both continue answering questions
7. Battle ends when:
   - One player's HP reaches 0, OR
   - All 20 questions answered

**Expected Results**:
- Step 3:
  - Device 2 (opponent) loses 15 HP (now 85/100)
  - Device 1 stays at 100 HP
- Step 5:
  - Device 2 loses 8 more HP (self-damage, now 77/100)
  - Device 1 stays at 100 HP
- Step 6: Questions advance automatically after both answer
- Step 7: Battle completes, shows results screen with:
  - Winner/Loser
  - XP earned
  - Stats updated

**Pass Criteria**:
✅ Correct answers deal damage to opponent
✅ Incorrect answers deal self-damage
✅ Health updates in real-time on both devices
✅ Battle ends correctly
✅ Results screen shows accurate stats

**Damage Table** (for verification):
| Scenario | Damage |
|----------|--------|
| Correct answer (≤15s) | 15 damage to opponent |
| Correct answer (16-30s) | 12 damage to opponent |
| Correct answer (>30s) | 10 damage to opponent |
| Incorrect answer | 8 self-damage |
| Timeout (no answer) | 15 self-damage |

---

### Test 4.4: Battle Question Randomization
**Prerequisites**: At least 100 SAT questions in Firestore

**Steps**:
1. Complete a battle (Test 4.2 & 4.3)
2. Note the questions that appeared (write down Question 1's text)
3. Start a NEW battle with same test type
4. Check if Question 1 is the same

**Expected Results**:
- Second battle should have DIFFERENT questions
- Questions should NOT be in the same order
- Over 5 battles, should see ~100 unique questions (if 100+ exist)

**Pass Criteria**:
✅ Questions randomized between battles
✅ Not same 20 questions every time
✅ No obvious patterns

**If FAILS**:
- Verify fix in `functions/src/index.ts:286` (limit should be 500)
- Redeploy Cloud Functions
- Generate more questions

---

## Test Suite 5: Friends System

### Test 5.1: User Search
**Prerequisites**:
- Two accounts: TestUser1, TestUser2
- Signed in as TestUser1

**Steps**:
1. Go to "Friends" tab
2. Click "Add Friend" or search icon
3. Search for "TestUser2" (exact username)
4. Search for "testuser2" (lowercase)
5. Search for "Test" (partial match)

**Expected Results**:
- Step 3: TestUser2 appears in search results
- Step 4: TestUser2 appears (case-insensitive search)
- Step 5: TestUser2 appears if username starts with "Test"

**Pass Criteria**:
✅ Search works (finds user)
✅ Case-insensitive
✅ Shows username, level, profile picture

**Troubleshooting**:
- Check Firestore `users` collection has `usernameLower` field
- Verify Cloud Function `searchUsers` deployed
- Check function logs for errors

---

### Test 5.2: Send Friend Request
**Prerequisites**: Test 5.1 passed

**Steps**:
1. From search results, click TestUser2
2. Click "Send Friend Request"
3. Wait for confirmation

**Expected Results**:
- Shows "Request Sent" or similar confirmation
- Button changes to "Pending" or disabled state
- Cannot send duplicate requests

**Pass Criteria**:
✅ Request sent successfully
✅ UI updates to show pending state
✅ No errors

---

### Test 5.3: Accept Friend Request
**Prerequisites**: Test 5.2 passed, signed in as TestUser2

**Steps**:
1. Go to "Friends" tab
2. Check for friend request notification
3. Click "Accept"

**Expected Results**:
- Friend request appears in pending/notifications area
- Shows TestUser1's username and profile picture
- After accepting:
  - Both users see each other in friends list
  - Can now challenge to battle

**Pass Criteria**:
✅ Request received and visible
✅ Accept button works
✅ Both users become friends

---

### Test 5.4: Friends Battle
**Prerequisites**: Test 5.3 passed (TestUser1 and TestUser2 are friends)

**Steps (TestUser1)**:
1. Go to Friends tab
2. Click on TestUser2 in friends list
3. Click "Challenge to Battle"
4. Select "SAT"
5. Confirm challenge

**Steps (TestUser2)**:
6. Receive notification (if FCM configured) OR check Friends tab
7. See battle invite
8. Click "Accept Challenge"

**Expected Results**:
- Both users enter battle
- Battle functions same as matchmaking (Test 4.3)
- Battle marked as "Friend Battle" (optional)

**Pass Criteria**:
✅ Battle invite sent
✅ TestUser2 can see and accept invite
✅ Battle starts and functions correctly

---

## Test Suite 6: Edge Cases & Error Handling

### Test 6.1: No Internet Connection
**Prerequisites**: Device with airplane mode or network toggle

**Steps**:
1. Sign in normally
2. Enable airplane mode
3. Try to start Zen Mode session
4. Try to start Battle Mode

**Expected Results**:
- Zen Mode: May show cached questions OR error message
- Battle Mode: Shows error "No internet connection"
- Sign-in: Shows error if attempting fresh sign-in

**Pass Criteria**:
✅ App doesn't crash
✅ Clear error messages shown
✅ Retry buttons functional

---

### Test 6.2: Battle Disconnect (One Player Quits)
**Prerequisites**: Two devices in battle

**Steps**:
1. Start battle (Test 4.2)
2. Device 1 answers first question
3. Device 2 closes app (force quit)
4. Device 1 continues answering questions

**Expected Results**:
- Device 1: Battle continues (opponent becomes inactive)
- After 1 hour: Battle auto-abandoned by cleanup function
- Device 1 may win by default if opponent never answers

**Pass Criteria**:
✅ App doesn't crash
✅ Device 1 can complete battle solo
✅ Results recorded correctly

---

### Test 6.3: Empty Question Inventory
**Prerequisites**: Firestore `questions` collection is empty or has < 10 questions

**Steps**:
1. Try to start Zen Mode session
2. Try to start Battle Mode

**Expected Results**:
- Shows error message: "No questions available for this section. Please try a different section."
- OR: "No questions available for this test type yet. AI generation might be in progress."

**Pass Criteria**:
✅ Clear error message
✅ No crash
✅ User can go back and try different section

**Troubleshooting**:
- Generate questions (see DEPLOYMENT_GUIDE.md Step 5)

---

## Test Suite 7: Notifications (Android Only)

### Test 7.1: Friend Request Notification
**Prerequisites**: FCM configured, TestUser1 sends friend request to TestUser2

**Steps**:
1. TestUser1 sends friend request
2. Check TestUser2's device notification tray

**Expected Results**:
- Notification appears: "TestUser1 sent you a friend request"
- Tapping opens app to Friends tab

**Pass Criteria**:
✅ Notification received
✅ Tap opens app correctly

**If FAILS**:
- Check FCM token saved in Firestore `users/{userId}/fcmToken`
- Check Cloud Function `sendFriendRequestNotification` logs
- Verify Firebase Cloud Messaging enabled

---

## Test Report Template

After running tests, fill out this report:

```
# Test Run Report
Date: __________
Tester: __________
Environment: [Device/Emulator, Android Version]

## Results Summary
Total Tests: __
Passed: __
Failed: __
Skipped: __

## Test Results
### Authentication & Onboarding
- [ ] 1.1 Sign-Up: [PASS/FAIL]
- [ ] 1.2 Sign-In: [PASS/FAIL]
- [ ] 1.3 Guest Mode: [PASS/FAIL]

### Question Generation & Serving
- [ ] 2.1 Question Inventory: [PASS/FAIL] (__ questions found)
- [ ] 2.2 Unanswered Questions: [PASS/FAIL]
- [ ] 2.3 Review Mode: [PASS/FAIL]
- [ ] 2.4 Answer Randomization: [PASS/FAIL]

### Stats & Progression
- [ ] 3.1 XP and Leveling: [PASS/FAIL]
- [ ] 3.2 Daily Streak: [PASS/FAIL]
- [ ] 3.3 Section Accuracy: [PASS/FAIL]

### Battle Mode
- [ ] 4.1 Single Player Queue: [PASS/FAIL]
- [ ] 4.2 Two Player Match: [PASS/FAIL]
- [ ] 4.3 Battle Gameplay: [PASS/FAIL]
- [ ] 4.4 Question Randomization: [PASS/FAIL]

### Friends System
- [ ] 5.1 User Search: [PASS/FAIL]
- [ ] 5.2 Send Request: [PASS/FAIL]
- [ ] 5.3 Accept Request: [PASS/FAIL]
- [ ] 5.4 Friends Battle: [PASS/FAIL]

### Edge Cases
- [ ] 6.1 No Internet: [PASS/FAIL]
- [ ] 6.2 Battle Disconnect: [PASS/FAIL]
- [ ] 6.3 Empty Questions: [PASS/FAIL]

### Notifications (Optional)
- [ ] 7.1 Friend Request Notification: [PASS/FAIL/SKIPPED]

## Critical Failures (Blocking Release)
1. __________
2. __________

## Minor Issues (Non-Blocking)
1. __________
2. __________

## Notes
__________
```

---

## Automated Testing (Future)

Current status: **Manual testing only**

Future improvements:
- Unit tests for models and services
- Widget tests for UI components
- Integration tests for auth flow
- End-to-end tests for battle mode

See `test/` directory for existing test stubs.
