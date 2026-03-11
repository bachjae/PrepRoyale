# SAT/ACT Study App - Simplified MVP
## Complete 1-2 Day Build Package

---

## 🎯 WHAT YOU'RE BUILDING

A streamlined SAT/ACT study app with:
- ✅ Profile pictures & user profiles (no complex avatars)
- ✅ Level/XP progression system
- ✅ AI-generated practice questions
- ✅ Streak tracking (daily login + accuracy streaks)
- ✅ Achievement badges
- ✅ Real-time 1v1 quiz battles
- ✅ Leaderboards (global + friends)
- ✅ Home screen widgets (iOS/Android)

**SIMPLIFIED** from original (to fit 1-2 days):
- ❌ No character customization
- ❌ No in-app shop
- ❌ No virtual currency
- ❌ No complex animations
- ❌ No premium subscriptions

---

## 📦 PACKAGE CONTENTS

### Documentation
1. **README.md** - Project overview and features
2. **GET_STARTED.md** ⭐ **START HERE** - Complete 1-2 day build plan
3. **ARCHITECTURE.md** - System design (if you need reference)

### Code Structure
```
lib/
├── models/
│   ├── user_model.dart          # User profile, stats, streaks
│   ├── question_model.dart       # Questions and answers
│   ├── battle_model.dart         # Battle state
│   └── achievement_model.dart    # Achievements
│
├── providers/                    # (To be created with Claude Code)
├── services/                     # (To be created with Claude Code)
├── screens/                      # (To be created with Claude Code)
├── widgets/                      # (To be created with Claude Code)
└── config/                       # (To be created with Claude Code)

functions/
└── src/
    └── index.ts                  # Cloud Functions (AI generation, matchmaking)

firestore.rules                   # Database security
database.rules.json               # Realtime DB security
pubspec.yaml                      # Flutter dependencies
```

---

## 🚀 QUICK START (5 Minutes)

### 1. Prerequisites Check
```bash
flutter --version    # Need 3.16+
firebase --version   # Need Firebase CLI
```

