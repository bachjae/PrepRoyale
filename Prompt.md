# SAT/ACT Study App – Multi‑Agent Claude Code Prompt

You are a team of specialized coding agents collaborating to build a fully working MVP of a SAT/ACT study mobile app in Flutter using Firebase and OpenAI, as specified in the documents `PROJECT_OVERVIEW.md` and `GET_STARTED.md` in this repository.[file:1][file:2]

Your goal:  
- Deliver a complete, buildable MVP that matches the simplified scope and features described in those two docs.  
- Follow the 1–2 day build structure, but you may parallelize work across agents to accelerate development.[file:2]

Use these global rules:

- Stack:
  - Flutter 3.16+ for iOS and Android.[file:1]
  - State management with Riverpod.[file:1][file:2]
  - Routing with go_router.[file:1][file:2]
  - Backend: Firebase Auth, Firestore, Realtime Database, Cloud Functions (Node/TypeScript), Firebase Storage.[file:1][file:2]
  - AI: OpenAI GPT-4 (via Cloud Functions) for SAT/ACT question generation.[file:1][file:2]

- Scope (MVP features you MUST implement):
  - Email/password authentication with user profiles.
  - Profile picture support (presets + upload to Firebase Storage).
  - Level/XP progression system.
  - AI-generated practice questions with explanations.
  - Study mode flow (SAT/ACT, sections, timed questions, feedback, XP).
  - Streak tracking: daily streak 🔥 and accuracy streak ⚡.
  - Achievements system (using predefined achievements from models).
  - Real-time 1v1 quiz battles with matchmaking and scoring.
  - Leaderboards (global, and ready for friends later).
  - Home screen widgets (iOS + Android) with tips and streak info.
  - Basic polish: loading/error states, simple transitions, consistent styling.[file:1][file:2]

- Out of scope (explicitly DO NOT build):
  - Character/avatar customization beyond simple profile pictures.
   - In-app shop.
  - Virtual currency.
  - Complex animations.
  - Premium subscriptions or paywalls.[file:1][file:2]

- Code organization (must follow this structure):
  - `lib/models/` (already contains user_model.dart, question_model.dart, battle_model.dart, achievement_model.dart; use these as source of truth).[file:1]
  - `lib/providers/` for Riverpod providers.
  - `lib/services/` for Firebase, AI, widgets, achievements, etc.
  - `lib/screens/` for UI screens.
  - `lib/widgets/` for reusable widgets.
  - `lib/config/` for router, Firebase initialization, theme, etc.
  - `functions/src/index.ts` for Cloud Functions.
  - Root Firebase config and rules files (`firestore.rules`, `database.rules.json`).[file:1][file:2]

- Implementation style:
  - Build in small, testable increments.
  - Prefer clear, typed Dart and TypeScript.
  - Keep dependencies aligned with the ones listed in `GET_STARTED.md` (flutter_riverpod, go_router, firebase_core, firebase_auth, cloud_firestore, firebase_database, cloud_functions, firebase_storage, cached_network_image, image_picker, home_widget, workmanager).[file:2]
  - Add minimal but clear comments where non-obvious logic occurs (e.g., streak calculations, matchmaking).

- Assume:
  - Firebase project already created and CLI initialized as described in GET_STARTED, or at least that the human developer will handle `google-services.json` / `GoogleService-Info.plist` placement and `firebase init` / `firebase deploy` commands manually.[file:2]
  - An OpenAI API key will be configured in Cloud Functions via `firebase functions:config:set openai.api_key="..."` by the human.[file:2]

You must coordinate multiple agents, each handling a subset of the work, and run them in parallel whenever there are no hard dependencies. Before coding, have a short “planning” phase where one coordinator agent breaks down tasks and assigns them. Then implement.

---

## Agent Roles and Responsibilities

Create at least these agents and let them collaborate:

### 1) Architect & Coordinator Agent

- Reads `PROJECT_OVERVIEW.md` and `GET_STARTED.md` to understand requirements, data models, and feature list.[file:1][file:2]  
- Produces a concrete task breakdown tied to files and modules, roughly aligned to “Day 1” and “Day 2”, but optimized for parallel work.[file:2]  
- Defines contracts/interfaces between layers:
  - Models ↔ services.
  - Services ↔ providers.
  - Providers ↔ screens/widgets.[file:1][file:2]
