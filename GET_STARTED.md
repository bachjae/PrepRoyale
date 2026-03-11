# GET STARTED - 1-2 Day Build Plan

This guide will help you build the complete SAT/ACT study app in **1-2 days** using Claude Code.

## 🎯 Simplified Scope

**REMOVED** from original design:
- ❌ Character/avatar system
- ❌ Cosmetic shop and in-app currency
- ❌ Complex animations
- ❌ Premium subscriptions

**KEPT** for MVP:
- ✅ Profile pictures (upload or presets)
- ✅ Level/XP progression
- ✅ AI-generated questions
- ✅ Streak tracking (daily + accuracy)
- ✅ Real-time battles
- ✅ Achievements system
- ✅ Leaderboards
- ✅ Home screen widgets

---

## ⚡ Quick Start (Before You Begin)

### Prerequisites
```bash
# Verify Flutter installation
flutter --version  # Should be 3.16+

# Verify Firebase CLI
firebase --version

# OpenAI API key
# Get from: https://platform.openai.com/api-keys
```

### Initial Setup (30 minutes)
```bash
# 1. Create Firebase project
firebase login
firebase projects:create sat-act-study

# 2. Clone/create project directory
mkdir sat_act_app
cd sat_act_app

# 3. Initialize Flutter
flutter create .
flutter pub add flutter_riverpod go_router firebase_core firebase_auth \
  cloud_firestore firebase_database cloud_functions firebase_storage \
  cloud_firestore cached_network_image image_picker home_widget workmanager

# 4. Initialize Firebase in project
firebase init
# Select: Firestore, Functions, Storage

# 5. Configure OpenAI
cd functions
npm install openai
firebase functions:config:set openai.api_key="YOUR_KEY_HERE"
cd ..
```

---

## 📅 DAY 1: CORE FOUNDATION (6-8 hours)

### Morning Session (3-4 hours)

#### Task 1: Firebase & Auth Setup (1 hour)
**With Claude Code:**
```
"Set up Firebase configuration files for iOS and Android. 
Create authentication screens for email/password login and signup.
Use Riverpod for state management."
```

**Expected Output:**
- `lib/config/firebase_config.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/signup_screen.dart`
- `lib/providers/auth_provider.dart`

**Manual Steps:**
1. Download `google-services.json` from Firebase Console → Android
2. Download `GoogleService-Info.plist` from Firebase Console → iOS
3. Place in `android/app/` and `ios/Runner/` respectively

#### Task 2: Navigation & Home Screen (1 hour)
**With Claude Code:**
```
"Create GoRouter configuration with routes for home, study, battle, 
profile, and leaderboard. Build a home screen that shows:
- Profile picture and username at top
- Level and XP progress bar
- Daily streak (🔥) and accuracy streak (⚡)
- Three main buttons: Practice, Battle, Leaderboard
Use Material 3 design and make it look clean."
```

**Expected Output:**
- `lib/config/router.dart`
- `lib/screens/home/home_screen.dart`
- `lib/widgets/common/xp_progress_bar.dart`
- `lib/widgets/common/streak_display.dart`

#### Task 3: User Model & Service (1 hour)
**With Claude Code:**
```
"Create UserModel with profile picture, username, level, XP, stats, 
streaks, and achievements. Create FirebaseService with methods to:
- Create user profile on signup
- Get user data
- Update user stats, XP, level
- Update streaks
Use the models I already created in lib/models/user_model.dart"
```

**Expected Output:**
- `lib/services/firebase_service.dart` (comprehensive)
- User profile auto-created on signup
- Real-time user data streaming

#### Task 4: Profile Picture Selection (30 min)
**With Claude Code:**
```
"Create a profile picture picker that allows users to:
1. Choose from 10 preset avatar images (use emoji or placeholder URLs)
2. Upload custom image from camera or gallery
Store uploaded images in Firebase Storage.
Show this during signup and in profile settings."
```