### 2. Get OpenAI API Key
- Go to https://platform.openai.com/api-keys
- Create new secret key
- Save it (you'll need this in setup)

### 3. Open GET_STARTED.md
**This is your step-by-step guide!**

It contains:
- Complete Day 1 schedule (6-8 hours)
- Complete Day 2 schedule (6-8 hours)  
- Exact prompts to use with Claude Code
- Testing checkpoints
- Troubleshooting tips

---

## 💡 KEY FEATURES OVERVIEW

### User System
- Email/password authentication
- Profile picture (upload custom or choose preset)
- Username and display name
- Level based on total XP earned
- XP progress bar to next level

### Study Mode
**Flow:**
1. Choose SAT or ACT
2. Select section (Math, Reading, Writing, Science)
3. Answer questions infinitely
4. Get immediate feedback + explanation
5. Earn XP (+10 correct, +5 incorrect)

**Question Generation:**
- AI-powered via OpenAI GPT-4
- Realistic SAT/ACT format
- Adaptive difficulty
- Cached to reduce costs

### Streaks
**Daily Streak** 🔥
- Increments when user answers ≥1 question/day
- Resets if missed 24+ hours
- Milestones unlock achievements

**Accuracy Streak** ⚡
- Consecutive correct answers
- Resets immediately on wrong answer
- Best streak tracked

### Achievements
14 pre-defined achievements:
- **Questions**: First Steps (10), Century (100), Dedicated (500), Master (1000)
- **Streaks**: Week Warrior (7), Month Champion (30), Unstoppable (100)
- **Accuracy**: Sharpshooter (10), Perfectionist (20), Flawless (50)
- **Battles**: Battle Ready (1), Victor (10), Champion (50), Legend (100)

Each unlocks automatically and awards bonus XP.

### Real-Time Battles
**Matchmaking:**
- Click "Battle" button
- Automatically matched with player ±3 levels
- 5-10 second wait time

**Battle Flow:**
1. Both players see same 5 questions
2. 45 seconds per question
3. Scores update in real-time
4. Winner determined by total score
5. Bonus XP awarded

**Scoring:**
- Correct answer: 100 points
- Speed bonus: 0-50 points (faster = more)
- Incorrect: 0 points

### Leaderboards
- **Global**: Top 100 users by total XP
- **Friends**: Just your friends' rankings
- Shows: rank, profile pic, username, level, XP
- Updates automatically when users gain XP

### Home Screen Widget
**iOS & Android:**
- Random SAT/ACT study tip
- Updates hourly
- Shows current daily streak
- "Study Now" button (deep links to app)

---

## 🏗️ TECH STACK

### Frontend
- **Flutter 3.16+** - Cross-platform mobile
- **Riverpod** - State management
- **go_router** - Navigation

### Backend
- **Firebase Auth** - User authentication
- **Cloud Firestore** - Primary database
- **Realtime Database** - Battle synchronization
- **Cloud Functions** - Serverless (Node.js)
- **Cloud Storage** - Profile pictures

### AI
- **OpenAI GPT-4** - Question generation

---

## 📊 DATA MODELS (Already Created)

### UserModel
- Profile: email, username, profilePictureUrl
- Progress: level, xp, totalXp
- Stats: total questions, accuracy by section
- Streaks: daily (count, lastDate), accuracy (current, best)
- Battles: wins, losses, winRate
- Achievements: list of unlocked achievementIds

### QuestionModel
- Test: testType (SAT/ACT), section, skill
- Content: questionText, passage?, choices[4], correctAnswer
- Meta: difficulty (1-5), explanation, createdAt

### BattleModel
- Players: player1, player2 (username, level, profilePic, score)
- State: status, currentQuestionIndex, questionIds
- Result: winnerId

### Achievement
- Info: name, description, emoji
- Type: category (questions/streaks/battles/accuracy)
- Unlock: requirement (e.g., 100 questions)

---

## ⏱️ TIME BREAKDOWN

### Day 1 (6-8 hours)
- **Morning**: Auth, navigation, home screen, user profiles (4h)
- **Afternoon**: Question generation, study mode, streak tracking (4h)

### Day 2 (6-8 hours)
- **Morning**: Achievements, leaderboard, profile screen (4h)
- **Afternoon**: Battle system, widgets, polish (4h)

**Total: 12-16 hours of focused work**

---

## 🎓 USING WITH CLAUDE CODE

### Best Practices

1. **Be Specific in Prompts**
   ```
   ✅ "Create a home screen with a profile picture at the top, 
       XP progress bar, two streak displays (daily with fire emoji, 
       accuracy with lightning), and three buttons for Practice, 
       Battle, and Leaderboard. Use Material 3 design."
   
   ❌ "Make the home screen"
   ```

2. **Reference Existing Code**
   ```
   "Use the UserModel from lib/models/user_model.dart to display 
    the user's stats on the profile screen"
   ```

3. **Build Incrementally**
   - First: UI/layout
   - Then: Add data/logic
   - Finally: Polish/animations

4. **Test Frequently**
   - After each major component
   - Use hot reload during development
   - Test on both iOS and Android simulators

### Example Prompt Sequence

**Prompt 1:**
```
"Create Firebase authentication screens for email/password login 
and signup. Use Riverpod for state management. Include form 
validation and error handling."
```

**Prompt 2:**
```
"Build a home screen that displays the current user's profile 
picture, username, level, and XP progress bar. Add displays for 
daily streak (🔥) and accuracy streak (⚡). Include three main 
action buttons: Practice, Battle, and Leaderboard. Use the 
UserModel from lib/models/user_model.dart."
```

**Prompt 3:**
```
"Create the study mode flow: selector screen to choose SAT/ACT 
and section, then a question screen that fetches questions from 
Firestore, displays them with 4 answer choices, tracks time spent, 
and shows feedback with explanation. Award XP for each answer."
```

Continue with prompts from GET_STARTED.md...

---

## 🐛 COMMON ISSUES

### Firebase won't initialize
**Fix:** Verify `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct directories.

### Questions not generating
**Fix:** 
1. Check OpenAI API key: `firebase functions:config:get`
2. View logs: `firebase functions:log`

### Real-time battles not syncing
**Fix:** 
1. Enable Realtime Database in Firebase Console
2. Deploy database rules: `firebase deploy --only database`

### Widget not updating
**Fix:**
1. iOS: Verify App Group ID matches
2. Android: Check WorkManager initialization

---

## 💰 ESTIMATED COSTS

### Development
- **Time**: 12-16 hours
- **Your Rate**: (Your hourly rate)

### Monthly Operations (1000 users)
- Firebase: $25-50/month
- OpenAI: $20-40/month
- **Total: $45-90/month**

### Scaling (10,000 users)
- Firebase: $100-200/month
- OpenAI: $50-100/month
- **Total: $150-300/month**

**Pro Tip:** Pre-generate 500-1000 questions to reduce OpenAI costs by 80%+

---

## 📈 SUCCESS CHECKLIST

### End of Day 1
- [ ] Can sign up and login
- [ ] Home screen shows user info
- [ ] Can select study mode
- [ ] Questions display correctly
- [ ] Answers are recorded
- [ ] XP increases after answers
- [ ] Streaks increment properly

### End of Day 2
- [ ] Achievements unlock automatically
- [ ] Leaderboard shows top users
- [ ] Profile displays all stats
- [ ] Can upload profile picture
- [ ] Battles work with matchmaking
- [ ] Scores update in real-time
- [ ] Widget displays on home screen

---

## 🎯 NEXT STEPS

1. **Read GET_STARTED.md** (your detailed guide)
2. Complete prerequisites setup (30 min)
3. Begin Day 1, Task 1
4. Use Claude Code for each task
5. Test after each task
6. Complete MVP in 1-2 days!

---

## 📞 NEED HELP?

**Documentation:**
- GET_STARTED.md - Step-by-step guide
- README.md - Feature overview
- Code comments - Implementation details

**External Resources:**
- Flutter docs: https://docs.flutter.dev
- Firebase docs: https://firebase.google.com/docs
- Riverpod docs: https://riverpod.dev

---

## 🎉 YOU'RE READY TO BUILD!

This simplified version removes complexity while keeping all the fun, engaging features that make studying addictive. You can build a production-quality MVP in just 1-2 focused days.

**Start now with GET_STARTED.md!** 🚀