- Ensures agents follow a consistent style (naming, folder structure, error handling).
- Maintains a checklist mirroring the “Success Checklist” from the docs and keeps it updated.[file:1][file:2]
- Validates that all MVP features listed above are covered before declaring completion.

### 2) Flutter App & Navigation Agent

Focus: App entry, routing, core layout, shared widgets.

Tasks:
- Create app bootstrap:
  - `lib/main.dart` with Firebase initialization, Riverpod `ProviderScope`, Material 3 theme, and GoRouter setup.[file:1][file:2]
- Create router configuration:
  - `lib/config/router.dart` with routes for:
    - Auth: login, signup, optional onboarding/profile picture selector.
    - Home.
    - Study: study_mode_selector, question_screen, answer_feedback_screen.
    - Battle: lobby, battle_screen, battle_results.
    - Profile: profile_screen, edit_profile_screen, achievements_screen.
    - Leaderboard: leaderboard_screen.
- Build `lib/screens/home/home_screen.dart`:
  - Shows user’s profile picture, username, level, and XP progress bar.
  - Shows daily streak 🔥 and accuracy streak ⚡.
  - Three main buttons: Practice, Battle, Leaderboard.[file:1][file:2]
- Create shared widgets:
  - `lib/widgets/common/xp_progress_bar.dart`.
  - `lib/widgets/common/streak_display.dart`.
  - Common button styles, card components, and simple skeleton/placeholder widgets for loading states.
- Ensure UI uses Material 3 and looks clean and consistent across screens.[file:2]

### 3) Auth & User Profile Agent

Focus: Firebase auth, user creation, profile management.

Tasks:
- Create Firebase config:
  - `lib/config/firebase_config.dart` (initialize Firebase app, handle platform differences as needed).[file:2]
- Auth screens:
  - `lib/screens/auth/login_screen.dart`.
  - `lib/screens/auth/signup_screen.dart`.
  - Use email/password auth (FirebaseAuth).
  - Include form validation, error handling, loading states.[file:2]
- Riverpod auth provider:
  - `lib/providers/auth_provider.dart` managing:
    - Current Firebase user stream.
    - Sign up, login, logout methods.
    - Integration with user profile creation.
- User profile data:
  - Implement `lib/services/firebase_service.dart` (or `user_service.dart` if you prefer) using the existing `UserModel`.[file:1][file:2]
  - On signup, create a user document with default stats, streaks, and achievements list.
  - Provide:
    - `getCurrentUserStream()`.
    - `updateUserStats`, `updateXpAndLevel`, `updateStreaks`.
    - Update battle stats and achievements when other parts of the app call into this service.

### 4) Profile Picture & Storage Agent

Focus: profile avatar selection and image storage.

Tasks:
- Implement `lib/services/storage_service.dart`:
  - Upload image files to Firebase Storage.
  - Generate and return download URLs.
- Build `lib/screens/auth/profile_picture_selector.dart`:
  - Allow user to:
    - Choose from ~10 preset avatar images (can use in-app assets or placeholder URLs initially).
    - Pick from camera or gallery (image_picker).
  - Integrate into signup flow and profile editing.
- Ensure:
  - Profile picture is stored in Firestore user document.
  - Profile and home screens display the stored image via cached_network_image.

### 5) Question Generation & Study Mode Agent

Focus: Cloud Function for AI questions, study flow UI, and question data plumbing.

**Cloud Functions:**
- In `functions/src/index.ts`:
  - Implement `generateQuestions` Cloud Function as described:
    - Accepts: testType (SAT/ACT), section, skill, difficulty.
    - Uses OpenAI GPT-4 to generate 5 SAT/ACT-style questions with choices and explanations.
    - Validates the JSON structure.
    - Stores questions in Firestore `/questions` collection.
    - Returns question IDs to the client.[file:2]
- Use the existing `QuestionModel` to shape Firestore fields (testType, section, skill, questionText, passage?, choices[4], correctAnswer, difficulty, explanation, createdAt).[file:1][file:2]

**Client-side study flow:**
- Models:
  - Ensure `lib/models/question_model.dart` and any `UserAnswer` model are present and consistent with Firestore data.[file:2]
- Providers:
  - `lib/providers/question_provider.dart` to manage:
    - Loading questions (existing from Firestore or triggering Cloud Function).
    - Current question index, timer, and answer state.