**Expected Output:**
- `lib/screens/auth/profile_picture_selector.dart`
- `lib/services/storage_service.dart`
- Preset avatars ready to use

---

### Afternoon Session (3-4 hours)

#### Task 5: Question Generation Setup (1.5 hours)
**With Claude Code:**
```
"Create Cloud Function to generate SAT/ACT questions using OpenAI GPT-4.
Function should:
- Accept: testType (SAT/ACT), section, skill, difficulty
- Generate 5 questions with choices and explanations
- Validate JSON structure
- Store in Firestore /questions collection
Return question IDs to client.

Also create QuestionModel and UserAnswer models."
```

**Expected Output:**
- `functions/src/index.ts` with `generateQuestions` function
- `lib/models/question_model.dart`
- Questions stored in Firestore

**Deploy:**
```bash
cd functions
firebase deploy --only functions
cd ..
```

#### Task 6: Study Mode Screens (2 hours)
**With Claude Code:**
```
"Create study mode flow:
1. Study mode selector: Choose SAT or ACT, then section (Math, Reading, etc.)
2. Question screen that:
   - Displays question text and passage if needed
   - Shows 4 answer choices (A, B, C, D)
   - Has submit button
   - Shows timer for time tracking
3. Answer feedback screen:
   - Shows if correct/incorrect
   - Displays explanation
   - Shows XP earned (+10 correct, +5 incorrect)
   - Has Next Question button
4. Fetch questions from Firestore, generate new ones if needed
5. Track time spent and record answer to Firestore"
```

**Expected Output:**
- `lib/screens/study/study_mode_selector.dart`
- `lib/screens/study/question_screen.dart`
- `lib/screens/study/answer_feedback_screen.dart`
- `lib/providers/question_provider.dart`

#### Task 7: Stats & Streak Tracking (1 hour)
**With Claude Code:**
```
"Implement streak tracking:
1. Daily streak: Increment when user answers ≥1 question per day
2. Accuracy streak: Count consecutive correct answers, reset on wrong answer
3. Update user stats after each answer (total questions, accuracy by section)
4. Check for streak milestones and show notifications
Add logic to FirebaseService"
```

**Expected Output:**
- Streak logic in `firebase_service.dart`
- Real-time streak updates
- Stats properly calculated

---

### End of Day 1 Checkpoint

**You should have:**
- ✅ Working authentication
- ✅ Home screen with profile info
- ✅ Study mode with AI-generated questions
- ✅ Streak tracking functional
- ✅ Stats recording

**Test it:**
1. Sign up new user
2. Answer 10 questions
3. Verify XP increases
4. Check streak increments
5. Answer 1 wrong, verify accuracy streak resets

---

## 📅 DAY 2: FEATURES & POLISH (6-8 hours)

### Morning Session (3-4 hours)

#### Task 8: Achievements System (1.5 hours)
**With Claude Code:**
```
"Implement achievements system:
1. Create Achievement model (already in lib/models/achievement_model.dart)
2. Seed Firestore with default achievements from DefaultAchievements.all
3. Create achievement checking logic:
   - After each answer, check if user unlocked achievements
   - After battle, check battle achievements
   - Check streak achievements daily
4. Create achievements display screen showing:
   - Locked achievements (grayed out)
   - Unlocked achievements (with unlock date)
   - Progress bars for each
5. Show popup notification when achievement unlocked"
```

**Expected Output:**
- Achievement seeding script
- `lib/services/achievement_service.dart`
- `lib/screens/profile/achievements_screen.dart`
- `lib/widgets/common/achievement_popup.dart`

#### Task 9: Leaderboard (1 hour)
**With Claude Code:**
```
"Create leaderboard system:
1. Cloud Function to update leaderboard on user XP changes
2. Leaderboard screen showing:
   - Top 100 users globally (rank, profile pic, username, level, XP)
   - Friends leaderboard (if friends exist)
   - Highlight current user
   - Pull to refresh
3. Use Firestore collection: /leaderboards/global/entries/{userId}"
```

