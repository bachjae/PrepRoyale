# Complete Setup and Installation Commands

## Prerequisites
- Node.js 20+ installed
- Flutter SDK installed
- Android phone connected via USB (or emulator running)
- Firebase CLI installed (`npm install -g firebase-tools`)

## Step-by-Step Setup

### 1. Navigate to Project Directory
```cmd
cd "c:\Users\tsuom\OneDrive\Desktop\SAT-ACT Battle Royale"
```

### 2. Install Node.js Dependencies (for question generation)
```cmd
npm install firebase-admin
```

### 3. Start Firebase Emulators (in a separate terminal window)
**Open a NEW Command Prompt window** and run:
```cmd
cd "c:\Users\tsuom\OneDrive\Desktop\SAT-ACT Battle Royale"
firebase emulators:start
```

**Expected Output:**
```
✔  Emulator UI running on http://127.0.0.1:4000
┌─────────────┬────────────────┬─────────────────────────────────┐
│ Emulator    │ Host:Port      │ View in Emulator UI             │
├─────────────┼────────────────┼─────────────────────────────────┤
│ Auth        │ 127.0.0.1:9099 │ http://127.0.0.1:4000/auth      │
│ Firestore   │ 127.0.0.1:8080 │ http://127.0.0.1:4000/firestore │
│ Database    │ 127.0.0.1:9000 │ http://127.0.0.1:4000/database  │
│ Functions   │ 127.0.0.1:5001 │ http://127.0.0.1:4000/functions │
└─────────────┴────────────────┴─────────────────────────────────┘
```

**Leave this terminal window running!** Do not close it.

### 4. Generate 3,500 Questions (in original terminal)
**Go back to your first Command Prompt window** and run:
```cmd
node generate_500_questions.js
```

**Expected Output:**
```
Starting question generation...
Generating SAT Math questions (500)...
  Skill: Linear Equations
  Skill: Quadratics
  Skill: Percentages
  Skill: Geometry
Generating SAT Reading questions (500)...
  Skill: Main Idea
  Skill: Detail Recognition
  Skill: Purpose
Generating SAT Writing questions (500)...
  Skill: Grammar
  Skill: Parallel Structure
Generating ACT Math questions (500)...
  Skill: Pre-Algebra
  Skill: Intermediate Algebra
  Skill: Coordinate Geometry
  Skill: Trigonometry
Generating ACT Reading questions (500)...
  Skill: Detail Recognition
  Skill: Cause and Effect
Generating ACT English questions (500)...
  Skill: Grammar
  Skill: Usage
Generating ACT Science questions (500)...
  Skill: Data Interpretation
  Skill: Scientific Concepts

Total questions generated: 3500

Uploading questions to Firestore...
Progress: [========================================] 100% (70/70 batches)

✅ Successfully uploaded 3500 questions to Firestore!
```

**This will take 5-10 minutes.** The script uploads in batches of 50 questions.

### 5. Build and Install Cloud Functions
```cmd
cd functions
npm install
npm run build
cd ..
```

**Expected Output:**
```
> tsc
(TypeScript compilation output)
```

### 6. Flutter Setup and Install
```cmd
flutter clean
flutter pub get
flutter doctor
```

**Check flutter doctor output** - make sure Android toolchain is OK and device is connected.

### 7. Install App on Phone
```cmd
flutter run --release
```

**OR for debug mode with hot reload:**
```cmd
flutter run
```

**Expected Output:**
```
Launching lib\main.dart on SM-XXXXX in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...
Syncing files to device SM-XXXXX...
```

## Verification Steps

### 1. Check Emulators are Running
Visit http://127.0.0.1:4000 in your browser - you should see the Firebase Emulator Suite UI.

### 2. Check Questions in Firestore
1. Go to http://127.0.0.1:4000/firestore
2. Navigate to `questions` collection
3. You should see 3,500 documents

### 3. Test Login Flow
1. Open app on phone
2. Click "Continue as Guest" or "Create Account"
3. Should load quickly (< 2 seconds) since using emulators

### 4. Test Zen Mode
1. Navigate to Zen Mode from home screen
2. Select SAT Math
3. Should see questions loading
4. Verify questions are different from seed questions (should have variety)

## Troubleshooting

### Emulators Not Starting
**Error:** `Port 8080 is already in use`
**Fix:** Kill existing process:
```cmd
netstat -ano | findstr :8080
taskkill /PID <PID_NUMBER> /F
```

### Question Generation Fails
**Error:** `FirebaseError: Invalid project`
**Fix:** Make sure emulators are running first (Step 3), then run generation script

### Flutter Build Fails
**Error:** `Gradle build failed`
**Fix:**
```cmd
cd android
gradlew.bat clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Phone Not Detected
**Error:** `No devices found`
**Fix:**
1. Enable USB Debugging on phone (Settings > Developer Options)
2. Accept USB debugging prompt on phone
3. Check connection: `flutter devices`

### App Crashes on Startup
**Error:** App opens then immediately closes
**Fix:** Check logs:
```cmd
flutter logs
```
Look for errors related to Firebase configuration.

## Quick Restart (After Initial Setup)

If you need to restart everything later:

```cmd
REM Terminal 1: Start emulators
cd "c:\Users\tsuom\OneDrive\Desktop\SAT-ACT Battle Royale"
firebase emulators:start

REM Terminal 2: Run app
cd "c:\Users\tsuom\OneDrive\Desktop\SAT-ACT Battle Royale"
flutter run
```

**Note:** Questions persist in emulator data, so you only need to run `generate_500_questions.js` once unless you clear emulator data.

## Switching to Production Firebase Later

When ready to deploy to production:

1. **Update configuration:**
   - Edit `lib/config/firebase_config.dart`
   - Change `useEmulators = true` to `useEmulators = false`

2. **Deploy Cloud Functions:**
   ```cmd
   cd functions
   firebase deploy --only functions
   ```

3. **Generate questions in production:**
   - Edit `generate_500_questions.js`
   - Comment out emulator connection lines (lines with `useEmulator`)
   - Run: `node generate_500_questions.js`

4. **Rebuild app:**
   ```cmd
   flutter clean
   flutter pub get
   flutter build apk --release
   ```
