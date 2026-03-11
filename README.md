# SAT/ACT Battle Royale

A Flutter-based study app for SAT and ACT test preparation featuring AI-generated questions, real-time 1v1 battles, achievements, and leaderboards.

## Features

- **Email/Password Authentication** - Secure user accounts with profile management
- **AI-Generated Questions** - GPT-4 powered SAT/ACT practice questions
- **Study Mode** - Practice by test type (SAT/ACT) and section (Math, Reading, Writing, Science)
- **Real-Time Battles** - 1v1 quiz battles with live scoring and matchmaking
- **XP & Leveling** - Earn XP for answers and level up
- **Streak Tracking** - Daily study streaks and accuracy streaks
- **Achievements** - 14 unlockable achievements with bonus XP
- **Leaderboards** - Global rankings by XP
- **Profile Pictures** - Upload custom or choose from presets
- **Home Screen Widgets** - iOS and Android widgets with tips and streak info

## Tech Stack

- **Frontend**: Flutter 3.16+
- **State Management**: Riverpod
- **Navigation**: go_router
- **Backend**: Firebase (Auth, Firestore, Realtime Database, Storage, Functions)
- **AI**: OpenAI GPT-4

## Project Structure

```
lib/
├── config/
│   ├── firebase_config.dart    # Firebase initialization
│   ├── router.dart             # GoRouter configuration
│   └── theme.dart              # Material 3 theme
├── models/
│   ├── user_model.dart         # User profile and stats
│   ├── question_model.dart     # Questions and answers
│   ├── battle_model.dart       # Battle state
│   └── achievement_model.dart  # Achievements
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   ├── question_provider.dart  # Study session state
│   ├── battle_provider.dart    # Battle state
│   └── leaderboard_provider.dart # Leaderboard data
├── services/
│   ├── firebase_service.dart   # Firestore operations
│   ├── storage_service.dart    # Image upload/storage
│   ├── achievement_service.dart # Achievement logic
│   └── widget_service.dart     # Home widget updates
├── screens/
│   ├── auth/                   # Login, Signup, Profile Picture
│   ├── home/                   # Home screen
│   ├── study/                  # Study mode flow
│   ├── battle/                 # Battle lobby, game, results
│   ├── profile/                # Profile, achievements
│   └── leaderboard/            # Leaderboard
├── widgets/
│   └── common/                 # Reusable UI components
└── main.dart                   # App entry point

functions/
└── src/
    └── index.ts                # Cloud Functions

android/app/src/main/
├── kotlin/.../SATACTWidgetProvider.kt  # Android widget
└── res/
    ├── layout/widget_layout.xml        # Widget layout
    └── xml/widget_info.xml             # Widget config

ios/WidgetExtension/
└── SATACTWidget.swift          # iOS widget (placeholder)
```

## Setup Instructions

### Prerequisites

```bash
flutter --version    # Need 3.16+
firebase --version   # Need Firebase CLI
node --version       # Need Node.js 18+
```

### 1. Clone and Install

```bash
cd sat_act_app
flutter pub get
```

### 2. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create Firestore Database
4. Create Realtime Database
5. Enable Cloud Storage
6. Download config files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### 3. Cloud Functions Setup

```bash
cd functions
npm install

# Set OpenAI API key
firebase functions:config:set openai.api_key="YOUR_OPENAI_API_KEY"

# Deploy functions
firebase deploy --only functions
```

### 4. Deploy Security Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only database
```

### 5. Seed Initial Data

After deploying functions, call these endpoints to seed data:
- `https://YOUR_PROJECT.cloudfunctions.net/seedAchievements`
- `https://YOUR_PROJECT.cloudfunctions.net/seedWidgetTips`

### 6. Run the App

```bash
flutter run
```

## Configuration

### Firebase Config

Update `lib/config/firebase_config.dart` with your Firebase project values, or use FlutterFire CLI:

```bash
flutterfire configure
```

### Android Widget

The Android widget is pre-configured. Register the provider in your `AndroidManifest.xml`:

```xml
<receiver android:name=".SATACTWidgetProvider" android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_info" />
</receiver>
```

### iOS Widget

1. Open `ios/Runner.xcworkspace` in Xcode
2. Add Widget Extension target
3. Copy code from `ios/WidgetExtension/SATACTWidget.swift`
4. Configure App Group: `group.com.example.satactapp`

## Cloud Functions

| Function | Type | Description |
|----------|------|-------------|
| `generateQuestions` | HTTPS Callable | Generate AI questions using GPT-4 |
| `joinMatchmaking` | HTTPS Callable | Add user to battle queue |
| `submitBattleAnswer` | HTTPS Callable | Submit answer during battle |
| `updateLeaderboard` | Firestore Trigger | Update leaderboard on XP changes |
| `getRandomTip` | HTTPS Callable | Get random study tip |
| `seedWidgetTips` | HTTPS Request | Seed initial tips |
| `seedAchievements` | HTTPS Request | Seed achievements |

## Key Features

### Study Mode Flow
1. Select SAT or ACT
2. Choose section (Math, Reading, Writing, Science)
3. Answer questions with timer
4. Get immediate feedback with explanation
5. Earn XP (+10 correct, +5 incorrect)

### Battle System
1. Join matchmaking queue
2. Match with player within ±3 levels
3. Answer 5 questions (45s each)
4. Score: 100 base + up to 50 speed bonus
5. Winner gets 50 XP, loser gets 20 XP

### Achievements
- **Questions**: First Steps (10), Century (100), Dedicated (500), Master (1000)
- **Streaks**: Week Warrior (7), Month Champion (30), Unstoppable (100)
- **Accuracy**: Sharpshooter (10), Perfectionist (20), Flawless (50)
- **Battles**: Battle Ready (1), Victor (10), Champion (50), Legend (100)

## Cost Estimates

### Monthly Operations (1,000 users)
- Firebase: $25-50
- OpenAI API: $20-40
- **Total**: $45-90/month

### Cost Optimization
- Pre-generate questions to reduce OpenAI calls
- Cache questions on client
- Use Firestore offline persistence

## Development

### Run Tests
```bash
flutter test
```

### Build for Release
```bash
flutter build apk --release
flutter build ios --release
```

## License

MIT License