**Expected Output:**
- Cloud Function: `updateLeaderboard`
- `lib/screens/leaderboard/leaderboard_screen.dart`
- `lib/providers/leaderboard_provider.dart`

**Deploy:**
```bash
cd functions
firebase deploy --only functions
cd ..
```

#### Task 10: Profile & Stats Screen (1 hour)
**With Claude Code:**
```
"Create profile screen showing:
- Large profile picture (tappable to change)
- Username and level
- XP progress to next level
- Stats section:
  - Total questions answered
  - Overall accuracy
  - Breakdown by section (SAT Math: 85%, etc.)
- Streaks section:
  - Daily streak with best
  - Accuracy streak with best
- Battle stats:
  - Wins / Losses
  - Win rate percentage
- Achievements button (navigate to achievements screen)
- Settings/logout button"
```

**Expected Output:**
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/profile/edit_profile_screen.dart`

---

### Afternoon Session (3-4 hours)

#### Task 11: Battle System (2 hours)
**With Claude Code:**
```
"Implement real-time battle system:
1. Matchmaking Cloud Function:
   - Add user to queue with level
   - Find opponent within ±3 levels
   - Create battle in Realtime Database
   - Generate 5 questions for battle
2. Battle screen:
   - Show both players (profile pic, username, score)
   - Display questions one at a time
   - Show live timer (45s per question)
   - Update scores in real-time
   - After 5 questions, show winner
3. Battle results screen:
   - Show final scores
   - Award bonus XP to winner
   - Update battle stats (wins/losses)
   - Rematch or exit options
Use Firebase Realtime Database for battle state, Firestore for results"
```

**Expected Output:**
- Cloud Function: `joinMatchmaking`, `createBattle`
- `lib/screens/battle/battle_lobby.dart`
- `lib/screens/battle/battle_screen.dart`
- `lib/screens/battle/battle_results.dart`
- `lib/providers/battle_provider.dart`
- `lib/models/battle_model.dart`

**Deploy:**
```bash
cd functions
firebase deploy --only functions
cd ..
```

#### Task 12: Home Screen Widget (1.5 hours)
**With Claude Code:**
```
"Create home screen widget for iOS and Android:
1. Display random SAT/ACT study tip
2. Show current daily streak
3. Quick 'Study Now' button that deep links to app
4. Update widget hourly using WorkManager
5. Store tips in Firestore /widgetTips collection
Seed with 20 initial tips about SAT/ACT strategies"
```

**Expected Output:**
- `lib/services/widget_service.dart`
- `ios/WidgetExtension/` (iOS widget code)
- `android/.../widget/` (Android widget code)
- Widget tips seeded in Firestore

**Manual iOS Setup:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Add Widget Extension target
3. Configure App Group ID

**Manual Android Setup:**
1. Create widget layout XML
2. Create AppWidgetProvider class

#### Task 13: Testing & Bug Fixes (30 min)
**With Claude Code:**
```
"Add error handling and loading states to all screens.
Add retry logic for failed network requests.
Test complete user flow:
1. Signup → Study 10 questions → Check achievements
2. Battle another user (test with 2 devices/emulators)
3. View leaderboard
4. Check widget updates
Fix any bugs found"
```

#### Task 14: Polish & UI Improvements (30 min)
**With Claude Code:**
```
"Polish the UI:
1. Add smooth transitions between screens
2. Add loading skeletons for leaderboard and profile
3. Add empty states (no achievements, no battles yet)
4. Add confirmation dialogs (logout, etc.)
5. Ensure consistent spacing and colors throughout
6. Add haptic feedback for important actions (level up, achievement unlock)"
```

---

### End of Day 2 Checkpoint

**You should have:**
- ✅ Complete achievements system
- ✅ Working leaderboards
- ✅ Profile with full stats
- ✅ Real-time battles
- ✅ Home screen widgets
- ✅ Polished UI

**Final Test:**
1. Create 2 accounts
2. Answer questions on both
3. Start battle between them
4. Verify scores update in real-time
5. Check winner gets XP
6. Verify achievements unlock
7. Check leaderboard updates
8. Test widget on home screen

---

## 🚀 DEPLOYMENT (Optional - Beyond 2 Days)

### Firebase Deployment
```bash
# Deploy everything
firebase deploy