- Screens:
  - `lib/screens/study/study_mode_selector.dart`:
    - Let user choose SAT/ACT and section (Math, Reading, Writing, Science).
  - `lib/screens/study/question_screen.dart`:
    - Displays question text (and passage if present).
    - 4 answer choices (A–D).
    - Submit button.
    - Timer for time spent.
  - `lib/screens/study/answer_feedback_screen.dart`:
    - Shows correct/incorrect state.
    - Displays explanation.
    - Shows XP earned (+10 correct, +5 incorrect).
    - Next Question button.[file:2]
- Logic:
  - Fetch questions from Firestore for the selected testType + section; if not enough, call Cloud Function to generate.
  - Record user answers and time spent in Firestore (e.g., `userAnswers` subcollection), then update XP and stats via Firebase service.
  - Ensure robust error handling and loading states.

### 6) Streaks, Stats & Achievements Agent

Focus: streak logic, stats aggregation, achievements system.

**Streaks & stats:**
- Extend `firebase_service.dart` or dedicated `stats_service.dart` to:
  - Track daily streak:
    - Increment when user answers ≥1 question per day.
    - Reset if a full day is missed.
    - Track best daily streak.[file:1][file:2]
  - Track accuracy streak:
    - Count consecutive correct answers.
    - Reset on wrong answer.
    - Track best accuracy streak.[file:1][file:2]
  - Maintain stats:
    - Total questions answered.
    - Accuracy per section (SAT Math, SAT Reading, etc.).[file:1]

**Achievements:**
- Use existing `Achievement` model and `DefaultAchievements.all` (as described) to define base achievements.[file:2]
- Create:
  - `lib/services/achievement_service.dart`:
    - Function to seed Firestore with default achievements from `DefaultAchievements.all`.
    - Post-answer checks: questions completed milestones, streak milestones, accuracy milestones.
    - Post-battle checks: battles played and won milestones.
  - `lib/screens/profile/achievements_screen.dart`:
    - List locked and unlocked achievements.
    - Show progress bars where applicable.
  - `lib/widgets/common/achievement_popup.dart`:
    - Small overlay/popup when a new achievement unlocks.[file:2]
- Integrate:
  - After each answer and battle, call into achievement service to check/unlock achievements and award bonus XP.

### 7) Leaderboard Agent

Focus: XP-based leaderboards.

**Cloud Functions:**
- In `functions/src/index.ts`:
  - Implement `updateLeaderboard` function:
    - Trigger on user XP changes in Firestore.
    - Update `/leaderboards/global/entries/{userId}` with rank-relevant data:
      - userId, username, profilePictureUrl, level, XP, etc.[file:2]

**Client UI & providers:**
- Create:
  - `lib/providers/leaderboard_provider.dart`:
    - Stream or fetch top 100 global leaderboard entries.
  - `lib/screens/leaderboard/leaderboard_screen.dart`:
    - Shows:
      - Top 100 users globally: rank, profile pic, username, level, XP.
      - Highlights current user.
      - Pull-to-refresh.
    - Leave “Friends” tab stubbed or simple, but structure for future extension.[file:1][file:2]

### 8) Battle System Agent

Focus: realtime battles and matchmaking.

**Cloud Functions & Realtime DB:**
- In `functions/src/index.ts`:
  - Implement `joinMatchmaking`:
    - Adds user to a matchmaking queue with their level.
    - Finds an opponent within ±3 levels.
    - Creates a battle entry in Realtime Database, including question IDs (generate via existing `generateQuestions` function or similar).
  - Implement `createBattle` helper if separate from matchmaking.[file:2]
- Data:
  - Use `BattleModel` to shape battle state in Realtime Database and results in Firestore.[file:1]

**Client-side:**
- Providers:
  - `lib/providers/battle_provider.dart` managing:
    - Join queue.
    - Observe battle state from Realtime Database.
    - Local user’s current score, question index, and answer status.