# Or deploy individually
firebase deploy --only firestore:rules
firebase deploy --only functions
firebase deploy --only storage
```

### App Store / Play Store (Future)
If you want to publish (3-5 additional days):
1. Create app icons and screenshots
2. Write app descriptions
3. Test on real devices
4. Submit to App Store Connect (iOS)
5. Submit to Google Play Console (Android)

---

## 🎯 Success Checklist

### Day 1 Deliverables
- [ ] Authentication works (signup/login)
- [ ] Home screen displays user info
- [ ] Can select study mode and sections
- [ ] Questions load and display correctly
- [ ] Answers are recorded
- [ ] XP increases after each answer
- [ ] Streaks increment properly
- [ ] Stats update in real-time

### Day 2 Deliverables
- [ ] Achievements unlock automatically
- [ ] Achievement screen shows all badges
- [ ] Leaderboard displays top users
- [ ] Profile shows all user stats
- [ ] Can change profile picture
- [ ] Battles work with matchmaking
- [ ] Battle scores update in real-time
- [ ] Winner is determined correctly
- [ ] Widget displays on home screen
- [ ] Widget updates with new tips

---

## 💡 Tips for Success

### Working with Claude Code

1. **Be specific in prompts**: 
   - ❌ "Create the battle system"
   - ✅ "Create a battle screen that shows two players side by side with their profile pictures and scores, displays questions one at a time, and updates scores in real-time using Firebase Realtime Database"

2. **Build incrementally**:
   - Don't ask for entire features at once
   - Build UI first, then add logic
   - Test after each major component

3. **Reference existing code**:
   - "Use the UserModel I created in lib/models/user_model.dart"
   - "Follow the same pattern as the question_screen.dart"

4. **Ask for specific file creation**:
   - "Create lib/screens/battle/battle_screen.dart"
   - "Update lib/services/firebase_service.dart to add a new method"

### Common Issues

**Firebase initialization fails:**
- Verify `google-services.json` and `GoogleService-Info.plist` are in correct folders
- Run `flutter clean` and `flutter pub get`

**Questions not generating:**
- Check OpenAI API key is set: `firebase functions:config:get`
- Check Cloud Function logs: `firebase functions:log`

**Real-time battle not working:**
- Verify Firebase Realtime Database is enabled in console
- Check database rules allow read/write

**Widget not updating:**
- Verify App Group ID matches in iOS
- Check WorkManager is initialized in Android

---

## 📊 Cost Estimate (Post-Launch)

For **1,000 active users/month:**

| Service | Cost |
|---------|------|
| Firebase (Firestore, Auth, Functions) | $25-50 |
| OpenAI API (question generation) | $20-40 |
| Firebase Storage (profile pictures) | $5 |
| **Total** | **$50-95/month** |

For **10,000 active users/month:**
- ~$200-400/month total

**Cost Optimization:**
- Pre-generate 1000+ questions to reduce OpenAI costs
- Cache questions on client to reduce Firestore reads
- Use Firestore offline persistence

---

## 🎉 You're Ready to Build!

Follow this guide step by step with Claude Code. By the end of Day 2, you'll have a fully functional SAT/ACT study app ready for user testing.

**Start Now:**
1. Complete "Quick Start" setup (30 min)
2. Begin Day 1, Task 1
3. Use Claude Code for each task
4. Test frequently
5. Ship MVP in 1-2 days! 🚀

Good luck!