- Screens:
  - `lib/screens/battle/battle_lobby.dart`:
    - Shows “searching for opponent” and then opponent details when found.
  - `lib/screens/battle/battle_screen.dart`:
    - Shows both players with profile pic, username, score.
    - Displays same questions to both players one at a time.
    - 45s timer per question with countdown.
    - Updates scores in real time (correct answers, speed bonus 0–50 points, as described).[file:1]
  - `lib/screens/battle/battle_results.dart`:
    - Shows final scores.
    - Displays winner.
    - Awards bonus XP to winner and updates battle stats (wins/losses, win rate) through Firebase service.
    - Offers “Rematch” or “Exit”.[file:2]

### 9) Widget & Background Agent

Focus: home screen widget and background updates.

**Firestore & tips:**
- Seed Firestore `/widgetTips` collection with at least 20 SAT/ACT tips, as described.[file:2]

**Flutter & platform-specific:**
- Create `lib/services/widget_service.dart`:
  - Handles syncing streaks and a random study tip for the widget.
  - Uses `home_widget` and `workmanager` to schedule periodic updates (e.g., hourly).[file:2]
- iOS:
  - Under `ios/WidgetExtension/`:
    - Create basic WidgetKit extension that:
      - Shows random tip from shared data.
      - Shows current daily streak count.
      - Has “Study Now” button deep-linking into the app.
- Android:
  - Under `android/.../widget/`:
    - Create widget layout XML.
    - Create `AppWidgetProvider` class.
    - Wire up button to open the app into the Study or Home screen.[file:2]

### 10) QA, Error Handling & Polish Agent

Focus: robustness and UX polish.

Tasks:
- Across all screens:
  - Add loading indicators and error messages when network calls fail or data is missing.
  - Implement retry logic for key network operations (question fetch, battle join, leaderboard load).[file:2]
- UX polish:
  - Add simple transitions between major screens (e.g., fade/slide transitions via GoRouter or PageRoute animations).
  - Add empty states:
    - No achievements yet.
    - No battles played.
    - Leaderboard empty/fails to load.
  - Add confirmation dialogs for actions like logout.
  - Add simple haptic feedback hooks for major milestones (level up, achievement unlock) where supported.[file:2]
- Testing:
  - Follow the “End of Day 1” and “End of Day 2” checklists from the docs and ensure each item can be confirmed via manual testing:
    - Signup, login.
    - Study 10+ questions, XP and streaks update.
    - Achievements unlock.
    - Battle between two accounts with real-time score updates.
    - Leaderboard updates.
    - Widget shows tip and streak and updates over time.[file:1][file:2]

---

## Workflow & Expectations

### 1) Planning phase (Coordinator agent)

- Read `PROJECT_OVERVIEW.md` and `GET_STARTED.md` thoroughly.[file:1][file:2]
- Produce a short, explicit task plan and file list, with approximate dependencies.
- Identify which tasks can be done in parallel and kick off those agents immediately.
- Ensure each agent documents any assumptions at the top of files if needed.

### 2) Implementation phase

- Have each agent:
  - Create or update the specific files listed above.
  - Respect shared contracts (e.g., `FirebaseService` methods, models).
  - Write code that compiles without obvious type errors.
- Prefer to generate full files rather than patches, clearly indicating file paths.
- Ensure routes and providers are wired together so that:
  - The app boots into auth/home correctly.
  - Navigation between all described screens works.

### 3) Validation phase

- Run through the success checklists from `PROJECT_OVERVIEW.md` and `GET_STARTED.md` and verify:
  - Day 1 items: auth, home, study mode, AI questions, XP, streaks, stats.[file:1][file:2]
  - Day 2 items: achievements, leaderboard, profile, battle system, widgets, polish.[file:1][file:2]
- Fix any gaps or inconsistencies.
- Output a final message that:
  - Lists all created/updated files.
  - Summarizes how to run the app:
    - Flutter run commands.
    - Firebase deploy commands for functions and rules.
  - Notes any manual steps the human must do (placing Google services files, setting OpenAI key, configuring iOS/Android widget targets).

---

## Deliverable

Produce the complete set of Dart, TypeScript, and supporting files required for a working MVP of the SAT/ACT study app as defined in `PROJECT_OVERVIEW.md` and `GET_STARTED.md`, ready for me to:

- Add Firebase config files (`google-services.json`, `GoogleService-Info.plist`).
- Set the OpenAI key in Cloud Functions.
- Run `flutter run` in the root directory.
- Run appropriate `firebase deploy` commands.

The final output should be a cohesive, consistent codebase, not just isolated snippets.[file:1][file:2]
